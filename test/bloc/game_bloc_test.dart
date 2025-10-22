/// Game BLoC 单元测试
/// 
/// 测试覆盖：
/// - 新游戏事件
/// - 重新开始事件
/// - 选中棋子事件
/// - 移动棋子事件
/// - 取消选中事件
/// - 撤销移动事件
/// - 游戏结束检测
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foursquare/bloc/game_bloc.dart';
import 'package:foursquare/bloc/game_event.dart';
import 'package:foursquare/bloc/game_state.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/engine/game_engine.dart';
import 'package:foursquare/engine/move_validator.dart';
import 'package:foursquare/services/audio_service.dart';
import 'package:foursquare/services/music_service.dart';
import 'package:foursquare/services/storage_service.dart';

// Mock classes
class MockGameEngine extends Mock implements GameEngine {}
class MockMoveValidator extends Mock implements MoveValidator {}
class MockAudioService extends Mock implements AudioService {}
class MockMusicService extends Mock implements MusicService {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  // 注册fallback值以支持mocktail的any()匹配器
  setUpAll(() {
    registerFallbackValue(SoundType.move);
    registerFallbackValue(MusicTheme.main);
    registerFallbackValue(BoardState.initial());
    registerFallbackValue(const Position(0, 0));
  });

  group('GameBloc', () {
    late GameEngine gameEngine;
    late MoveValidator moveValidator;
    late AudioService audioService;
    late MusicService musicService;
    late StorageService storageService;

    setUp(() {
      gameEngine = MockGameEngine();
      moveValidator = MockMoveValidator();
      audioService = MockAudioService();
      musicService = MockMusicService();
      storageService = MockStorageService();

      // 设置默认的mock行为
      when(() => audioService.playSound(any())).thenReturn(null);
      when(() => audioService.setEnabled(any())).thenReturn(null);
      when(() => musicService.playMusic(any())).thenAnswer((_) async {});
      when(() => musicService.switchTheme(any())).thenAnswer((_) async {});
      when(() => musicService.setVolume(any())).thenAnswer((_) async {});
    });

    test('初始状态应该是 GameInitial', () {
      final bloc = GameBloc(
        gameEngine: gameEngine,
        moveValidator: moveValidator,
        audioService: audioService,
        musicService: musicService,
        storageService: storageService,
      );

      expect(bloc.state, isA<GameInitial>());
      
      bloc.close();
    });

    blocTest<GameBloc, GameState>(
      '新游戏事件应该创建 GamePlaying 状态',
      build: () => GameBloc(
        gameEngine: gameEngine,
        moveValidator: moveValidator,
        audioService: audioService,
        musicService: musicService,
        storageService: storageService,
      ),
      act: (bloc) => bloc.add(const NewGameEvent(mode: GameMode.pvp)),
      expect: () => [
        isA<GamePlaying>()
            .having((s) => s.mode, 'mode', GameMode.pvp)
            .having((s) => s.boardState.currentPlayer, 'currentPlayer', PieceType.black)
            .having((s) => s.moveHistory.length, 'moveHistory', 0),
      ],
      verify: (_) {
        verify(() => audioService.playSound(SoundType.click)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      '重新开始事件应该重置游戏状态',
      build: () => GameBloc(
        gameEngine: gameEngine,
        moveValidator: moveValidator,
        audioService: audioService,
        musicService: musicService,
        storageService: storageService,
      ),
      seed: () => GamePlaying(
        boardState: BoardState.initial().movePiece(
          const Position(0, 0),
          const Position(0, 1),
        ),
        mode: GameMode.pvp,
        moveHistory: [
          Move.now(
            from: const Position(0, 0),
            to: const Position(0, 1),
            player: PieceType.black,
          ),
        ],
        selectedPiece: const Position(1, 0),
        validMoves: const [Position(1, 1)],
      ),
      act: (bloc) => bloc.add(const RestartGameEvent()),
      expect: () => [
        isA<GamePlaying>()
            .having((s) => s.moveHistory.length, 'moveHistory', 0),
      ],
      verify: (_) {
        verify(() => audioService.playSound(SoundType.click)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      '选中己方棋子应该更新选中状态和合法移动',
      build: () {
        when(() => moveValidator.getValidMoves(any(), any()))
            .thenReturn([
          const Position(0, 1),
          const Position(1, 0),
        ]);
        
        return GameBloc(
          gameEngine: gameEngine,
          moveValidator: moveValidator,
          audioService: audioService,
          musicService: musicService,
          storageService: storageService,
        );
      },
      seed: () => GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        moveHistory: const [],
      ),
      act: (bloc) => bloc.add(const SelectPieceEvent(Position(0, 0))),
      expect: () => [
        isA<GamePlaying>()
            .having((s) => s.selectedPiece, 'selectedPiece', const Position(0, 0))
            .having((s) => s.validMoves.length, 'validMoves', 2),
      ],
      verify: (_) {
        verify(() => audioService.playSound(SoundType.select)).called(1);
        verify(() => moveValidator.getValidMoves(any(), const Position(0, 0))).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      '选中对方棋子不应该改变状态',
      build: () => GameBloc(
        gameEngine: gameEngine,
        moveValidator: moveValidator,
        audioService: audioService,
        musicService: musicService,
        storageService: storageService,
      ),
      seed: () => GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        moveHistory: const [],
      ),
      act: (bloc) => bloc.add(const SelectPieceEvent(Position(3, 3))), // 白方棋子
      expect: () => [],
    );

    blocTest<GameBloc, GameState>(
      '取消选中应该清除选中状态',
      build: () => GameBloc(
        gameEngine: gameEngine,
        moveValidator: moveValidator,
        audioService: audioService,
        musicService: musicService,
        storageService: storageService,
      ),
      seed: () => GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        selectedPiece: const Position(0, 0),
        validMoves: const [Position(0, 1), Position(1, 0)],
        moveHistory: const [],
      ),
      act: (bloc) => bloc.add(const DeselectPieceEvent()),
      expect: () => [
        isA<GamePlaying>()
            .having((s) => s.selectedPiece, 'selectedPiece', null)
            .having((s) => s.validMoves.length, 'validMoves', 0),
      ],
    );

    blocTest<GameBloc, GameState>(
      '合法移动应该更新棋盘状态',
      build: () {
        when(() => moveValidator.isValidMove(any(), any(), any()))
            .thenReturn(true);
        
        final newBoard = BoardState.initial().movePiece(
          const Position(0, 0),
          const Position(0, 1),
        );
        
        when(() => gameEngine.executeMove(any(), any(), any()))
            .thenReturn(MoveResult(
          success: true,
          move: Move.now(
            from: const Position(0, 0),
            to: const Position(0, 1),
            player: PieceType.black,
          ),
          newBoard: newBoard,
        ),);

        return GameBloc(
          gameEngine: gameEngine,
          moveValidator: moveValidator,
          audioService: audioService,
          musicService: musicService,
          storageService: storageService,
        );
      },
      seed: () => GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        selectedPiece: const Position(0, 0),
        validMoves: const [Position(0, 1)],
        moveHistory: const [],
      ),
      act: (bloc) => bloc.add(
        const MovePieceEvent(
          from: Position(0, 0),
          to: Position(0, 1),
        ),
      ),
      expect: () => [
        isA<GamePlaying>()
            .having((s) => s.selectedPiece, 'selectedPiece', null)
            .having((s) => s.moveHistory.length, 'moveHistory', 1)
            .having((s) => s.lastMove?.from, 'lastMove.from', const Position(0, 0))
            .having((s) => s.lastMove?.to, 'lastMove.to', const Position(0, 1)),
      ],
      verify: (_) {
        verify(() => moveValidator.isValidMove(any(), const Position(0, 0), const Position(0, 1))).called(1);
        verify(() => gameEngine.executeMove(any(), const Position(0, 0), const Position(0, 1))).called(1);
        verify(() => audioService.playSound(SoundType.move)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      '非法移动不应该改变状态',
      build: () {
        when(() => moveValidator.isValidMove(any(), any(), any()))
            .thenReturn(false);

        return GameBloc(
          gameEngine: gameEngine,
          moveValidator: moveValidator,
          audioService: audioService,
          musicService: musicService,
          storageService: storageService,
        );
      },
      seed: () => GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        selectedPiece: const Position(0, 0),
        validMoves: const [Position(0, 1)],
        moveHistory: const [],
      ),
      act: (bloc) => bloc.add(
        const MovePieceEvent(
          from: Position(0, 0),
          to: Position(3, 3),
        ),
      ),
      expect: () => [],
    );

    blocTest<GameBloc, GameState>(
      '吃子移动应该播放吃子音效',
      build: () {
        when(() => moveValidator.isValidMove(any(), any(), any()))
            .thenReturn(true);

        final newBoard = BoardState.initial().movePiece(
          const Position(0, 0),
          const Position(0, 1),
        );

        when(() => gameEngine.executeMove(any(), any(), any()))
            .thenReturn(MoveResult(
          success: true,
          move: Move.now(
            from: const Position(0, 0),
            to: const Position(0, 1),
            player: PieceType.black,
          ),
          newBoard: newBoard,
          captured: const Position(3, 3),
        ),);

        return GameBloc(
          gameEngine: gameEngine,
          moveValidator: moveValidator,
          audioService: audioService,
          musicService: musicService,
          storageService: storageService,
        );
      },
      seed: () => GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        selectedPiece: const Position(0, 0),
        validMoves: const [Position(0, 1)],
        moveHistory: const [],
      ),
      act: (bloc) => bloc.add(
        const MovePieceEvent(
          from: Position(0, 0),
          to: Position(0, 1),
        ),
      ),
      skip: 0,
      verify: (_) {
        verify(() => audioService.playSound(SoundType.capture)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      '撤销移动应该恢复到之前的状态',
      build: () {
        // Mock executeMove for replay
        when(() => gameEngine.executeMove(any(), any(), any()))
            .thenAnswer((invocation) {
          final board = invocation.positionalArguments[0] as BoardState;
          final from = invocation.positionalArguments[1] as Position;
          final to = invocation.positionalArguments[2] as Position;
          
          return MoveResult(
            success: true,
            move: Move.now(
              from: from,
              to: to,
              player: board.currentPlayer,
            ),
            newBoard: board.movePiece(from, to),
          );
        });

        return GameBloc(
          gameEngine: gameEngine,
          moveValidator: moveValidator,
          audioService: audioService,
          musicService: musicService,
          storageService: storageService,
        );
      },
      seed: () => GamePlaying(
        boardState: BoardState.initial().movePiece(
          const Position(0, 0),
          const Position(0, 1),
        ),
        mode: GameMode.pvp,
        moveHistory: [
          Move.now(
            from: const Position(0, 0),
            to: const Position(0, 1),
            player: PieceType.black,
          ),
        ],
        lastMove: Move.now(
          from: const Position(0, 0),
          to: const Position(0, 1),
          player: PieceType.black,
        ),
      ),
      act: (bloc) => bloc.add(const UndoMoveEvent()),
      expect: () => [
        isA<GamePlaying>()
            .having((s) => s.moveHistory.length, 'moveHistory', 0),
      ],
      verify: (_) {
        verify(() => audioService.playSound(SoundType.click)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      '设置变更应该更新音频服务',
      build: () => GameBloc(
        gameEngine: gameEngine,
        moveValidator: moveValidator,
        audioService: audioService,
        musicService: musicService,
        storageService: storageService,
      ),
      act: (bloc) => bloc.add(
        const SettingsChangedEvent(soundEnabled: false),
      ),
      verify: (_) {
        verify(() => audioService.setEnabled(false)).called(1);
      },
    );
  });
}
