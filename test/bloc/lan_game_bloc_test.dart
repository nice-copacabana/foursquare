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
import 'package:foursquare/models/move_result.dart';
import 'package:foursquare/services/local_network_service.dart';
import 'package:foursquare/services/audio_coordinator.dart';
import 'package:foursquare/engine/game_engine.dart';
import 'package:foursquare/models/websocket_message.dart';
import 'package:foursquare/models/message_type.dart';

class MockLocalNetworkService extends Mock implements LocalNetworkService {}
class MockGameEngine extends Mock implements GameEngine {}
class MockAudioCoordinator extends Mock implements AudioCoordinator {}

void main() {
  group('LanGameBloc', () {
    late MockLocalNetworkService networkService;
    late MockGameEngine gameEngine;
    late MockAudioCoordinator audioCoordinator;
    late LanGameBloc bloc;
    late StreamController<WebSocketMessage> messageController;
    late StreamController<LocalNetworkConnectionState> connController;

    setUpAll(() {
      registerFallbackValue(BoardState.initial());
      registerFallbackValue(const Position(0, 0));
      registerFallbackValue(const WebSocketMessage(type: MessageType.move, payload: {}));
    });

    setUp(() {
      networkService = MockLocalNetworkService();
      gameEngine = MockGameEngine();
      audioCoordinator = MockAudioCoordinator();
      messageController = StreamController<WebSocketMessage>.broadcast();
      connController = StreamController<LocalNetworkConnectionState>.broadcast();

      when(() => networkService.messageStream)
          .thenAnswer((_) => messageController.stream);
      when(() => networkService.connectionStateStream)
          .thenAnswer((_) => connController.stream);

      bloc = LanGameBloc(
        networkService: networkService,
        gameEngine: gameEngine,
        audioCoordinator: audioCoordinator,
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
        isA<LanGamePlaying>().having((s) => s.localColor, 'localColor', PieceType.black),
      ],
    );

    group('Moves', () {
      final initialBoard = BoardState.initial();
      const from = Position(0, 0); // Black piece
      const to = Position(0, 1);
      const move = Move(from: from, to: to, player: PieceType.black);
      final newBoard = BoardState(
        blackPieces: [to, ...initialBoard.blackPieces.sublist(1)],
        whitePieces: initialBoard.whitePieces,
        currentPlayer: PieceType.white,
      );
      final moveResult = MoveResult(
        success: true,
        newBoard: newBoard,
        move: move,
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
        act: (bloc) => bloc.add(const LanLocalPlayerMoved(move)),
        verify: (_) {
          verify(() => gameEngine.executeMove(initialBoard, from, to)).called(1);
          verify(() => networkService.send(any())).called(1);
        },
        expect: () => [
          isA<LanGamePlaying>().having((s) => s.moveHistory.length, 'history length', 1),
        ],
      );
    });
  });
}
