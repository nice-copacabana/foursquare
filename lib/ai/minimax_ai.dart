/// Minimax AI - Minimax算法实现
/// 
/// 职责：
/// - 实现Minimax搜索算法
/// - Alpha-Beta剪枝优化
/// - 提供不同难度的AI
library;

import 'dart:math';
import '../models/board_state.dart';
import '../models/piece_type.dart';
import '../models/position.dart';
import '../engine/game_engine.dart';
import 'ai_player.dart';
import 'evaluation.dart';

/// Minimax AI实现
class MinimaxAI extends AIPlayer {
  final GameEngine _engine = GameEngine();
  final int _maxDepth;
  final Random _random = Random();
  
  MinimaxAI(super.difficulty) : _maxDepth = _getDepthForDifficulty(difficulty);
  
  static int _getDepthForDifficulty(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return 2;
      case AIDifficulty.medium:
        return 3;
      case AIDifficulty.hard:
        return 4;
    }
  }
  
  @override
  String get name => 'Minimax AI';
  
  @override
  String get description => 'AI使用Minimax算法和Alpha-Beta剪枝';
  
  @override
  Future<AIMoveResult?> selectMove(BoardState board) async {
    final startTime = DateTime.now();
    int nodesEvaluated = 0;
    
    final possibleMoves = _engine.getPossibleMoves(board);
    if (possibleMoves.isEmpty) return null;
    
    // 简单难度：30%概率随机移动
    if (difficulty == AIDifficulty.easy && _random.nextDouble() < 0.3) {
      final randomMove = possibleMoves[_random.nextInt(possibleMoves.length)];
      return AIMoveResult(
        from: randomMove.from,
        to: randomMove.to,
        score: 0,
        nodesEvaluated: 1,
        thinkingTime: DateTime.now().difference(startTime),
      );
    }
    
    Position? bestFrom;
    Position? bestTo;
    int bestScore = -9999999;
    
    for (final move in possibleMoves) {
      final result = _engine.executeMove(board, move.from, move.to);
      if (!result.success) continue;
      
      nodesEvaluated++;
      final score = -_minimax(
        result.newBoard,
        _maxDepth - 1,
        -9999999,
        9999999,
        false,
        result.newBoard.currentPlayer,
      );
      
      if (score > bestScore) {
        bestScore = score;
        bestFrom = move.from;
        bestTo = move.to;
      }
    }
    
    if (bestFrom == null || bestTo == null) return null;
    
    return AIMoveResult(
      from: bestFrom,
      to: bestTo,
      score: bestScore,
      nodesEvaluated: nodesEvaluated,
      thinkingTime: DateTime.now().difference(startTime),
    );
  }
  
  int _minimax(
    BoardState board,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
    PieceType aiPlayer,
  ) {
    // 检查游戏结束
    final gameResult = _engine.checkGameOver(board);
    if (gameResult != null) {
      if (gameResult.status.toString().contains(aiPlayer.toString())) {
        return 10000 + depth; // AI获胜
      } else {
        return -10000 - depth; // AI失败
      }
    }
    
    // 达到深度限制
    if (depth == 0) {
      return BoardEvaluator.evaluate(board, aiPlayer);
    }
    
    final possibleMoves = _engine.getPossibleMoves(board);
    if (possibleMoves.isEmpty) {
      return BoardEvaluator.evaluate(board, aiPlayer);
    }
    
    if (isMaximizing) {
      int maxScore = -9999999;
      for (final move in possibleMoves) {
        final result = _engine.executeMove(board, move.from, move.to);
        if (!result.success) continue;
        
        final score = _minimax(result.newBoard, depth - 1, alpha, beta, false, aiPlayer);
        maxScore = max(maxScore, score);
        alpha = max(alpha, score);
        if (beta <= alpha) break; // Beta剪枝
      }
      return maxScore;
    } else {
      int minScore = 9999999;
      for (final move in possibleMoves) {
        final result = _engine.executeMove(board, move.from, move.to);
        if (!result.success) continue;
        
        final score = _minimax(result.newBoard, depth - 1, alpha, beta, true, aiPlayer);
        minScore = min(minScore, score);
        beta = min(beta, score);
        if (beta <= alpha) break; // Alpha剪枝
      }
      return minScore;
    }
  }
}
