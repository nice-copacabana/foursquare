import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/online_protocol.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/online_game_transport.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

const bool _runRealServerE2e = bool.fromEnvironment(
  'RUN_ONLINE_REAL_SERVER_E2E',
);
const Duration _eventTimeout = Duration(seconds: 5);

void main() {
  test(
    'real Flutter transports match, move, disconnect, resume and refresh',
    () async {
      final transports = <OnlineGameTransport>[];
      _RunningServer? server;

      try {
        server = await _startRealServer();
        final first = OnlineGameTransport(
          serverUrl: server.url,
          connectTimeout: _eventTimeout,
        );
        final second = OnlineGameTransport(
          serverUrl: server.url,
          connectTimeout: _eventTimeout,
          socketFactory: _createForceNewSocket,
        );
        transports.addAll([first, second]);

        expect(await first.connect(), isTrue);
        expect(await second.connect(), isTrue);

        final firstQueued = _nextEvent<OnlineMatchQueued>(first);
        expect(first.requestMatch('device-dart-e2e-first'), isTrue);
        await firstQueued;

        final firstMatched = _nextEvent<OnlineSnapshotReceived>(
          first,
          where: (event) => event.source == OnlineSnapshotSource.matchFound,
        );
        final secondMatched = _nextEvent<OnlineSnapshotReceived>(
          second,
          where: (event) => event.source == OnlineSnapshotSource.matchFound,
        );
        expect(second.requestMatch('device-dart-e2e-second'), isTrue);
        final initialSnapshots = await Future.wait([
          firstMatched,
          secondMatched,
        ]);
        final firstSnapshot = initialSnapshots[0].snapshot;
        final secondSnapshot = initialSnapshots[1].snapshot;

        expect(firstSnapshot.matchId, isNotEmpty);
        expect(secondSnapshot.matchId, firstSnapshot.matchId);
        expect(secondSnapshot.color, isNot(firstSnapshot.color));
        expect(firstSnapshot.state.revision, 0);
        expect(secondSnapshot.state.revision, 0);

        final currentTurn = firstSnapshot.state.currentTurn;
        final mover = firstSnapshot.color == currentTurn ? first : second;
        final from = currentTurn == OnlinePieceColor.black
            ? const Position(0, 0)
            : const Position(0, 3);
        final to = currentTurn == OnlinePieceColor.black
            ? const Position(0, 1)
            : const Position(0, 2);
        final firstDecision = _nextEvent<OnlineMoveDecisionReceived>(first);
        final secondDecision = _nextEvent<OnlineMoveDecisionReceived>(second);

        expect(
          mover.submitMove(
            OnlineMoveIntent(
              matchId: firstSnapshot.matchId,
              commandId: 'command-dart-e2e-1',
              expectedRevision: 0,
              from: from,
              to: to,
            ),
          ),
          isTrue,
        );
        final decisions = await Future.wait([firstDecision, secondDecision]);
        final firstCommit = decisions[0].decision as OnlineMoveCommitted;
        final secondCommit = decisions[1].decision as OnlineMoveCommitted;

        expect(firstCommit.state.revision, 1);
        expect(secondCommit.state.revision, 1);
        expect(secondCommit.state.board, firstCommit.state.board);
        expect(firstCommit.state.board[from.y][from.x], isNull);
        expect(firstCommit.state.board[to.y][to.x], currentTurn);

        final opponentDisconnected = _nextEvent<OnlineOpponentPresenceChanged>(
          second,
          where: (event) => !event.isConnected,
        );
        await first.disconnect();
        final disconnected = await opponentDisconnected;

        expect(disconnected.matchId, firstSnapshot.matchId);
        expect(disconnected.reconnectDeadlineEpochMs, isNotNull);

        final returned = OnlineGameTransport(
          serverUrl: server.url,
          connectTimeout: _eventTimeout,
          socketFactory: _createForceNewSocket,
        );
        transports.add(returned);
        expect(await returned.connect(), isTrue);

        final resumedSnapshot = _nextEvent<OnlineSnapshotReceived>(
          returned,
          where: (event) =>
              event.source == OnlineSnapshotSource.authoritativeSnapshot,
        );
        final opponentReconnected = _nextEvent<OnlineOpponentPresenceChanged>(
          second,
          where: (event) => event.isConnected,
        );
        expect(
          returned.resumeMatch(
            'device-dart-e2e-first',
            firstSnapshot.matchId,
          ),
          isTrue,
        );
        final resumed = (await resumedSnapshot).snapshot;
        final reconnected = await opponentReconnected;

        expect(resumed.matchId, firstSnapshot.matchId);
        expect(resumed.color, firstSnapshot.color);
        expect(resumed.state.revision, 1);
        expect(resumed.state.board, firstCommit.state.board);
        expect(reconnected.matchId, firstSnapshot.matchId);
        expect(reconnected.reconnectDeadlineEpochMs, isNull);

        final refreshedSnapshot = _nextEvent<OnlineSnapshotReceived>(
          returned,
          where: (event) =>
              event.source == OnlineSnapshotSource.authoritativeSnapshot,
        );
        expect(returned.requestSnapshot(firstSnapshot.matchId), isTrue);
        final refreshed = (await refreshedSnapshot).snapshot;

        expect(refreshed.matchId, firstSnapshot.matchId);
        expect(refreshed.color, firstSnapshot.color);
        expect(refreshed.state.revision, 1);
        expect(refreshed.state.board, firstCommit.state.board);
      } finally {
        try {
          await Future.wait(
            transports.reversed.map((transport) => transport.dispose()),
          );
        } finally {
          await server?.close();
        }
      }
    },
    skip: _runRealServerE2e
        ? false
        : 'Enable with --dart-define=RUN_ONLINE_REAL_SERVER_E2E=true.',
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

OnlineGameSocket _createForceNewSocket(String serverUrl) {
  return _ForceNewSocket(
    socket_io.io(
      serverUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .disableReconnection()
          .enableForceNew()
          .build(),
    ),
  );
}

class _ForceNewSocket implements OnlineGameSocket {
  final socket_io.Socket _socket;

  const _ForceNewSocket(this._socket);

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
  void on(String event, void Function(Object? data) handler) {
    _socket.on(event, handler);
  }

  @override
  void onConnect(void Function(Object? data) handler) {
    _socket.onConnect(handler);
  }

  @override
  void onConnectError(void Function(Object? data) handler) {
    _socket.onConnectError(handler);
  }

  @override
  void onDisconnect(void Function(Object? data) handler) {
    _socket.onDisconnect(handler);
  }
}

Future<T> _nextEvent<T extends OnlineGameTransportEvent>(
  OnlineGameTransport transport, {
  bool Function(T event)? where,
}) {
  return transport.events
      .where(
        (event) => event is T && (where == null || where(event)),
      )
      .cast<T>()
      .first
      .timeout(_eventTimeout);
}

Future<_RunningServer> _startRealServer() async {
  final root = Directory.current;
  _verifyServerBuildIsCurrent(root);
  final entrypoint = File('${root.path}/server/dist/index.js');
  if (!entrypoint.existsSync()) {
    throw StateError(
      'Missing server/dist/index.js. Run npm run build in server first.',
    );
  }

  final reservation = await ServerSocket.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  final port = reservation.port;
  await reservation.close();

  final process = await Process.start(
    'node',
    ['server/dist/index.js'],
    workingDirectory: root.path,
    environment: {
      ...Platform.environment,
      'NODE_ENV': 'test',
      'PORT': '$port',
    },
  );
  final output = <String>[];
  final ready = Completer<void>();
  final stdoutSubscription = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    output.add(line);
    if (!ready.isCompleted &&
        line.contains('Server is running on port $port')) {
      ready.complete();
    }
  });
  final stderrSubscription = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(output.add);
  unawaited(
    process.exitCode.then((exitCode) {
      if (!ready.isCompleted) {
        ready.completeError(
          StateError(
            'Node server exited with code $exitCode before startup. '
            '${output.join('\n')}',
          ),
        );
      }
    }),
  );

  final server = _RunningServer(
    process: process,
    port: port,
    stdoutSubscription: stdoutSubscription,
    stderrSubscription: stderrSubscription,
  );
  try {
    await ready.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException(
        'Timed out starting Node server. ${output.join('\n')}',
      ),
    );
    return server;
  } catch (_) {
    await server.close();
    rethrow;
  }
}

