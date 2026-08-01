import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/online_protocol.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/online_game_transport.dart';

void main() {
  group('OnlineGameTransport connection', () {
    test('connect completes only after the socket reports a real connection',
        () async {
      final socket = FakeOnlineGameSocket();
      final timer = FakeConnectTimer();
      final transport = _transport(socket: socket, timer: timer);

      final result = transport.connect();
      var completed = false;
      result.then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(transport.connectionState, OnlineTransportConnection.connecting);
      expect(socket.connectCalls, 1);

      socket.fireConnect();

      expect(await result, isTrue);
      expect(transport.connectionState, OnlineTransportConnection.connected);
      expect(timer.handle.cancelled, isTrue);
      await transport.dispose();
    });

    test('connect error completes false and returns to disconnected', () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);

      final result = transport.connect();
      socket.fireConnectError('secret server response');

      expect(await result, isFalse);
      expect(transport.connectionState, OnlineTransportConnection.disconnected);
      await transport.dispose();
    });

    test('connect timeout completes false and disposes the failed socket',
        () async {
      final socket = FakeOnlineGameSocket();
      final timer = FakeConnectTimer();
      final transport = _transport(socket: socket, timer: timer);

      final result = transport.connect();
      timer.fire();

      expect(await result, isFalse);
      expect(socket.disconnectCalls, 1);
      expect(socket.disposeCalls, 1);
      expect(transport.connectionState, OnlineTransportConnection.disconnected);
      await transport.dispose();
    });

    test('unexpected disconnect produces a safe typed failure', () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fireDisconnect();
      await Future<void>.delayed(Duration.zero);

      expect(transport.connectionState, OnlineTransportConnection.disconnected);
      expect(
        (events.single as OnlineTransportFailure).reason,
        OnlineTransportFailureReason.unexpectedDisconnect,
      );
      await subscription.cancel();
      await transport.dispose();
    });

    test('events from a replaced socket cannot enter the new connection',
        () async {
      final oldSocket = FakeOnlineGameSocket();
      final newSocket = FakeOnlineGameSocket();
      final sockets = [oldSocket, newSocket];
      var socketIndex = 0;
      final transport = OnlineGameTransport(
        serverUrl: 'ws://test.invalid',
        socketFactory: (_) => sockets[socketIndex++],
      );
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);

      final firstConnect = transport.connect();
      oldSocket.fireConnect();
      await firstConnect;
      oldSocket.fireDisconnect();

      final secondConnect = transport.connect();
      newSocket.fireConnect();
      await secondConnect;

      oldSocket.fire('match_found', _snapshotJson(revision: 1));
      newSocket.fire('match_found', _snapshotJson(revision: 2));
      await Future<void>.delayed(Duration.zero);

      final snapshots = events.whereType<OnlineSnapshotReceived>().toList();
      expect(snapshots, hasLength(1));
      expect(snapshots.single.snapshot.state.revision, 2);
      await subscription.cancel();
      await transport.dispose();
    });
  });

  group('OnlineGameTransport outbound events', () {
    test('match commands and move intent have authoritative wire shapes',
        () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      transport.requestMatch('device-12345678');
      transport.cancelMatch('device-12345678');
      transport.submitMove(
        OnlineMoveIntent(
          matchId: 'match-1',
          commandId: 'command-1',
          expectedRevision: 4,
          from: const Position(0, 0),
          to: const Position(0, 1),
        ),
      );

      expect(socket.emitted, [
        const EmittedEvent('request_match', {
          'protocolVersion': 1,
          'playerId': 'device-12345678',
        }),
        const EmittedEvent('cancel_match', {
          'protocolVersion': 1,
          'playerId': 'device-12345678',
        }),
        const EmittedEvent('submit_move', {
          'protocolVersion': 1,
          'matchId': 'match-1',
          'commandId': 'command-1',
          'expectedRevision': 4,
          'from': {'x': 0, 'y': 0},
          'to': {'x': 0, 'y': 1},
        }),
      ]);
      await transport.dispose();
    });
  });

  group('OnlineGameTransport inbound events', () {
    test('maps the complete matching lifecycle to typed events', () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fire('match_queued', {
        'protocolVersion': 1,
        'status': 'searching',
      });
      socket.fire('match_cancelled', {
        'protocolVersion': 1,
        'status': 'cancelled',
      });
      socket.fire('match_rejected', {
        'protocolVersion': 1,
        'reason': 'invalid_identity',
      });
      await Future<void>.delayed(Duration.zero);

      expect(events[0], isA<OnlineMatchQueued>());
      expect(events[1], isA<OnlineMatchCancelled>());
      expect(
        (events[2] as OnlineMatchRejected).reason,
        OnlineMatchRejectionReason.invalidIdentity,
      );

      socket.fire('match_rejected', {
        'protocolVersion': 1,
        'reason': 'invalid_protocol',
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        (events.last as OnlineMatchRejected).reason,
        OnlineMatchRejectionReason.invalidProtocol,
      );
      socket.fire('match_rejected', {
        'protocolVersion': 1,
        'reason': 'not_queued',
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        (events.last as OnlineMatchRejected).reason,
        OnlineMatchRejectionReason.notQueued,
      );
      await subscription.cancel();
      await transport.dispose();
    });

    test('rejects unknown matching reasons and missing protocol envelopes',
        () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fire('match_rejected', {
        'protocolVersion': 1,
        'reason': 'raw-secret-reason',
      });
      socket.fire('match_queued', {'status': 'searching'});
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(
        events.whereType<OnlineTransportFailure>(),
        hasLength(2),
      );
      expect(
        events.join(),
        isNot(contains('raw-secret-reason')),
      );
      await subscription.cancel();
      await transport.dispose();
    });

    test('maps matching and resync payloads to authoritative snapshots',
        () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fire('match_found', _snapshotJson(revision: 0));
      socket.fire('authoritative_snapshot', _snapshotJson(revision: 2));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(
        (events[0] as OnlineSnapshotReceived).source,
        OnlineSnapshotSource.matchFound,
      );
      expect(
        (events[1] as OnlineSnapshotReceived).snapshot.state.revision,
        2,
      );
      await subscription.cancel();
      await transport.dispose();
    });

    test('maps committed and rejected moves to protocol decisions', () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fire('move_committed', _committedJson());
      socket.fire('move_rejected', {
        'type': 'rejected',
        'protocolVersion': 1,
        'commandId': 'command-2',
        'reason': 'stale_revision',
        'currentRevision': 3,
      });
      await Future<void>.delayed(Duration.zero);

      expect(
        (events[0] as OnlineMoveDecisionReceived).decision,
        isA<OnlineMoveCommitted>(),
      );
      expect(
        (events[1] as OnlineMoveDecisionReceived).decision,
        isA<OnlineMoveRejected>(),
      );
      await subscription.cancel();
      await transport.dispose();
    });

    test('maps opponent presence and game over to stable typed events',
        () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fire('opponent_disconnected', _presenceJson());
      socket.fire('opponent_reconnected', _presenceJson());
      socket.fire('game_over', {
        'protocolVersion': 1,
        'matchId': 'match-1',
        'state': _stateJson(revision: 3, finished: true),
      });
      await Future<void>.delayed(Duration.zero);

      expect(
        events[0],
        isA<OnlineOpponentPresenceChanged>()
            .having((event) => event.isConnected, 'isConnected', isFalse)
            .having(
              (event) => event.reconnectDeadlineEpochMs,
              'reconnectDeadlineEpochMs',
              1785585690000,
            ),
      );
      expect(
        (events[1] as OnlineOpponentPresenceChanged).isConnected,
        isTrue,
      );
      final gameOver = events[2] as OnlineGameOverReceived;
      expect(gameOver.matchId, 'match-1');
      expect(gameOver.state.status, OnlineGameStatus.finished);
      await subscription.cancel();
      await transport.dispose();
    });

    test('turns malformed payloads into a safe failure event', () async {
      final socket = FakeOnlineGameSocket();
      final transport = _transport(socket: socket);
      final events = <OnlineGameTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      final connect = transport.connect();
      socket.fireConnect();
      await connect;

      socket.fire('match_found', {'identity': 'must-not-be-exposed'});
      await Future<void>.delayed(Duration.zero);

      final failure = events.single as OnlineTransportFailure;
      expect(failure.reason, OnlineTransportFailureReason.invalidPayload);
      expect(failure.sourceEvent, 'match_found');
      expect(failure.toString(), isNot(contains('must-not-be-exposed')));
      await subscription.cancel();
      await transport.dispose();
    });
  });
}

