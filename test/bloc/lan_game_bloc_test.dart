import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foursquare/bloc/lan_game_bloc.dart';
import 'package:foursquare/bloc/lan_game_event.dart';
import 'package:foursquare/bloc/lan_game_state.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/local_network_service.dart';
import 'package:foursquare/services/audio_coordinator.dart';
import 'package:foursquare/engine/game_engine.dart';
import 'package:foursquare/models/websocket_message.dart';
import 'package:foursquare/models/message_type.dart';
import 'package:foursquare/models/lan_protocol.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/game_record.dart';
import 'package:foursquare/services/storage_service.dart';

class MockLocalNetworkService extends Mock implements LocalNetworkService {}

class MockGameEngine extends Mock implements GameEngine {}

class MockAudioCoordinator extends Mock implements AudioCoordinator {}

class MockStorageService extends Mock implements StorageService {}

class FakeGameRecord extends Fake implements GameRecord {}

void main() {
  group('LanGameBloc', () {
    late MockLocalNetworkService networkService;
    late MockGameEngine gameEngine;
    late MockAudioCoordinator audioCoordinator;
    late MockStorageService storageService;
    late LanGameBloc bloc;
    late StreamController<WebSocketMessage> messageController;
    late StreamController<LocalNetworkConnectionState> connController;
    late DateTime fakeNow;

    setUpAll(() {
      registerFallbackValue(BoardState.initial());
      registerFallbackValue(const Position(0, 0));
      registerFallbackValue(
        WebSocketMessage(
          type: MessageType.move,
          payload: const {},
          timestamp: DateTime.now(),
        ),
      );
      registerFallbackValue(FakeGameRecord());
    });

    setUp(() {
      networkService = MockLocalNetworkService();
      gameEngine = MockGameEngine();
      audioCoordinator = MockAudioCoordinator();
      storageService = MockStorageService();
      messageController = StreamController<WebSocketMessage>.broadcast();
      connController =
          StreamController<LocalNetworkConnectionState>.broadcast();
      fakeNow = DateTime.utc(2026, 8, 1, 12);

      when(() => networkService.messageStream)
          .thenAnswer((_) => messageController.stream);
      when(() => networkService.connectionStateStream)
          .thenAnswer((_) => connController.stream);
      when(() => storageService.recordCompletedGame(any()))
          .thenAnswer((_) async => true);

      bloc = LanGameBloc(
        networkService: networkService,
        gameEngine: gameEngine,
        audioCoordinator: audioCoordinator,
        storageService: storageService,
        clock: () => fakeNow,
        startingPlayerGenerator: () => PieceType.white,
        gameIdGenerator: () => 'test-game',
        commandIdGenerator: () => 'test-command',
      );
    });

    tearDown(() {
      bloc.close();
      messageController.close();
      connController.close();
    });

    test('initial state is LanGameInitial', () {
      expect(bloc.state, isA<LanGameInitial>());
    });

    blocTest<LanGameBloc, LanGameState>(
      'emits LanGamePlaying when StartLanGame is added',
      build: () => bloc,
      act: (bloc) => bloc.add(const StartLanGame(isHost: true)),
      expect: () => [
        isA<LanGamePlaying>()
            .having((s) => s.localColor, 'localColor', PieceType.black),
      ],
    );

    group('Moves', () {
      final initialBoard = BoardState.initial();
      const from = Position(0, 0); // Black piece
      const to = Position(0, 1);
      final move = Move.now(from: from, to: to, player: PieceType.black);
      final newBoard = initialBoard.movePiece(from, to).switchPlayer();
      final moveResult = MoveResult.success(
        move: move,
        gameOver: false,
        newBoard: newBoard,
      );

      blocTest<LanGameBloc, LanGameState>(
        'local move executes and emits new state',
        build: () {
          when(() => gameEngine.executeMove(any(), any(), any()))
              .thenReturn(moveResult);
          return bloc;
        },
        seed: () => LanGamePlaying(
          boardState: initialBoard,
          localColor: PieceType.black,
          lastUpdate: DateTime.now(),
        ),
        act: (bloc) => bloc.add(LanLocalPlayerMoved(move)),
        verify: (_) {
          verify(() => gameEngine.executeMove(initialBoard, from, to))
              .called(1);
          verify(() => networkService.send(any())).called(1);
        },
        expect: () => [
          isA<LanGamePlaying>()
              .having((s) => s.moveHistory.length, 'history length', 1),
        ],
      );
    });

    group('authoritative protocol', () {
      test('client sends an intent without optimistically changing its board',
          () async {
        bloc.add(const StartLanGame(isHost: false));
        await _waitForPlaying(bloc, (state) => !state.isSynchronized);

        final snapshot = LanStateSnapshot(
          gameId: 'game-client',
          revision: 0,
          boardState: BoardState.initial(currentPlayer: PieceType.white),
          startingPlayer: PieceType.white,
          moveHistory: const [],
          noCapturePlyCount: 0,
          turnDeadlineUtc: fakeNow.add(const Duration(seconds: 60)),
          gameResult: null,
          stateHash: 'initial-client',
        );
        messageController.add(_protocolEnvelope(snapshot, fakeNow));
        final synchronized = await _waitForPlaying(
          bloc,
          (state) => state.isSynchronized && state.gameId == 'game-client',
        );
        final before = synchronized.boardState;

        bloc.add(
          LanLocalPlayerMoved(
            Move.now(
              from: const Position(0, 3),
              to: const Position(0, 2),
              player: PieceType.white,
            ),
          ),
        );
        final pending = await _waitForPlaying(
          bloc,
          (state) => state.pendingCommandId != null,
        );

        expect(pending.boardState, before);
        expect(pending.moveHistory, isEmpty);
        final sent = verify(() => networkService.send(captureAny())).captured;
        final intentEnvelope = sent.cast<WebSocketMessage>().lastWhere(
              (message) => message.type == MessageType.lanProtocol,
            );
        final intent = LanProtocol.fromJson(intentEnvelope.payload);
        expect(intent, isA<LanMoveIntent>());
        expect((intent as LanMoveIntent).expectedRevision, 0);
      });

      test('client applies only the received authoritative commit', () async {
        bloc.add(const StartLanGame(isHost: false));
        await _waitForPlaying(bloc, (state) => !state.isSynchronized);
        final snapshot = LanStateSnapshot(
          gameId: 'game-client',
          revision: 0,
          boardState: BoardState.initial(currentPlayer: PieceType.white),
          startingPlayer: PieceType.white,
          moveHistory: const [],
          noCapturePlyCount: 0,
          turnDeadlineUtc: fakeNow.add(const Duration(seconds: 60)),
          gameResult: null,
          stateHash: 'initial-client',
        );
        messageController.add(_protocolEnvelope(snapshot, fakeNow));
        await _waitForPlaying(bloc, (state) => state.isSynchronized);

        final move = Move(
          from: const Position(0, 3),
          to: const Position(0, 2),
          player: PieceType.white,
          timestamp: fakeNow,
        );
        final committed = LanMoveCommitted(
          gameId: 'game-client',
          commandId: 'host-commit-1',
          revision: 1,
          move: move,
          noCapturePlyCount: 1,
          currentPlayer: PieceType.black,
          turnDeadlineUtc: fakeNow.add(const Duration(seconds: 60)),
          gameResult: null,
          stateHash: 'committed-client',
        );
        messageController.add(_protocolEnvelope(committed, fakeNow));
        final applied = await _waitForPlaying(
          bloc,
          (state) => state.revision == 1,
        );

        expect(
          applied.boardState.getPiece(const Position(0, 2)),
          PieceType.white,
        );
        expect(applied.boardState.currentPlayer, PieceType.black);
        expect(applied.moveHistory, [move]);
        expect(applied.noCapturePlyCount, 1);
        expect(applied.stateHash, 'committed-client');
      });

      test('client cannot regress a finished game with an older snapshot',
          () async {
        bloc.add(const StartLanGame(isHost: false));
        await _waitForPlaying(bloc, (state) => !state.isSynchronized);
        final result = GameResult.timeout(
          timeoutPlayer: PieceType.black,
          moveCount: 4,
          duration: const Duration(minutes: 2),
        );
        final terminal = LanStateSnapshot(
          gameId: 'game-client-terminal',
          revision: 5,
          boardState: BoardState.initial(),
          startingPlayer: PieceType.black,
          moveHistory: const [],
          noCapturePlyCount: 4,
          turnDeadlineUtc: null,
          gameResult: result,
          stateHash: 'terminal-revision-5',
        );
        messageController.add(_protocolEnvelope(terminal, fakeNow));
        final finished = await _waitForFinished(bloc).timeout(
          const Duration(seconds: 1),
        );
        expect(finished.revision, 5);

        final staleOngoing = LanStateSnapshot(
          gameId: terminal.gameId,
          revision: 4,
          boardState: BoardState.initial(),
          startingPlayer: PieceType.black,
          moveHistory: const [],
          noCapturePlyCount: 3,
          turnDeadlineUtc: fakeNow.add(const Duration(seconds: 30)),
          gameResult: null,
          stateHash: 'stale-revision-4',
        );
        messageController.add(_protocolEnvelope(staleOngoing, fakeNow));
        await pumpEventQueue();

        expect(bloc.state, isA<LanGameFinished>());
        expect((bloc.state as LanGameFinished).revision, 5);
      });

      test('host validates a received intent and broadcasts its commit',
          () async {
        final initial = BoardState.initial(currentPlayer: PieceType.white);
        final move = Move(
          from: const Position(0, 3),
          to: const Position(0, 2),
          player: PieceType.white,
          timestamp: fakeNow,
        );
        when(
          () => gameEngine.executeMove(
            any(),
            any(),
            any(),
            noCapturePlyCount: any(named: 'noCapturePlyCount'),
          ),
        ).thenReturn(
          MoveResult.success(
            move: move,
            gameOver: false,
            noCapturePlyCount: 1,
            newBoard: initial
                .movePiece(const Position(0, 3), const Position(0, 2))
                .switchPlayer(),
          ),
        );
        bloc.add(const StartLanGame(isHost: true));
        final started = await _waitForPlaying(
          bloc,
          (state) => state.isSynchronized,
        );
        clearInteractions(networkService);

        final intent = LanMoveIntent(
          gameId: started.gameId!,
          commandId: 'peer-command-1',
          expectedRevision: 0,
          from: const Position(0, 3),
          to: const Position(0, 2),
        );
        messageController.add(_protocolEnvelope(intent, fakeNow));
        final committedState = await _waitForPlaying(
          bloc,
          (state) => state.revision == 1,
        );

        expect(committedState.moveHistory, hasLength(1));
        final envelope = verify(
          () => networkService.send(captureAny()),
        ).captured.single as WebSocketMessage;
        expect(envelope.type, MessageType.lanProtocol);
        expect(LanProtocol.fromJson(envelope.payload), isA<LanMoveCommitted>());
      });

      test('host broadcasts a rejection and a snapshot for stale intent',
          () async {
        bloc.add(const StartLanGame(isHost: true));
        final started = await _waitForPlaying(
          bloc,
          (state) => state.isSynchronized,
        );
        clearInteractions(networkService);
        final stale = LanMoveIntent(
          gameId: started.gameId!,
          commandId: 'stale-peer-command',
          expectedRevision: 4,
          from: const Position(0, 3),
          to: const Position(0, 2),
        );

        messageController.add(_protocolEnvelope(stale, fakeNow));
        await _waitForPlaying(
          bloc,
          (state) =>
              state.lastRejection == LanMoveRejectionReason.staleRevision,
        );
        final sent = verify(
          () => networkService.send(captureAny()),
        ).captured.cast<WebSocketMessage>();

        expect(sent, hasLength(2));
        final rejected = LanProtocol.fromJson(sent.first.payload);
        final snapshot = LanProtocol.fromJson(sent.last.payload);
        expect(rejected, isA<LanMoveRejected>());
        expect(
          (rejected as LanMoveRejected).reason,
          LanMoveRejectionReason.staleRevision,
        );
        expect(snapshot, isA<LanStateSnapshot>());
      });

      test('host rematch alternates the authoritative starting player',
          () async {
        bloc.add(const StartLanGame(isHost: true));
        final first = await _waitForPlaying(
          bloc,
          (state) => state.isSynchronized,
        );
        expect(first.startingPlayer, PieceType.white);

        bloc.add(LanRestartGame());
        final rematch = await _waitForPlaying(
          bloc,
          (state) =>
              state.gameId != first.gameId &&
              state.startingPlayer == PieceType.black,
        );

        expect(rematch.revision, 0);
        expect(rematch.boardState.currentPlayer, PieceType.black);
      });
    });

    group('authority deadlines and reconnect state', () {
      test('host exposes 30-second grace and finishes after its deadline',
          () async {
        bloc.add(const StartLanGame(isHost: true));
        await _waitForPlaying(bloc, (state) => state.isSynchronized);

        connController.add(LocalNetworkConnectionState.disconnected);
        final reconnecting = await _waitForPlaying(
          bloc,
          (state) => state.isReconnecting,
        );
        expect(
          reconnecting.disconnectDeadlineUtc,
          fakeNow.add(const Duration(seconds: 30)),
        );

        fakeNow = fakeNow.add(const Duration(seconds: 30));
        bloc.add(LanAuthorityTick());
        final finished = await _waitForFinished(bloc);

        expect(
          finished.authoritativeResult!.endReason,
          GameEndReason.disconnect,
        );
        expect(finished.winner, PieceType.black);
        expect(finished.revision, 1);
      });

      test('host enforces the absolute 60-second turn deadline', () async {
        bloc.add(const StartLanGame(isHost: true));
        final started = await _waitForPlaying(
          bloc,
          (state) => state.isSynchronized,
        );
        expect(
          started.turnDeadlineUtc,
          fakeNow.add(const Duration(seconds: 60)),
        );

        fakeNow = fakeNow.add(const Duration(seconds: 60));
        bloc.add(LanAuthorityTick());
        final finished = await _waitForFinished(bloc);

        expect(
          finished.authoritativeResult!.endReason,
          GameEndReason.timeout,
        );
        expect(finished.winner, PieceType.black);
        expect(finished.revision, 1);
        await Future<void>.delayed(Duration.zero);
        final archived = verify(
          () => storageService.recordCompletedGame(captureAny()),
        ).captured.single as GameRecord;
        expect(archived.id, finished.gameId);
        expect(archived.humanPlayer, PieceType.black);
        expect(archived.result, finished.authoritativeResult);
      });

      test('host disconnect event cannot swallow an already expired turn',
          () async {
        bloc.add(const StartLanGame(isHost: true));
        await _waitForPlaying(bloc, (state) => state.isSynchronized);
        clearInteractions(networkService);

        fakeNow = fakeNow.add(const Duration(seconds: 60));
        connController.add(LocalNetworkConnectionState.disconnected);
        final finished = await _waitForFinished(bloc).timeout(
          const Duration(seconds: 1),
        );

        expect(
          finished.authoritativeResult!.endReason,
          GameEndReason.timeout,
        );
        expect(finished.winner, PieceType.black);
        final sent = verify(
          () => networkService.send(captureAny()),
        ).captured.cast<WebSocketMessage>();
        expect(
          sent.map((message) => LanProtocol.fromJson(message.payload)),
          contains(
            isA<LanStateSnapshot>().having(
              (snapshot) => snapshot.gameResult?.endReason,
              'endReason',
              GameEndReason.timeout,
            ),
          ),
        );
      });

      test('client finishes locally when the disconnected host misses grace',
          () async {
        bloc.add(const StartLanGame(isHost: false));
        await _waitForPlaying(bloc, (state) => !state.isSynchronized);
        final snapshot = LanStateSnapshot(
          gameId: 'game-host-disconnect',
          revision: 3,
          boardState: BoardState.initial(),
          startingPlayer: PieceType.black,
          moveHistory: const [],
          noCapturePlyCount: 0,
          turnDeadlineUtc: fakeNow.add(const Duration(seconds: 60)),
          gameResult: null,
          stateHash: 'host-connected',
        );
        messageController.add(_protocolEnvelope(snapshot, fakeNow));
        await _waitForPlaying(bloc, (state) => state.isSynchronized);

        connController.add(LocalNetworkConnectionState.disconnected);
        final reconnecting = await _waitForPlaying(
          bloc,
          (state) => state.isReconnecting,
        );
        expect(
          reconnecting.disconnectDeadlineUtc,
          fakeNow.add(const Duration(seconds: 30)),
        );

        fakeNow = fakeNow.add(const Duration(seconds: 30));
        bloc.add(LanAuthorityTick());
        final finished = await _waitForFinished(bloc).timeout(
          const Duration(seconds: 1),
        );

        expect(
          finished.authoritativeResult!.endReason,
          GameEndReason.disconnect,
        );
        expect(finished.winner, PieceType.white);
        expect(finished.revision, 4);
      });

      test('client preserves an earlier turn timeout during host disconnect',
          () async {
        bloc.add(const StartLanGame(isHost: false));
        await _waitForPlaying(bloc, (state) => !state.isSynchronized);
        final snapshot = LanStateSnapshot(
          gameId: 'game-timeout-before-disconnect',
          revision: 3,
          boardState: BoardState.initial(currentPlayer: PieceType.white),
          startingPlayer: PieceType.white,
          moveHistory: const [],
          noCapturePlyCount: 0,
          turnDeadlineUtc: fakeNow.add(const Duration(seconds: 10)),
          gameResult: null,
          stateHash: 'client-turn-before-host-grace',
        );
        messageController.add(_protocolEnvelope(snapshot, fakeNow));
        await _waitForPlaying(bloc, (state) => state.isSynchronized);

        connController.add(LocalNetworkConnectionState.disconnected);
        await _waitForPlaying(bloc, (state) => state.isReconnecting);
        fakeNow = fakeNow.add(const Duration(seconds: 30));
        bloc.add(LanAuthorityTick());
        final finished = await _waitForFinished(bloc).timeout(
          const Duration(seconds: 1),
        );

        expect(
          finished.authoritativeResult!.endReason,
          GameEndReason.timeout,
        );
        expect(finished.winner, PieceType.black);
      });
    });
  });
}

WebSocketMessage _protocolEnvelope(
  LanProtocolMessage message,
  DateTime timestamp,
) {
  return WebSocketMessage(
    type: MessageType.lanProtocol,
    payload: message.toJson(),
    timestamp: timestamp,
  );
}

Future<LanGamePlaying> _waitForPlaying(
  LanGameBloc bloc,
  bool Function(LanGamePlaying state) predicate,
) async {
  final current = bloc.state;
  if (current is LanGamePlaying && predicate(current)) return current;
  return bloc.stream
      .where((state) => state is LanGamePlaying && predicate(state))
      .cast<LanGamePlaying>()
      .first;
}

Future<LanGameFinished> _waitForFinished(LanGameBloc bloc) async {
  final current = bloc.state;
  if (current is LanGameFinished) return current;
  return bloc.stream
      .where((state) => state is LanGameFinished)
      .cast<LanGameFinished>()
      .first;
}
