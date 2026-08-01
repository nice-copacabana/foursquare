import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../models/online_protocol.dart';

enum OnlineTransportConnection { disconnected, connecting, connected }

enum OnlineSnapshotSource { matchFound, authoritativeSnapshot }

enum OnlineTransportFailureReason {
  connectError,
  connectTimeout,
  unexpectedDisconnect,
  invalidPayload,
}

enum OnlineMatchRejectionReason {
  invalidProtocol,
  invalidPayload,
  invalidIdentity,
  identityInUse,
  socketInUse,
  notQueued,
  resumeNotFound,
}

enum OnlineSnapshotRejectionReason {
  invalidProtocol,
  invalidPayload,
  notRoomPlayer,
}

sealed class OnlineGameTransportEvent {
  const OnlineGameTransportEvent();
}

class OnlineMatchQueued extends OnlineGameTransportEvent {
  const OnlineMatchQueued();
}

class OnlineMatchCancelled extends OnlineGameTransportEvent {
  const OnlineMatchCancelled();
}

class OnlineMatchRejected extends OnlineGameTransportEvent {
  final OnlineMatchRejectionReason reason;

  const OnlineMatchRejected(this.reason);
}

class OnlineSnapshotReceived extends OnlineGameTransportEvent {
  final OnlineStateSnapshot snapshot;
  final OnlineSnapshotSource source;

  const OnlineSnapshotReceived({
    required this.snapshot,
    required this.source,
  });
}

class OnlineSnapshotRejected extends OnlineGameTransportEvent {
  final String matchId;
  final OnlineSnapshotRejectionReason reason;

  const OnlineSnapshotRejected({
    required this.matchId,
    required this.reason,
  });
}

class OnlineMoveDecisionReceived extends OnlineGameTransportEvent {
  final OnlineMoveDecision decision;

  const OnlineMoveDecisionReceived(this.decision);
}

class OnlineOpponentPresenceChanged extends OnlineGameTransportEvent {
  final String matchId;
  final bool isConnected;
  final int? reconnectDeadlineEpochMs;

  const OnlineOpponentPresenceChanged({
    required this.matchId,
    required this.isConnected,
    required this.reconnectDeadlineEpochMs,
  });
}

class OnlineGameOverReceived extends OnlineGameTransportEvent {
  final String matchId;
  final OnlineGameState state;

  const OnlineGameOverReceived({
    required this.matchId,
    required this.state,
  });
}

/// A deliberately payload-free failure, safe to surface to diagnostics or UI.
class OnlineTransportFailure extends OnlineGameTransportEvent {
  final OnlineTransportFailureReason reason;
  final String sourceEvent;

  const OnlineTransportFailure({
    required this.reason,
    required this.sourceEvent,
  });

  @override
  String toString() =>
      'OnlineTransportFailure(${reason.name}, source: $sourceEvent)';
}

abstract interface class OnlineConnectTimerHandle {
  void cancel();
}

typedef OnlineConnectTimerFactory = OnlineConnectTimerHandle Function(
  Duration duration,
  void Function() callback,
);

/// The narrow Socket.io boundary. Tests can replace it without knowing the
/// concrete Socket.io client API.
abstract interface class OnlineGameSocket {
  bool get connected;

  void onConnect(void Function(Object? data) handler);

  void onDisconnect(void Function(Object? data) handler);

  void onConnectError(void Function(Object? data) handler);

  void on(String event, void Function(Object? data) handler);

  void emit(String event, Object data);

  void connect();

  void disconnect();

  void dispose();
}

typedef OnlineGameSocketFactory = OnlineGameSocket Function(String serverUrl);

abstract interface class OnlineGameTransportClient {
  Stream<OnlineGameTransportEvent> get events;

  Stream<OnlineTransportConnection> get connectionStates;

  OnlineTransportConnection get connectionState;

  bool get isConnected;

  Future<bool> connect();

  bool requestMatch(String playerId);

  bool resumeMatch(String playerId, String matchId);

  bool requestSnapshot(String matchId);

  bool cancelMatch(String playerId);

  bool submitMove(OnlineMoveIntent intent);

  Future<void> disconnect();

  Future<void> dispose();
}

/// Owns connection truth, wire event names, and protocol parsing so callers
/// only deal in authoritative domain messages.
class OnlineGameTransport implements OnlineGameTransportClient {
  final String serverUrl;
  final Duration connectTimeout;
  final OnlineGameSocketFactory _socketFactory;
  final OnlineConnectTimerFactory _connectTimerFactory;

  final StreamController<OnlineGameTransportEvent> _eventController =
      StreamController<OnlineGameTransportEvent>.broadcast();
  final StreamController<OnlineTransportConnection> _connectionController =
      StreamController<OnlineTransportConnection>.broadcast();

