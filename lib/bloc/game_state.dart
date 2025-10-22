/// Game State - 游戏状态定义
/// 
/// 职责：
/// - 定义游戏的各种状态
/// - 包含完整的游戏数据（棋盘、玩家、选中状态等）
/// - 为UI提供渲染所需的所有信息
/// 
/// 状态类型：
/// - GameInitial: 初始状态
/// - GamePlaying: 游戏进行中
/// - GameOver: 游戏结束
library;

import 'package:equatable/equatable.dart';
import '../models/board_state.dart';
import '../models/position.dart';
import '../models/piece_type.dart';
import '../models/game_result.dart';
import '../models/move.dart';
import 'game_event.dart';

/// 游戏状态基类
abstract class GameState extends Equatable {
  /// 当前棋盘状态
  final BoardState boardState;

  /// 游戏模式
  final GameMode mode;

  /// 选中的棋子位置
  final Position? selectedPiece;

  /// 合法移动位置列表
  final List<Position> validMoves;

  /// 移动历史记录
  final List<Move> moveHistory;

  /// 上一步移动
  final Move? lastMove;

  /// 最后被吃掉的棋子位置(用于动画效果)
  final Position? lastCapturedPosition;

  /// 游戏是否结束
  final bool isGameOver;

  /// 游戏结果
  final GameResult? gameResult;

  /// AI难度（仅在PVE模式下有效）
  final String? aiDifficulty;

  /// AI是否正在思考
  final bool isAIThinking;
  
  /// AI思考进度 (0.0-1.0)
  final double aiThinkingProgress;
  
  /// AI思考状态描述
  final String aiThinkingStatus;

  const GameState({
    required this.boardState,
    required this.mode,
    this.selectedPiece,
    this.validMoves = const [],
    this.moveHistory = const [],
    this.lastMove,
    this.lastCapturedPosition,
    this.isGameOver = false,
    this.gameResult,
    this.aiDifficulty,
    this.isAIThinking = false,
    this.aiThinkingProgress = 0.0,
    this.aiThinkingStatus = '',
  });

  /// 当前玩家
  PieceType get currentPlayer => boardState.currentPlayer;

  /// 是否有棋子被选中
  bool get hasPieceSelected => selectedPiece != null;

  /// 是否可以撤销
  bool get canUndo => moveHistory.isNotEmpty && !isGameOver;

  /// 黑方棋子数量
  int get blackPieceCount => boardState.blackPieces.length;

  /// 白方棋子数量
  int get whitePieceCount => boardState.whitePieces.length;

  /// 是否是AI的回合
  bool get isAITurn => mode == GameMode.pve && currentPlayer == PieceType.white;

  @override
  List<Object?> get props => [
        boardState,
        mode,
        selectedPiece,
        validMoves,
        moveHistory,
        lastMove,
        lastCapturedPosition,
        isGameOver,
        gameResult,
        aiDifficulty,
        isAIThinking,
        aiThinkingProgress,
        aiThinkingStatus,
      ];
}

/// 初始状态 - 游戏尚未开始
class GameInitial extends GameState {
  GameInitial()
      : super(
          boardState: BoardState.initial(),
          mode: GameMode.pvp,
        );

  @override
  String toString() => 'GameInitial()';
}

/// 游戏进行中状态
class GamePlaying extends GameState {
  const GamePlaying({
    required super.boardState,
    required super.mode,
    super.selectedPiece,
    super.validMoves,
    super.moveHistory,
    super.lastMove,
    super.lastCapturedPosition,
    super.aiDifficulty,
    super.isAIThinking,
    super.aiThinkingProgress,
    super.aiThinkingStatus,
  }) : super(
          isGameOver: false,
          gameResult: null,
        );

  /// 从另一个状态复制并更新部分字段
  GamePlaying copyWith({
    BoardState? boardState,
    GameMode? mode,
    Position? selectedPiece,
    bool clearSelectedPiece = false,
    List<Position>? validMoves,
    List<Move>? moveHistory,
    Move? lastMove,
    bool clearLastMove = false,
    Position? lastCapturedPosition,
    bool clearLastCapturedPosition = false,
    String? aiDifficulty,
    bool? isAIThinking,
    double? aiThinkingProgress,
    String? aiThinkingStatus,
  }) {
    return GamePlaying(
      boardState: boardState ?? this.boardState,
      mode: mode ?? this.mode,
      selectedPiece: clearSelectedPiece ? null : (selectedPiece ?? this.selectedPiece),
      validMoves: validMoves ?? this.validMoves,
      moveHistory: moveHistory ?? this.moveHistory,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      lastCapturedPosition: clearLastCapturedPosition ? null : (lastCapturedPosition ?? this.lastCapturedPosition),
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      isAIThinking: isAIThinking ?? this.isAIThinking,
      aiThinkingProgress: aiThinkingProgress ?? this.aiThinkingProgress,
      aiThinkingStatus: aiThinkingStatus ?? this.aiThinkingStatus,
    );
  }

  @override
  String toString() =>
      'GamePlaying(player: $currentPlayer, selected: $selectedPiece, '
      'moves: ${moveHistory.length}, aiThinking: $isAIThinking)';
}

/// 游戏结束状态
class GameOver extends GameState {
  const GameOver({
    required super.boardState,
    required super.mode,
    required GameResult gameResult,
    super.moveHistory,
    super.lastMove,
    super.lastCapturedPosition,
    super.aiDifficulty,
  }) : super(
          isGameOver: true,
          gameResult: gameResult,
          selectedPiece: null,
          validMoves: const [],
          isAIThinking: false,
        );

  /// 从GamePlaying转换为GameOver
  factory GameOver.fromPlaying(GamePlaying playing, GameResult gameResult) {
    return GameOver(
      boardState: playing.boardState,
      mode: playing.mode,
      gameResult: gameResult,
      moveHistory: playing.moveHistory,
      lastMove: playing.lastMove,
      lastCapturedPosition: playing.lastCapturedPosition,
      aiDifficulty: playing.aiDifficulty,
    );
  }

  /// 获胜方
  PieceType? get winner {
    if (gameResult == null) return null;
    switch (gameResult!.status) {
      case GameStatus.blackWin:
        return PieceType.black;
      case GameStatus.whiteWin:
        return PieceType.white;
      case GameStatus.draw:
        return null;
      default:
        return null;
    }
  }

  /// 是否平局
  bool get isDraw => gameResult?.status == GameStatus.draw;

  /// 胜利原因描述
  String get winReasonText {
    if (gameResult == null) return '';
    switch (gameResult!.status) {
      case GameStatus.blackWin:
        return gameResult!.reason;
      case GameStatus.whiteWin:
        return gameResult!.reason;
      case GameStatus.draw:
        return '平局：${gameResult!.reason}';
      default:
        return '';
    }
  }

  @override
  String toString() =>
      'GameOver(result: ${gameResult?.status}, winner: $winner, reason: ${gameResult?.reason})';
}

/// 游戏加载中状态（用于加载保存的游戏）
class GameLoading extends GameState {
  GameLoading()
      : super(
          boardState: BoardState.initial(),
          mode: GameMode.pvp,
        );

  @override
  String toString() => 'GameLoading()';
}

/// 游戏错误状态
class GameError extends GameState {
  final String errorMessage;

  const GameError({
    required this.errorMessage,
    required super.boardState,
    required super.mode,
  });

  @override
  List<Object?> get props => [errorMessage, ...super.props];

  @override
  String toString() => 'GameError(message: $errorMessage)';
}
