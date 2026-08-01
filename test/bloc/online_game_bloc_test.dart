import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/bloc/online_game_bloc.dart';
import 'package:foursquare/bloc/online_game_event.dart';
import 'package:foursquare/bloc/online_game_state.dart';
import 'package:foursquare/models/online_protocol.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/online_authority_session.dart';
import 'package:foursquare/services/online_game_transport.dart';
import 'package:foursquare/services/online_identity_service.dart';

void main() {
  late FakeOnlineGameTransport transport;
  late FakeOnlineIdentityService identityService;
  late OnlineGameBloc bloc;
  var commandSequence = 0;

  setUp(() {
    transport = FakeOnlineGameTransport();
    identityService = FakeOnlineIdentityService('device-12345678');
    bloc = OnlineGameBloc(
      transport: transport,
      identityService: identityService,
      sessionFactory: (snapshot) => OnlineAuthoritySession(
        snapshot: snapshot,
        commandIdGenerator: () => 'command-${++commandSequence}',
      ),
    );
  });

  tearDown(() async {
    if (!bloc.isClosed) await bloc.close();
  });

  test('connects before requesting a match and keeps identity private',
      () async {
    final connecting = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.connecting,
    );
    bloc.add(const StartOnlineMatching());
    await connecting;
    await _waitUntil(() => transport.requestedMatches.isNotEmpty);

    expect(identityService.getCalls, 1);
    expect(transport.connectCalls, 1);
    expect(transport.requestedMatches, ['device-12345678']);

    final matching = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.matching,
    );
    transport.add(const OnlineMatchQueued());
    final state = await matching;
    expect(state.toString(), isNot(contains('device-12345678')));
  });

  test('projects a complete authoritative snapshot without exposing ids',
      () async {
    final playing = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.playing,
    );
    transport.add(
      OnlineSnapshotReceived(
        snapshot: _snapshot(),
        source: OnlineSnapshotSource.matchFound,
      ),
    );

    final state = await playing;
    expect(state.localColor, OnlinePieceColor.black);
    expect(state.boardState?.getPiece(const Position(0, 0)), PieceType.black);
    expect(state.boardState?.getPiece(const Position(0, 3)), PieceType.white);
    expect(state.authoritativeState?.revision, 0);
    expect(state.canMove, isTrue);
    expect(state.toString(), isNot(contains('match-1')));
  });

  test('keeps the board unchanged until the server commits the move', () async {
    await _startBattle(bloc, transport);
    final originalBoard = bloc.state.boardState;
    final pending = bloc.stream.firstWhere((state) => state.isMovePending);

    bloc.add(
      const SubmitOnlineMove(
        from: Position(0, 0),
        to: Position(0, 1),
      ),
    );

    final pendingState = await pending;
    expect(pendingState.boardState, originalBoard);
    expect(transport.submittedMoves, hasLength(1));
    expect(transport.submittedMoves.single.expectedRevision, 0);

    final committed = bloc.stream.firstWhere(
      (state) => state.authoritativeState?.revision == 1,
    );
    transport.add(
      OnlineMoveDecisionReceived(_committed(revision: 1)),
    );
    final committedState = await committed;

    expect(
      committedState.boardState?.getPiece(const Position(0, 0)),
      PieceType.empty,
    );
    expect(
      committedState.boardState?.getPiece(const Position(0, 1)),
      PieceType.black,
    );
    expect(committedState.isMovePending, isFalse);
  });

  test('requests a snapshot when a committed revision has a gap', () async {
    await _startBattle(bloc, transport);
    final recovering = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.recovering,
    );

    transport.add(
      OnlineMoveDecisionReceived(_committed(revision: 2)),
    );

    final state = await recovering;
    expect(state.isSynchronized, isFalse);
    expect(state.authoritativeState?.revision, 0);
    expect(transport.requestedSnapshots, ['match-1']);
  });

  test('a failed send releases pending and a snapshot enables retry', () async {
    await _startBattle(bloc, transport);
    transport.submitResult = false;
    final recovering = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.recovering,
    );
    bloc.add(
      const SubmitOnlineMove(
        from: Position(0, 0),
        to: Position(0, 1),
      ),
    );
    expect((await recovering).isMovePending, isFalse);

    final restored = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.playing,
    );
    transport.add(
      OnlineSnapshotReceived(
        snapshot: _snapshot(),
        source: OnlineSnapshotSource.authoritativeSnapshot,
      ),
    );
    await restored;

    transport.submitResult = true;
    final pending = bloc.stream.firstWhere((state) => state.isMovePending);
    bloc.add(
      const SubmitOnlineMove(
        from: Position(0, 0),
        to: Position(0, 1),
      ),
    );
    await pending;
    expect(transport.submittedMoves, hasLength(2));
  });

  test('presence changes retain the board and terminal state is authoritative',
      () async {
    await _startBattle(bloc, transport);
    final board = bloc.state.boardState;
    final disconnected = bloc.stream.firstWhere(
      (state) => !state.opponentConnected,
    );
    transport.add(
      const OnlineOpponentPresenceChanged(
        matchId: 'match-1',
        isConnected: false,
        reconnectDeadlineEpochMs: 1785585690000,
      ),
    );
    final disconnectedState = await disconnected;
    expect(disconnectedState.boardState, board);
    expect(disconnectedState.canMove, isTrue);
    expect(
      disconnectedState.opponentReconnectDeadlineEpochMs,
      1785585690000,
    );

    final finished = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.finished,
    );
    transport.add(
      OnlineGameOverReceived(
        matchId: 'match-1',
        state: _finishedState(),
      ),
    );
    final finishedState = await finished;
    expect(finishedState.authoritativeState?.winner, OnlineGameWinner.white);
    expect(finishedState.opponentConnected, isTrue);
    expect(finishedState.opponentReconnectDeadlineEpochMs, isNull);
    expect(
      finishedState.authoritativeState?.endReason,
      OnlineGameEndReason.timeout,
    );
  });

  test('retry resumes the retained match with the same private identity',
      () async {
    bloc.add(const StartOnlineMatching());
    await _waitUntil(() => transport.requestedMatches.isNotEmpty);
    await _startBattle(bloc, transport);
    final recovering = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.recovering,
    );
    transport.add(
      const OnlineTransportFailure(
        reason: OnlineTransportFailureReason.unexpectedDisconnect,
        sourceEvent: 'disconnect',
      ),
    );
    await recovering;

    final retrying = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.recovering,
    );
    bloc.add(const RetryOnlineConnection());
    await retrying;
    await _waitUntil(() => transport.resumedMatches.isNotEmpty);

    expect(
      transport.resumedMatches.single,
      ('device-12345678', 'match-1'),
    );
    expect(identityService.getCalls, 1);
  });

  test('a late not-queued cancellation response cannot replace a live match',
      () async {
    await _startBattle(bloc, transport);

    transport.add(
      const OnlineMatchRejected(OnlineMatchRejectionReason.notQueued),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.phase, OnlineBattlePhase.playing);
    expect(bloc.state.authoritativeState?.revision, 0);
  });

  test('invalid battle payload requests a snapshot on the live socket',
      () async {
    await _startBattle(bloc, transport);
    transport.currentConnection = OnlineTransportConnection.connected;
    final recovering = bloc.stream.firstWhere(
      (state) => state.phase == OnlineBattlePhase.recovering,
    );

    transport.add(
      const OnlineTransportFailure(
        reason: OnlineTransportFailureReason.invalidPayload,
        sourceEvent: 'move_committed',
      ),
    );

    expect((await recovering).isSynchronized, isFalse);
    expect(transport.requestedSnapshots, ['match-1']);
    expect(transport.resumedMatches, isEmpty);
  });

  test('snapshot rejection for another match cannot replace the live battle',
      () async {
    await _startBattle(bloc, transport);

    transport.add(
      const OnlineSnapshotRejected(
        matchId: 'different-match',
        reason: OnlineSnapshotRejectionReason.notRoomPlayer,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.phase, OnlineBattlePhase.playing);
    expect(bloc.state.authoritativeState?.revision, 0);
  });

  test('snapshot rejection reconnects before resuming the retained match',
      () async {
    bloc.add(const StartOnlineMatching());
    await _waitUntil(() => transport.requestedMatches.isNotEmpty);
    await _startBattle(bloc, transport);
    final failed = bloc.stream.firstWhere(
      (state) => state.failure == OnlineBattleFailure.snapshotRejected,
    );
    transport.add(
      const OnlineSnapshotRejected(
        matchId: 'match-1',
        reason: OnlineSnapshotRejectionReason.notRoomPlayer,
      ),
    );
    await failed;

    bloc.add(const RetryOnlineConnection());
    await _waitUntil(() => transport.resumedMatches.isNotEmpty);

    expect(transport.disconnectCalls, 1);
    expect(transport.connectCalls, 2);
    expect(
      transport.resumedMatches.single,
      ('device-12345678', 'match-1'),
    );
  });

  test('snapshot rejection without a battle is ignored', () async {
    transport.add(
      const OnlineSnapshotRejected(
        matchId: 'unbound-match',
        reason: OnlineSnapshotRejectionReason.notRoomPlayer,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, const OnlineBattleState());
  });

  test('late matchmaking events cannot replace a live battle', () async {
    await _startBattle(bloc, transport);

    transport.add(const OnlineMatchQueued());
    transport.add(const OnlineMatchCancelled());
    transport.add(
      OnlineSnapshotReceived(
        snapshot: OnlineStateSnapshot.fromJson({
          'protocolVersion': 1,
          'matchId': 'different-match',
          'color': 'black',
          'turnDeadlineEpochMs': 1785585720000,
          'opponentConnected': true,
          'state': _stateJson(revision: 0),
        }),
        source: OnlineSnapshotSource.authoritativeSnapshot,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.phase, OnlineBattlePhase.playing);
    expect(bloc.state.authoritativeState?.revision, 0);
  });

  test('resume not found discards the old match and retries matchmaking',
      () async {
    bloc.add(const StartOnlineMatching());
    await _waitUntil(() => transport.requestedMatches.isNotEmpty);
    await _startBattle(bloc, transport);
    final failed = bloc.stream.firstWhere(
      (state) => state.failure == OnlineBattleFailure.resumeNotFound,
    );
    transport.add(
      const OnlineMatchRejected(OnlineMatchRejectionReason.resumeNotFound),
    );
    final failure = await failed;
    expect(failure.hasBattle, isFalse);

    bloc.add(const RetryOnlineConnection());
    await _waitUntil(() => transport.requestedMatches.length == 2);

    expect(transport.requestedMatches.last, 'device-12345678');
    expect(transport.resumedMatches, isEmpty);
  });

  test('closing the bloc always disposes its transport', () async {
    await bloc.close();

    expect(bloc.isClosed, isTrue);
    expect(transport.disposed, isTrue);
  });
}

Future<void> _startBattle(
  OnlineGameBloc bloc,
  FakeOnlineGameTransport transport,
) async {
  final playing = bloc.stream.firstWhere(
    (state) => state.phase == OnlineBattlePhase.playing,
  );
  transport.add(
    OnlineSnapshotReceived(
      snapshot: _snapshot(),
      source: OnlineSnapshotSource.matchFound,
    ),
  );
  await playing;
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition was not reached');
}

OnlineStateSnapshot _snapshot() => OnlineStateSnapshot.fromJson({
      'protocolVersion': 1,
      'matchId': 'match-1',
      'color': 'black',
      'turnDeadlineEpochMs': 1785585720000,
      'opponentConnected': true,
      'state': _stateJson(revision: 0),
    });

OnlineMoveDecision _committed({required int revision}) =>
    OnlineMoveDecision.fromJson({
      'type': 'committed',
      'protocolVersion': 1,
      'commandId': 'command-1',
      'capturedPieces': <Map<String, int>>[],
      'turnDeadlineEpochMs': 1785585780000,
      'state': _stateJson(revision: revision, moved: true),
    });

OnlineGameState _finishedState() => OnlineGameState.fromJson({
      ..._stateJson(revision: 1, moved: true),
      'status': 'finished',
      'winner': 'white',
      'endReason': 'timeout',
    });

Map<String, dynamic> _stateJson({
  required int revision,
  bool moved = false,
}) =>
    {
      'board': [
        [if (moved) null else 'black', 'black', 'black', 'black'],
        [if (moved) 'black' else null, null, null, null],
        [null, null, null, null],
        ['white', 'white', 'white', 'white'],
      ],
      'currentTurn': moved ? 'white' : 'black',
      'status': 'playing',
      'moveHistory': moved
          ? [
              {
                'matchId': 'match-1',
                'from': {'x': 0, 'y': 0},
                'to': {'x': 0, 'y': 1},
                'player': 'black',
                'capturedPieces': <Map<String, int>>[],
              },
            ]
          : <Map<String, dynamic>>[],
      'noCapturePly': moved ? 1 : 0,
      'revision': revision,
    };

class FakeOnlineIdentityService extends OnlineIdentityService {
  FakeOnlineIdentityService(this.identity);

  final String identity;
  int getCalls = 0;

  @override
  Future<String> getOrCreate() async {
    getCalls += 1;
    return identity;
  }
}

class FakeOnlineGameTransport implements OnlineGameTransportClient {
  final StreamController<OnlineGameTransportEvent> _events =
      StreamController<OnlineGameTransportEvent>.broadcast();
  final StreamController<OnlineTransportConnection> _connections =
      StreamController<OnlineTransportConnection>.broadcast();

  final List<String> requestedMatches = [];
  final List<(String, String)> resumedMatches = [];
  final List<String> requestedSnapshots = [];
  final List<String> cancelledMatches = [];
  final List<OnlineMoveIntent> submittedMoves = [];
  int connectCalls = 0;
  int disconnectCalls = 0;
  bool connectResult = true;
  bool requestResult = true;
  bool submitResult = true;
  bool disposed = false;
  OnlineTransportConnection currentConnection =
      OnlineTransportConnection.disconnected;

  void add(OnlineGameTransportEvent event) {
    if (event is OnlineTransportFailure &&
        event.reason == OnlineTransportFailureReason.unexpectedDisconnect) {
      currentConnection = OnlineTransportConnection.disconnected;
    }
    _events.add(event);
  }

  @override
  Stream<OnlineGameTransportEvent> get events => _events.stream;

  @override
  Stream<OnlineTransportConnection> get connectionStates => _connections.stream;

  @override
  OnlineTransportConnection get connectionState => currentConnection;

  @override
  bool get isConnected =>
      currentConnection == OnlineTransportConnection.connected;

  @override
  Future<bool> connect() async {
    connectCalls += 1;
    if (connectResult) currentConnection = OnlineTransportConnection.connected;
    return connectResult;
  }

  @override
  bool requestMatch(String playerId) {
    requestedMatches.add(playerId);
    return requestResult;
  }

  @override
  bool resumeMatch(String playerId, String matchId) {
    resumedMatches.add((playerId, matchId));
    return requestResult;
  }

  @override
  bool requestSnapshot(String matchId) {
    requestedSnapshots.add(matchId);
    return requestResult;
  }

  @override
  bool cancelMatch(String playerId) {
    cancelledMatches.add(playerId);
    return requestResult;
  }

  @override
  bool submitMove(OnlineMoveIntent intent) {
    submittedMoves.add(intent);
    return submitResult;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    currentConnection = OnlineTransportConnection.disconnected;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
    await _connections.close();
  }
}