void _verifyServerBuildIsCurrent(Directory root) {
  final sourceDirectory = Directory('${root.path}/server/src');
  final outputDirectory = Directory('${root.path}/server/dist');
  if (!sourceDirectory.existsSync() || !outputDirectory.existsSync()) {
    return;
  }

  final staleOutputs = <String>[];
  for (final source in sourceDirectory.listSync(recursive: true)) {
    if (source is! File || !source.path.endsWith('.ts')) continue;
    final relativePath = source.path
        .substring(sourceDirectory.path.length + 1)
        .replaceFirst(RegExp(r'\.ts$'), '.js');
    final output = File('${outputDirectory.path}/$relativePath');
    if (!output.existsSync() ||
        source.lastModifiedSync().isAfter(output.lastModifiedSync())) {
      staleOutputs.add(relativePath);
    }
  }

  if (staleOutputs.isNotEmpty) {
    throw StateError(
      'server/dist is missing or older than server/src for: '
      '${staleOutputs.join(', ')}. Run npm run build in server first.',
    );
  }
}

class _RunningServer {
  final Process process;
  final int port;
  final StreamSubscription<String> stdoutSubscription;
  final StreamSubscription<String> stderrSubscription;
  bool _closed = false;

  _RunningServer({
    required this.process,
    required this.port,
    required this.stdoutSubscription,
    required this.stderrSubscription,
  });

  String get url => 'http://127.0.0.1:$port';

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode.timeout(const Duration(seconds: 3));
    } finally {
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
    }
  }
}
