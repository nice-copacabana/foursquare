import 'dart:async';
import 'dart:io';
import 'package:nsd/nsd.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/websocket_message.dart';
import '../services/logger_service.dart';

enum LocalNetworkRole { host, client, none }

class LocalNetworkService {
  static final LocalNetworkService _instance = LocalNetworkService._internal();
  factory LocalNetworkService() => _instance;
  LocalNetworkService._internal();

  // State
  LocalNetworkRole _role = LocalNetworkRole.none;
  LocalNetworkRole get role => _role;

  // Host properties
  HttpServer? _server;
  Registration? _registration;
  WebSocketChannel? _connectedClient; // 1v1 support for now

  // Client properties
  Discovery? _discovery;
  WebSocketChannel? _clientChannel;
  final List<Service> _foundServices = [];

  // State Streams
  final _connectionStateController =
      StreamController<LocalNetworkConnectionState>.broadcast();
  Stream<LocalNetworkConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  final _messageController = StreamController<WebSocketMessage>.broadcast();
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  final _servicesController = StreamController<List<Service>>.broadcast();
  Stream<List<Service>> get foundServices => _servicesController.stream;

  static const String _serviceType = '_foursquare._tcp';
  static const int _port = 4040;

  /// Start Host Mode: Start WebSocket server and advertise via mDNS
  Future<void> startHost({String roomName = 'Foursquare Room'}) async {
    if (_role != LocalNetworkRole.none) await stop();
    _role = LocalNetworkRole.host;
    _updateConnectionState(LocalNetworkConnectionState.disconnected);

    try {
      // 1. Start WebSocket Server
      var handler = webSocketHandler((webSocket) {
        if (_connectedClient != null) {
          // Only allow one client for now
          webSocket.sink.close(1008, 'Room full');
          return;
        }

        logger.info('Client connected', 'LocalNetworkService');
        _connectedClient = WebSocketChannel(webSocket);
        _updateConnectionState(LocalNetworkConnectionState.connected);

        _connectedClient!.stream.listen(
          (message) => _onMessageReceived(message),
          onDone: () {
            logger.info('Client disconnected', 'LocalNetworkService');
            _connectedClient = null;
            _updateConnectionState(LocalNetworkConnectionState.disconnected);
          },
          onError: (error) {
            logger.error('WebSocket error', 'LocalNetworkService', error);
            _connectedClient = null;
            _updateConnectionState(LocalNetworkConnectionState.disconnected);
          },
        );
      });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      logger.info(
        'Server running on port $_server.port',
        'LocalNetworkService',
      );
      _updateConnectionState(LocalNetworkConnectionState.hosting);

      // 2. Register mDNS Service
      final ip = await NetworkInfo().getWifiIP();
      _registration = await register(
        Service(
          name: roomName,
          type: _serviceType,
          port: _port,
          txt: {'ip': ip ?? '0.0.0.0'},
        ),
      );
      logger.info('mDNS Service registered: $roomName', 'LocalNetworkService');
    } catch (e) {
      logger.error('Failed to start host', 'LocalNetworkService', e);
      await stop();
      rethrow;
    }
  }

  /// Start Discovery (Client Mode)
  Future<void> startDiscovery() async {
    if (_role == LocalNetworkRole.host) return; // Host cannot discover

    _foundServices.clear();
    _servicesController.add([]);
    _updateConnectionState(LocalNetworkConnectionState.scanning);

    try {
      _discovery = await startDiscovery(_serviceType, autoResolve: true);
      _discovery!.addListener(() {
        _foundServices.clear();
        _foundServices.addAll(_discovery!.services);
        _servicesController.add(List.from(_foundServices));
        logger.info(
          'Services updated: ${_foundServices.length}',
          'LocalNetworkService',
        );
      });
      logger.info('Discovery started', 'LocalNetworkService');
    } catch (e) {
      logger.error('Failed to start discovery', 'LocalNetworkService', e);
      _updateConnectionState(LocalNetworkConnectionState.disconnected);
    }
  }