  OnlineGameSocket? _socket;
  Completer<bool>? _connectCompleter;
  OnlineConnectTimerHandle? _connectTimer;
  OnlineTransportConnection _connectionState =
      OnlineTransportConnection.disconnected;
  bool _disposed = false;

  OnlineGameTransport({
    required this.serverUrl,
    this.connectTimeout = const Duration(seconds: 10),
    OnlineGameSocketFactory? socketFactory,
    OnlineConnectTimerFactory? connectTimerFactory,
  })  : _socketFactory = socketFactory ?? _createSocket,
        _connectTimerFactory = connectTimerFactory ?? _createTimer;

  @override
  Stream<OnlineGameTransportEvent> get events => _eventController.stream;

  @override
  Stream<OnlineTransportConnection> get connectionStates =>
      _connectionController.stream;

  @override
  OnlineTransportConnection get connectionState => _connectionState;

  @override
  bool get isConnected =>
      _connectionState == OnlineTransportConnection.connected;

  @override
  Future<bool> connect() {
    if (_disposed) return Future<bool>.value(false);
    if (isConnected && _socket?.connected == true) {
      return Future<bool>.value(true);
    }
    final pending = _connectCompleter;
    if (pending != null && !pending.isCompleted) return pending.future;

    final completer = Completer<bool>();
    _connectCompleter = completer;
    _setConnectionState(OnlineTransportConnection.connecting);

    late final OnlineGameSocket socket;
    try {
      socket = _socketFactory(serverUrl);
      _socket = socket;
      _registerSocketHandlers(socket);
      _connectTimer = _connectTimerFactory(
        connectTimeout,
        () => _failConnection(
          socket,
          OnlineTransportFailureReason.connectTimeout,
          'connect_timeout',
        ),
      );
      socket.connect();
    } catch (_) {
      _failConnection(
        _socket,
        OnlineTransportFailureReason.connectError,
        'connect',
      );
    }
    return completer.future;
  }

  @override
  bool requestMatch(String playerId) => _emitWhenConnected(
        'request_match',
        {
          'protocolVersion': OnlineProtocol.currentVersion,
          'playerId': playerId,
        },
      );

  @override
  bool resumeMatch(String playerId, String matchId) => _emitWhenConnected(
        'resume_match',
        {
          'protocolVersion': OnlineProtocol.currentVersion,
          'playerId': playerId,
          'matchId': matchId,
        },
      );

  @override
  bool requestSnapshot(String matchId) => _emitWhenConnected(
        'request_snapshot',
        {
          'protocolVersion': OnlineProtocol.currentVersion,
          'matchId': matchId,
        },
      );

  @override
  bool cancelMatch(String playerId) => _emitWhenConnected(
        'cancel_match',
        {
          'protocolVersion': OnlineProtocol.currentVersion,
          'playerId': playerId,
        },
      );

  @override
  bool submitMove(OnlineMoveIntent intent) => _emitWhenConnected(
        'submit_move',
        intent.toJson(),
      );

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _connectTimer = null;
    final completer = _connectCompleter;
    _connectCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(false);

