/// Game BLoC - 游戏业务逻辑组件
/// 
/// 职责：
/// - 处理所有游戏事件
/// - 管理游戏状态转换
/// - 集成游戏引擎
/// - 协调音频和存储服务
/// 
/// 核心功能：
/// - 棋子选择和移动
/// - 游戏流程控制
/// - 撤销/重做
/// - 保存/加载游戏
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/board_state.dart';
import '../models/piece_type.dart';
import '../models/game_result.dart';
import '../models/game_save.dart';
import '../engine/game_engine.dart';
import '../engine/move_validator.dart';
import '../services/audio_service.dart';
import '../services/music_service.dart';
import '../services/storage_service.dart';
import '../services/logger_service.dart';
import '../ai/ai_player.dart';
import '../ai/minimax_ai.dart';
import 'game_event.dart';
import 'game_state.dart';

/// 游戏BLoC
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameEngine _gameEngine;
  final MoveValidator _moveValidator;
  final AudioService _audioService;
  final MusicService _musicService;
  final StorageService _storageService;

  GameBloc({
    GameEngine? gameEngine,
    MoveValidator? moveValidator,
    AudioService? audioService,
    MusicService? musicService,
    StorageService? storageService,
  })  : _gameEngine = gameEngine ?? GameEngine(),
        _moveValidator = moveValidator ?? MoveValidator(),
        _audioService = audioService ?? AudioService(),
        _musicService = musicService ?? MusicService(),
        _storageService = storageService ?? StorageService(),
        super(GameInitial()) {
    // 注册事件处理器
    on<NewGameEvent>(_onNewGame);
    on<RestartGameEvent>(_onRestartGame);
    on<SelectPieceEvent>(_onSelectPiece);
    on<MovePieceEvent>(_onMovePiece);
    on<DeselectPieceEvent>(_onDeselectPiece);
    on<UndoMoveEvent>(_onUndoMove);
    on<AIPlayEvent>(_onAIPlay);
    on<SaveGameEvent>(_onSaveGame);
    on<LoadGameEvent>(_onLoadGame);
    on<SettingsChangedEvent>(_onSettingsChanged);
  }

  /// 处理新游戏事件
  Future<void> _onNewGame(NewGameEvent event, Emitter<GameState> emit) async {
    _audioService.playSound(SoundType.click);
    
    // 切换到游戏音乐
    await _musicService.playMusic(MusicTheme.gameplay);

    emit(GamePlaying(
      boardState: BoardState.initial(),
      mode: event.mode,
      aiDifficulty: event.aiDifficulty,
      moveHistory: const [],
    ),);

    // 如果是AI模式且AI先手，触发AI移动
    if (event.mode == GameMode.pve && state.currentPlayer == PieceType.white) {
      add(const AIPlayEvent());
    }
  }

  /// 处理重新开始事件
  Future<void> _onRestartGame(RestartGameEvent event, Emitter<GameState> emit) async {
    _audioService.playSound(SoundType.click);

    final currentMode = state.mode;
    final currentAIDifficulty = state is GamePlaying 
        ? (state as GamePlaying).aiDifficulty 
        : null;

    emit(GamePlaying(
      boardState: BoardState.initial(),
      mode: currentMode,
      aiDifficulty: currentAIDifficulty,
      moveHistory: const [],
    ),);

    // 如果是AI模式且AI先手，触发AI移动
    if (currentMode == GameMode.pve && state.currentPlayer == PieceType.white) {
      add(const AIPlayEvent());
    }
  }

  /// 处理选中棋子事件
  Future<void> _onSelectPiece(SelectPieceEvent event, Emitter<GameState> emit) async {
    // 只在游戏进行中且不是AI回合时处理
    if (state is! GamePlaying) return;
    final playing = state as GamePlaying;
    
    if (playing.isAITurn || playing.isAIThinking) return;

    final piece = playing.boardState.getPiece(event.position);

    // 只能选中当前玩家的棋子
    if (piece != playing.currentPlayer) return;

    _audioService.playSound(SoundType.select);

    // 获取该棋子的合法移动
    final validMoves = _moveValidator.getValidMoves(
      playing.boardState,
      event.position,
    );

    emit(playing.copyWith(
      selectedPiece: event.position,
      validMoves: validMoves,
    ),);
  }

  /// 处理移动棋子事件
  Future<void> _onMovePiece(MovePieceEvent event, Emitter<GameState> emit) async {
    if (state is! GamePlaying) return;
    final playing = state as GamePlaying;

    if (playing.isAIThinking) return;

    // 验证移动是否合法
    if (!_moveValidator.isValidMove(playing.boardState, event.from, event.to)) {
      return;
    }

    // 执行移动
    final result = _gameEngine.executeMove(playing.boardState, event.from, event.to);

    if (!result.success) {
      return;
    }

    // 播放音效
    if (result.captured != null) {
      _audioService.playSound(SoundType.capture);
    } else {
      _audioService.playSound(SoundType.move);
    }

    // 移动记录已经在executeMove中创建，直接使用
    final move = result.move!;

    // 更新移动历史
    final newMoveHistory = [...playing.moveHistory, move];

    // 检查游戏是否结束
    if (result.gameResult != null) {
      // 播放胜利/失败音效
      final isPlayerWin = (result.gameResult!.status == GameStatus.blackWin &&
              playing.currentPlayer == PieceType.black) ||
          (result.gameResult!.status == GameStatus.whiteWin &&
              playing.currentPlayer == PieceType.white);
              
      if (result.gameResult!.status == GameStatus.blackWin) {
        _audioService.playSound(
          playing.mode == GameMode.pve && playing.currentPlayer == PieceType.black
              ? SoundType.win
              : SoundType.lose,
        );
      } else if (result.gameResult!.status == GameStatus.whiteWin) {
        _audioService.playSound(
          playing.mode == GameMode.pve && playing.currentPlayer == PieceType.white
              ? SoundType.lose
              : SoundType.win,
        );
      }
      
      // 播放胜利音乐（只在玩家获胜时播放）
      if (isPlayerWin) {
        await _musicService.switchTheme(MusicTheme.victory);
      }

      // 更新统计数据
      await _updateStatistics(result.gameResult!, newMoveHistory.length, playing);

      emit(GameOver(
        boardState: result.newBoard!,
        mode: playing.mode,
        gameResult: result.gameResult!,
        moveHistory: newMoveHistory,
        lastMove: move,
        aiDifficulty: playing.aiDifficulty,
      ),);
      return;
    }

    // 游戏继续，更新状态
    emit(playing.copyWith(
      boardState: result.newBoard!,
      selectedPiece: null,
      clearSelectedPiece: true,
      validMoves: const [],
      moveHistory: newMoveHistory,
      lastMove: move,
      lastCapturedPosition: result.captured,
      clearLastCapturedPosition: result.captured == null,
    ),);

    // 如果是AI模式且轮到AI，触发AI移动
    if (playing.mode == GameMode.pve && result.newBoard!.currentPlayer == PieceType.white) {
      add(const AIPlayEvent());
    }
  }

  /// 处理取消选中事件
  Future<void> _onDeselectPiece(DeselectPieceEvent event, Emitter<GameState> emit) async {
    if (state is! GamePlaying) return;
    final playing = state as GamePlaying;

    emit(playing.copyWith(
      selectedPiece: null,
      clearSelectedPiece: true,
      validMoves: const [],
    ),);
  }

  /// 处理撤销移动事件
  Future<void> _onUndoMove(UndoMoveEvent event, Emitter<GameState> emit) async {
    if (state is! GamePlaying) return;
    final playing = state as GamePlaying;

    if (!playing.canUndo || playing.isAIThinking) return;

    _audioService.playSound(SoundType.click);

    // 计算要撤销的步数（AI模式撤销2步，双人模式撤销1步）
    final stepsToUndo = playing.mode == GameMode.pve ? 2 : event.steps;
    
    if (playing.moveHistory.length < stepsToUndo) return;

    // 从初始状态重新执行移动
    var newBoard = BoardState.initial();
    final newMoveHistory = playing.moveHistory.sublist(
      0,
      playing.moveHistory.length - stepsToUndo,
    );

    for (final move in newMoveHistory) {
      final result = _gameEngine.executeMove(newBoard, move.from, move.to);
      if (result.success && result.newBoard != null) {
        newBoard = result.newBoard!;
      }
    }

    emit(playing.copyWith(
      boardState: newBoard,
      selectedPiece: null,
      clearSelectedPiece: true,
      validMoves: const [],
      moveHistory: newMoveHistory,
      lastMove: newMoveHistory.isNotEmpty ? newMoveHistory.last : null,
      clearLastMove: newMoveHistory.isEmpty,
    ),);
  }

  /// 处理AI移动事件
  Future<void> _onAIPlay(AIPlayEvent event, Emitter<GameState> emit) async {
    if (state is! GamePlaying) return;
    final playing = state as GamePlaying;

    if (playing.mode != GameMode.pve || playing.currentPlayer != PieceType.white) {
      return;
    }

    // 标记AI正在思考
    emit(playing.copyWith(
      isAIThinking: true,
      aiThinkingProgress: 0.0,
      aiThinkingStatus: '初始化...',
    ),);

    // 创建AI实例
    final aiDifficulty = AIDifficulty.fromString(playing.aiDifficulty ?? 'medium');
    final ai = MinimaxAI(aiDifficulty);
    
    // 设置进度回调
    ai.setProgressCallback((progress, status) {
      if (state is GamePlaying) {
        emit((state as GamePlaying).copyWith(
          isAIThinking: true,
          aiThinkingProgress: progress,
          aiThinkingStatus: status,
        ),);
      }
    });
    
    // AI思考
    final aiMove = await ai.selectMove(playing.boardState);
    
    if (aiMove == null) {
      // AI无法移动，游戏结束
      emit(GameOver(
        boardState: playing.boardState,
        mode: playing.mode,
        gameResult: GameResult.blackWin(
          reason: '白方无子可走',
          moveCount: playing.moveHistory.length,
          duration: Duration.zero,
        ),
        moveHistory: playing.moveHistory,
        lastMove: playing.lastMove,
        aiDifficulty: playing.aiDifficulty,
      ),);
      return;
    }
    
    // 取消AI思考标记
    emit(playing.copyWith(
      isAIThinking: false,
      aiThinkingProgress: 0.0,
      aiThinkingStatus: '',
    ),);

    // 执行AI移动
    add(MovePieceEvent(from: aiMove.from, to: aiMove.to));
  }

  /// 处理保存游戏事件
  Future<void> _onSaveGame(SaveGameEvent event, Emitter<GameState> emit) async {
    if (state is! GamePlaying) return;
    
    final playing = state as GamePlaying;
    
    try {
      final gameSave = GameSave(
        id: 'current_game',
        saveTime: DateTime.now(),
        boardState: BoardStateData.fromBoardState(playing.boardState),
        moveHistory: playing.moveHistory
            .map((m) => MoveData.fromMove(m))
            .toList(),
        currentPlayer: playing.currentPlayer == PieceType.black ? 'black' : 'white',
        mode: playing.mode.toJson(),
        aiDifficulty: playing.aiDifficulty,
      );
      
      final success = await _storageService.saveGame(gameSave);
      if (success) {
        _audioService.playSound(SoundType.click);
      }
    } catch (e) {
      logger.error('保存游戏失败', 'GameBloc', e);
    }
  }

  /// 处理加载游戏事件
  Future<void> _onLoadGame(LoadGameEvent event, Emitter<GameState> emit) async {
    try {
      final gameSave = await _storageService.loadGame();
      if (gameSave == null) {
        return;
      }
      
      final currentPlayer = gameSave.currentPlayer == 'black' 
          ? PieceType.black 
          : PieceType.white;
      
      final boardState = gameSave.boardState.toBoardState(currentPlayer);
      final moveHistory = gameSave.moveHistory
          .map((m) => m.toMove())
          .toList();
      
      final mode = GameModeExtensions.fromJson(gameSave.mode);
      
      emit(GamePlaying(
        boardState: boardState,
        moveHistory: moveHistory,
        mode: mode,
        aiDifficulty: gameSave.aiDifficulty,
      ),);
      
      _audioService.playSound(SoundType.click);
      
      // 加载后删除存档
      await _storageService.deleteGameSave();
    } catch (e) {
      logger.error('加载游戏失败', 'GameBloc', e);
    }
  }

  /// 处理设置变更事件
  Future<void> _onSettingsChanged(SettingsChangedEvent event, Emitter<GameState> emit) async {
    // 更新音效设置
    if (event.soundEnabled != null) {
      _audioService.setEnabled(event.soundEnabled!);
    }
    
    // 更新音乐设置
    if (event.musicEnabled != null) {
      await _musicService.setEnabled(event.musicEnabled!);
    }
    
    // 震动和主题设置已由SettingsPage直接保存到StorageService
    // 这里不需要额外处理
    // 注意：音效/音乐的音量控制和主题切换需要在SettingsPage中直接调用服务
  }

  /// 更新统计数据
  Future<void> _updateStatistics(
    GameResult gameResult,
    int totalMoves,
    GamePlaying playing,
  ) async {
    final isWin = (gameResult.status == GameStatus.blackWin && playing.mode == GameMode.pvp) ||
        (gameResult.status == GameStatus.blackWin && playing.mode == GameMode.pve);
    final isLoss = (gameResult.status == GameStatus.whiteWin && playing.mode == GameMode.pve);
    final isDraw = gameResult.status == GameStatus.draw;

    // 计算吃子数
    final captures = playing.moveHistory.where((m) => m.capturedPiece != null).length;

    await _storageService.updateStatistics(
      isWin: isWin,
      isLoss: isLoss,
      isDraw: isDraw,
      moves: totalMoves,
      captures: captures,
      difficulty: playing.aiDifficulty,
    );
  }
}