  /// Connect to a Host (Client Mode)
  Future<void> connectToHost(Service service) async {
    if (_role == LocalNetworkRole.host) return;
    _role = LocalNetworkRole.client;
    _updateConnectionState(LocalNetworkConnectionState.connecting);

    try {
      await stopDiscovery(); // Stop discovery after selecting

      // Use IP from TXT record or resolving (NSD resolves it usually)
      String? ip;
      if (service.txt != null && service.txt!['ip'] != null) {
        try {
          ip = String.fromCharCodes(service.txt!['ip'] as List<int>);
        } catch (_) {
          ip = service.txt!['ip'].toString();
        }
      } else {
        ip = service.host;
        if (service.addresses.isNotEmpty) {
          ip = service.addresses.first.address;
        }
      }

      if (ip == null) {
        throw Exception('Could not determine Host IP');
      }

      final uri = 'ws://$ip:${service.port}';
      logger.info('Connecting to $uri', 'LocalNetworkService');

      _clientChannel = WebSocketChannel.connect(Uri.parse(uri));

      // Monitor connection via stream access? WebSocketChannel doesn't expose 'onConnected' easily.
      // But we can assume connecting state until first message or stream done?
      // Actually, waiting for the stream to be ready is implicit.

      _clientChannel!.stream.listen(
        (message) => _onMessageReceived(message),
        onDone: () {
          logger.info('Disconnected from host', 'LocalNetworkService');
          _cleanupClient();
        },
        onError: (error) {
          logger.error('Client Connection error', 'LocalNetworkService', error);
          _cleanupClient();
        },
      );

      // In a real app we might want to send a handshake here.
      logger.info('WebSocket connection initiated', 'LocalNetworkService');
      _updateConnectionState(
        LocalNetworkConnectionState.connected,
      ); // Optimistic connected
    } catch (e) {
      logger.error('Failed to connect to host', 'LocalNetworkService', e);
      _cleanupClient();
      rethrow;
    }
  }

  /// Send a message to the connected peer
  void send(WebSocketMessage message) {
    final jsonString = message.toJsonString();

    if (_role == LocalNetworkRole.host && _connectedClient != null) {
      _connectedClient!.sink.add(jsonString);
    } else if (_role == LocalNetworkRole.client && _clientChannel != null) {
      _clientChannel!.sink.add(jsonString);
    } else {
      logger.warning(
          'Cannot send message: Not connected', 'LocalNetworkService',);
    }
  }

  void _onMessageReceived(dynamic data) {
    try {
      if (data is String) {
        final message = WebSocketMessage.fromJsonString(data);
        _messageController.add(message);
      }
    } catch (e) {
      logger.error('Error parsing message: $data', 'LocalNetworkService', e);
    }
  }

  /// Stop everything
  Future<void> stop() async {
    try {
      if (_role == LocalNetworkRole.host) {
        if (_registration != null) {
          await unregister(_registration!);
          _registration = null;
        }
        await _server?.close(force: true);
        _server = null;
        _connectedClient?.sink.close();
        _connectedClient = null;
      } else {
        _cleanupClient();
        if (_discovery != null) {
          await stopDiscovery(_discovery!);
          _discovery = null;
        }
      }
      _role = LocalNetworkRole.none;
      _updateConnectionState(LocalNetworkConnectionState.disconnected);
      logger.info('Local Network Service stopped', 'LocalNetworkService');
    } catch (e) {
      logger.error('Error stopping service', 'LocalNetworkService', e);
    }
  }

  void _cleanupClient() {
    _clientChannel?.sink.close();
    _clientChannel = null;
    if (_role == LocalNetworkRole.client) {
      _role = LocalNetworkRole.none;
    }
    _updateConnectionState(LocalNetworkConnectionState.disconnected);
  }

  void _updateConnectionState(LocalNetworkConnectionState state) {
    _connectionStateController.add(state);
  }
}

enum LocalNetworkConnectionState {
  disconnected,
  scanning,
  hosting,
  connecting,
  connected,
}