OnlineGameTransport _transport({
  required FakeOnlineGameSocket socket,
  FakeConnectTimer? timer,
}) {
  return OnlineGameTransport(
    serverUrl: 'ws://test.invalid',
    socketFactory: (_) => socket,
    connectTimerFactory: timer?.create,
  );
}

Map<String, dynamic> _snapshotJson({required int revision}) => {
      'protocolVersion': 1,
      'matchId': 'match-1',
      'color': 'black',
      'turnDeadlineEpochMs': 1785585720000,
      'opponentConnected': true,
      'state': _stateJson(revision: revision),
    };

Map<String, dynamic> _committedJson() => {
      'type': 'committed',
      'protocolVersion': 1,
      'commandId': 'command-1',
      'capturedPieces': <Map<String, int>>[],
      'turnDeadlineEpochMs': 1785585780000,
      'state': _stateJson(revision: 1),
    };

Map<String, dynamic> _presenceJson() => {
      'protocolVersion': 1,
      'matchId': 'match-1',
      'reconnectDeadlineEpochMs': 1785585690000,
    };

Map<String, dynamic> _stateJson({
  required int revision,
  bool finished = false,
}) =>
    {
      'board': [
        ['black', 'black', 'black', 'black'],
        [null, null, null, null],
        [null, null, null, null],
        ['white', 'white', 'white', 'white'],
      ],
      'currentTurn': 'black',
      'status': finished ? 'finished' : 'playing',
      if (finished) 'winner': 'black',
      if (finished) 'endReason': 'timeout',
      'moveHistory': <Map<String, dynamic>>[],
      'noCapturePly': 0,
      'revision': revision,
    };