    final socket = _socket;
    _socket = null;
    socket?.disconnect();
    socket?.dispose();
    _setConnectionState(OnlineTransportConnection.disconnected);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _eventController.close();
    await _connectionController.close();
  }

  void _registerSocketHandlers(OnlineGameSocket socket) {
    socket.onConnect((_) => _handleConnected(socket));
    socket.onConnectError(
      (_) => _failConnection(
        socket,
        OnlineTransportFailureReason.connectError,
        'connect',
      ),
    );
    socket.onDisconnect((_) => _handleDisconnected(socket));

    socket.on(
      'match_queued',
      (data) => _parseSocketEvent(
        socket,
        'match_queued',
        data,
        _matchQueuedEvent,
      ),
    );
    socket.on(
      'match_cancelled',
      (data) => _parseSocketEvent(
        socket,
        'match_cancelled',
        data,
        _matchCancelledEvent,
      ),
    );
    socket.on(
      'match_rejected',
      (data) => _parseSocketEvent(
        socket,
        'match_rejected',
        data,
        _matchRejectedEvent,
      ),
    );
    socket.on(
      'match_found',
      (data) => _parseSocketEvent(
        socket,
        'match_found',
        data,
        (json) => OnlineSnapshotReceived(
          snapshot: OnlineStateSnapshot.fromJson(json),
          source: OnlineSnapshotSource.matchFound,
        ),
      ),
    );
    socket.on(
      'authoritative_snapshot',
      (data) => _parseSocketEvent(
        socket,
        'authoritative_snapshot',
        data,
        (json) => OnlineSnapshotReceived(
          snapshot: OnlineStateSnapshot.fromJson(json),
          source: OnlineSnapshotSource.authoritativeSnapshot,
        ),
      ),
    );
    socket.on(
      'snapshot_rejected',
      (data) => _parseSocketEvent(
        socket,
        'snapshot_rejected',
        data,
        _snapshotRejectedEvent,
      ),
    );
    socket.on(
      'move_committed',
      (data) => _parseSocketEvent(
        socket,
        'move_committed',
        data,
        (json) => OnlineMoveDecisionReceived(
          OnlineMoveDecision.fromJson(json),
        ),
      ),
    );
    socket.on(
      'move_rejected',
      (data) => _parseSocketEvent(
        socket,
        'move_rejected',
        data,
        (json) => OnlineMoveDecisionReceived(
          OnlineMoveDecision.fromJson(json),
        ),
      ),
    );
    socket.on(
      'opponent_disconnected',
      (data) => _parseSocketEvent(
        socket,
        'opponent_disconnected',
        data,
        (json) => _presenceEvent(json, isConnected: false),
      ),
    );
    socket.on(
      'opponent_reconnected',
      (data) => _parseSocketEvent(
        socket,
        'opponent_reconnected',
        data,
        (json) => _presenceEvent(json, isConnected: true),
      ),
    );
    socket.on(
      'game_over',
      (data) => _parseSocketEvent(
        socket,
        'game_over',
        data,
        _gameOverEvent,
      ),
    );
  }

  void _handleConnected(OnlineGameSocket socket) {
    if (!identical(_socket, socket) || _disposed) return;
    _connectTimer?.cancel();
    _connectTimer = null;
    _setConnectionState(OnlineTransportConnection.connected);
    final completer = _connectCompleter;
    _connectCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(true);
  }

  void _handleDisconnected(OnlineGameSocket socket) {
    if (!identical(_socket, socket)) return;
    final wasConnected = isConnected;
    _connectTimer?.cancel();
    _connectTimer = null;
    _socket = null;
    socket.dispose();
    final completer = _connectCompleter;
    _connectCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(false);
    _setConnectionState(OnlineTransportConnection.disconnected);
    if (wasConnected) {
      _addEvent(
        const OnlineTransportFailure(
          reason: OnlineTransportFailureReason.unexpectedDisconnect,
          sourceEvent: 'disconnect',
        ),
      );
    }
  }

  void _failConnection(
    OnlineGameSocket? socket,
    OnlineTransportFailureReason reason,
    String sourceEvent,
  ) {
    if (socket != null && !identical(_socket, socket)) return;
    _connectTimer?.cancel();
    _connectTimer = null;
    _socket = null;
    socket?.disconnect();
    socket?.dispose();
    final completer = _connectCompleter;
    _connectCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(false);
    _setConnectionState(OnlineTransportConnection.disconnected);
    _addEvent(OnlineTransportFailure(reason: reason, sourceEvent: sourceEvent));
  }

  bool _emitWhenConnected(String event, Object data) {
    final socket = _socket;
    if (!isConnected || socket == null || !socket.connected) return false;
    socket.emit(event, data);
    return true;
  }

  void _parse(
    String sourceEvent,
    Object? data,
    OnlineGameTransportEvent Function(Map<String, dynamic> json) parser,
  ) {
    if (_disposed) return;
    try {
      final normalized = _normalizeJson(data);
      if (normalized is! Map<String, dynamic>) throw const FormatException();
      _addEvent(parser(normalized));
    } catch (_) {
      _addEvent(
        OnlineTransportFailure(
          reason: OnlineTransportFailureReason.invalidPayload,
          sourceEvent: sourceEvent,
        ),
      );
    }
  }

  void _parseSocketEvent(
    OnlineGameSocket socket,
    String sourceEvent,
    Object? data,
    OnlineGameTransportEvent Function(Map<String, dynamic> json) parser,
  ) {
    if (!identical(_socket, socket) || _disposed) return;
    _parse(sourceEvent, data, parser);
  }

  OnlineOpponentPresenceChanged _presenceEvent(
    Map<String, dynamic> json, {
    required bool isConnected,
  }) {
    _validateEnvelope(json);
    return OnlineOpponentPresenceChanged(
      matchId: _requiredNonBlankString(json, 'matchId'),
      isConnected: isConnected,
      reconnectDeadlineEpochMs: isConnected
          ? null
          : _requiredNonNegativeInt(json, 'reconnectDeadlineEpochMs'),
    );
  }

  OnlineMatchQueued _matchQueuedEvent(Map<String, dynamic> json) {
    _validateEnvelope(json);
    if (_requiredNonBlankString(json, 'status') != 'searching') {
      throw const FormatException();
    }
    return const OnlineMatchQueued();
  }

  OnlineMatchCancelled _matchCancelledEvent(Map<String, dynamic> json) {
    _validateEnvelope(json);
    if (_requiredNonBlankString(json, 'status') != 'cancelled') {
      throw const FormatException();
    }
    return const OnlineMatchCancelled();
  }

  OnlineMatchRejected _matchRejectedEvent(Map<String, dynamic> json) {
    _validateEnvelope(json);
    final reason = switch (_requiredNonBlankString(json, 'reason')) {
      'invalid_protocol' => OnlineMatchRejectionReason.invalidProtocol,
      'invalid_payload' => OnlineMatchRejectionReason.invalidPayload,
      'invalid_identity' => OnlineMatchRejectionReason.invalidIdentity,
      'identity_in_use' => OnlineMatchRejectionReason.identityInUse,
      'socket_in_use' => OnlineMatchRejectionReason.socketInUse,
      'not_queued' => OnlineMatchRejectionReason.notQueued,
      'resume_not_found' => OnlineMatchRejectionReason.resumeNotFound,
      _ => throw const FormatException(),
    };
    return OnlineMatchRejected(reason);
  }

  OnlineSnapshotRejected _snapshotRejectedEvent(
    Map<String, dynamic> json,
  ) {
    _validateEnvelope(json);
    final reason = switch (_requiredNonBlankString(json, 'reason')) {
      'invalid_protocol' => OnlineSnapshotRejectionReason.invalidProtocol,
      'invalid_payload' => OnlineSnapshotRejectionReason.invalidPayload,
      'not_room_player' => OnlineSnapshotRejectionReason.notRoomPlayer,
      _ => throw const FormatException(),
    };
    return OnlineSnapshotRejected(
      matchId: _requiredNonBlankString(json, 'matchId'),
      reason: reason,
    );
  }

  OnlineGameOverReceived _gameOverEvent(Map<String, dynamic> json) {
    _validateEnvelope(json);
    final state = json['state'];
    if (state is! Map<String, dynamic>) throw const FormatException();
    return OnlineGameOverReceived(
      matchId: _requiredNonBlankString(json, 'matchId'),
      state: OnlineGameState.fromJson(state),
    );
  }

  void _addEvent(OnlineGameTransportEvent event) {
    if (!_eventController.isClosed) _eventController.add(event);
  }

  void _setConnectionState(OnlineTransportConnection next) {
    if (_connectionState == next) return;
    _connectionState = next;
    if (!_connectionController.isClosed) _connectionController.add(next);
  }
}

