/// Game Replay Service - 游戏回放服务
///
/// 职责：
/// - 管理游戏历史记录的回放
/// - 提供前进/后退导航功能
/// - 支持跳转到特定步骤
/// - 记录回放状态
library;

import '../engine/game_engine.dart';
import '../models/board_state.dart';
import '../models/move.dart';
import '../models/piece_type.dart';

/// 回放状态
class ReplayState {
  /// 当前步骤索引（-1表示初始状态）
  final int currentStep;

  /// 总步数
  final int totalSteps;

  /// 当前棋盘状态
  final BoardState boardState;

  /// 当前移动
  final Move? currentMove;

  /// 是否在回放模式
  final bool isReplaying;

  const ReplayState({
    required this.currentStep,
    required this.totalSteps,
    required this.boardState,
    this.currentMove,
    this.isReplaying = false,
  });

  /// 是否在初始状态
  bool get isAtStart => currentStep < 0;

  /// 是否在最后一步
  bool get isAtEnd => currentStep >= totalSteps - 1;

  /// 是否可以前进
  bool get canGoForward => !isAtEnd && totalSteps > 0;

  /// 是否可以后退
  bool get canGoBackward => !isAtStart;

  /// 当前步骤描述
  String get stepDescription {
    if (isAtStart) {
      return '初始状态';
    }
    return '第 ${currentStep + 1} 步 / 共 $totalSteps 步';
  }

  ReplayState copyWith({
    int? currentStep,
    int? totalSteps,
    BoardState? boardState,
    Move? currentMove,
    bool? isReplaying,
    bool clearCurrentMove = false,
  }) {
    return ReplayState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      boardState: boardState ?? this.boardState,
      currentMove: clearCurrentMove ? null : (currentMove ?? this.currentMove),
      isReplaying: isReplaying ?? this.isReplaying,
    );
  }
}

/// 游戏回放服务
class GameReplayService {
  /// 完整的移动历史
  List<Move> _moveHistory = [];

  PieceType _startingPlayer = PieceType.black;

  /// 当前回放状态
  ReplayState _state = ReplayState(
    currentStep: -1,
    totalSteps: 0,
    boardState: BoardState.initial(),
    isReplaying: false,
  );

  /// 获取当前回放状态
  ReplayState get state => _state;

  /// 初始化回放（使用完整的移动历史）
  ReplayState startReplay(
    List<Move> moveHistory, {
    PieceType startingPlayer = PieceType.black,
  }) {
    _moveHistory = List.from(moveHistory);
    _startingPlayer = startingPlayer;
    _state = ReplayState(
      currentStep: -1,
      totalSteps: _moveHistory.length,
      boardState: BoardState.initial(currentPlayer: _startingPlayer),
      isReplaying: true,
    );
    return _state;
  }

  /// 前进一步
  ReplayState goForward() {
    if (!_state.canGoForward) {
      return _state;
    }

    final nextStep = _state.currentStep + 1;
    final move = _moveHistory[nextStep];
    final newBoard = _rebuildBoard(nextStep);

    _state = _state.copyWith(
      currentStep: nextStep,
      boardState: newBoard,
      currentMove: move,
    );

    return _state;
  }

  /// 后退一步
  ReplayState goBackward() {
    if (!_state.canGoBackward) {
      return _state;
    }

    final prevStep = _state.currentStep - 1;

    final newBoard = _rebuildBoard(prevStep);
    final currentMove = prevStep >= 0 ? _moveHistory[prevStep] : null;

    _state = _state.copyWith(
      currentStep: prevStep,
      boardState: newBoard,
      currentMove: currentMove,
      clearCurrentMove: prevStep < 0,
    );

    return _state;
  }

  /// 跳转到第一步
  ReplayState goToStart() {
    _state = _state.copyWith(
      currentStep: -1,
      boardState: BoardState.initial(currentPlayer: _startingPlayer),
      clearCurrentMove: true,
    );
    return _state;
  }

  /// 跳转到最后一步
  ReplayState goToEnd() {
    if (_moveHistory.isEmpty) {
      return _state;
    }

    final newBoard = _rebuildBoard(_moveHistory.length - 1);

    _state = _state.copyWith(
      currentStep: _moveHistory.length - 1,
      boardState: newBoard,
      currentMove: _moveHistory.last,
    );

    return _state;
  }

  /// 跳转到指定步骤
  ReplayState goToStep(int step) {
    if (step < -1 || step >= _moveHistory.length) {
      return _state;
    }

    if (step == -1) {
      return goToStart();
    }

    final newBoard = _rebuildBoard(step);

    _state = _state.copyWith(
      currentStep: step,
      boardState: newBoard,
      currentMove: _moveHistory[step],
    );

    return _state;
  }

  BoardState _rebuildBoard(int lastStep) {
    var board = BoardState.initial(currentPlayer: _startingPlayer);
    if (lastStep < 0) return board;

    final engine = GameEngine()..startNewGame();
    var noCapturePlyCount = 0;
    for (int i = 0; i <= lastStep; i++) {
      final move = _moveHistory[i];
      final result = engine.executeMove(
        board,
        move.from,
        move.to,
        capturedPiecesOverride: move.capturedPieces,
        noCapturePlyCount: noCapturePlyCount,
      );
      if (!result.success || result.newBoard == null) {
        throw StateError('Invalid replay move at step $i');
      }
      board = result.newBoard!;
      noCapturePlyCount = result.noCapturePlyCount;
    }
    return board;
  }

  /// 退出回放模式
  void exitReplay() {
    _state = _state.copyWith(isReplaying: false);
    _moveHistory.clear();
  }

  /// 获取移动历史
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  /// 获取指定步骤的移动
  Move? getMoveAtStep(int step) {
    if (step < 0 || step >= _moveHistory.length) {
      return null;
    }
    return _moveHistory[step];
  }

  /// 重置服务
  void reset() {
    _moveHistory.clear();
    _state = ReplayState(
      currentStep: -1,
      totalSteps: 0,
      boardState: BoardState.initial(),
      isReplaying: false,
    );
  }
}