class FakeOnlineGameSocket implements OnlineGameSocket {
  final Map<String, List<void Function(Object?)>> _listeners = {};
  void Function(Object?)? _onConnect;
  void Function(Object?)? _onDisconnect;
  void Function(Object?)? _onConnectError;

  @override
  bool connected = false;

  int connectCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  final List<EmittedEvent> emitted = [];

  @override
  void connect() => connectCalls++;

  @override
  void disconnect() {
    disconnectCalls++;
    connected = false;
  }

  @override
  void dispose() => disposeCalls++;

  @override
  void emit(String event, Object data) =>
      emitted.add(EmittedEvent(event, data));

  @override
  void on(String event, void Function(Object? data) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  @override
  void onConnect(void Function(Object? data) handler) => _onConnect = handler;

  @override
  void onConnectError(void Function(Object? data) handler) {
    _onConnectError = handler;
  }

  @override
  void onDisconnect(void Function(Object? data) handler) {
    _onDisconnect = handler;
  }

  void fireConnect() {
    connected = true;
    _onConnect?.call(null);
  }

  void fireConnectError(Object? data) => _onConnectError?.call(data);

  void fireDisconnect() {
    connected = false;
    _onDisconnect?.call(null);
  }

  void fire(String event, Object? data) {
    for (final handler in _listeners[event] ?? const []) {
      handler(data);
    }
  }
}

class FakeConnectTimer {
  late final FakeConnectTimerHandle handle;

  OnlineConnectTimerHandle create(Duration _, void Function() callback) {
    handle = FakeConnectTimerHandle(callback);
    return handle;
  }

  void fire() => handle.fire();
}

class FakeConnectTimerHandle implements OnlineConnectTimerHandle {
  final void Function() _callback;
  bool cancelled = false;

  FakeConnectTimerHandle(this._callback);

  @override
  void cancel() => cancelled = true;

  void fire() {
    if (!cancelled) _callback();
  }
}

class EmittedEvent {
  final String name;
  final Object data;

  const EmittedEvent(this.name, this.data);

  @override
  bool operator ==(Object other) =>
      other is EmittedEvent &&
      name == other.name &&
      _deepEquals(data, other.data);

  @override
  int get hashCode => Object.hash(name, data);
}

bool _deepEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.entries.every(
          (entry) =>
              right.containsKey(entry.key) &&
              _deepEquals(entry.value, right[entry.key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        Iterable<int>.generate(left.length)
            .every((index) => _deepEquals(left[index], right[index]));
  }
  return left == right;
}