void _validateEnvelope(Map<String, dynamic> json) {
  if (json['protocolVersion'] != OnlineProtocol.currentVersion) {
    throw const FormatException();
  }
}

String _requiredNonBlankString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) throw const FormatException();
  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! int || value < 0) throw const FormatException();
  return value;
}

Object? _normalizeJson(Object? value) {
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) throw const FormatException();
      result[entry.key as String] = _normalizeJson(entry.value);
    }
    return result;
  }
  if (value is List) return value.map(_normalizeJson).toList(growable: false);
  return value;
}

OnlineGameSocket _createSocket(String serverUrl) => _SocketIoAdapter(
      socket_io.io(
        serverUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .disableReconnection()
            .build(),
      ),
    );

OnlineConnectTimerHandle _createTimer(
  Duration duration,
  void Function() callback,
) =>
    _DartTimerHandle(Timer(duration, callback));

class _DartTimerHandle implements OnlineConnectTimerHandle {
  final Timer _timer;

  const _DartTimerHandle(this._timer);

  @override
  void cancel() => _timer.cancel();
}

class _SocketIoAdapter implements OnlineGameSocket {
  final socket_io.Socket _socket;

  const _SocketIoAdapter(this._socket);

  @override
  bool get connected => _socket.connected;

  @override
  void connect() => _socket.connect();

  @override
  void disconnect() => _socket.disconnect();

  @override
  void dispose() => _socket.dispose();

  @override
  void emit(String event, Object data) => _socket.emit(event, data);

  @override
  void on(String event, void Function(Object? data) handler) =>
      _socket.on(event, handler);

  @override
  void onConnect(void Function(Object? data) handler) =>
      _socket.onConnect(handler);

  @override
  void onConnectError(void Function(Object? data) handler) =>
      _socket.onConnectError(handler);

  @override
  void onDisconnect(void Function(Object? data) handler) =>
      _socket.onDisconnect(handler);
}
