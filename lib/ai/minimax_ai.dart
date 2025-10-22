/// Minimax AI - Minimax算法实现（优化版）
/// 
/// 职责：
/// - 实现Minimax搜索算法
/// - Alpha-Beta剪枝优化
/// - 置换表缓存优化
/// - 移动排序启发式
/// - 动态深度调整
/// - 迭代加深搜索
/// - 提供不同难度的AI
library;

import 'dart:math';
import '../models/board_state.dart';
import '../models/piece_type.dart';
import '../models/position.dart';
import '../engine/game_engine.dart';
import 'ai_player.dart';
import 'evaluation.dart';

/// 置换表条目
class _TranspositionEntry {
  final int score;
  final int depth;
  final DateTime timestamp;
  
  _TranspositionEntry(this.score, this.depth, this.timestamp);
}

/// Minimax AI实现（优化版）
class MinimaxAI extends AIPlayer {
  final GameEngine _engine = GameEngine();
  final int _baseDepth;
  final Random _random = Random();
  
  // 置换表（缓存已评估的局面）
  final Map<String, _TranspositionEntry> _transpositionTable = {};
  static const int _maxTranspositionTableSize = 10000;
  
  // 历史启发式（记录好的移动）
  final Map<String, int> _historyTable = {};
  
  // AI思考进度回调
  Function(double progress, String status)? _progressCallback;
  
  MinimaxAI(super.difficulty) : _baseDepth = _getDepthForDifficulty(difficulty);
  
  /// 设置进度回调
  void setProgressCallback(Function(double progress, String status)? callback) {
    _progressCallback = callback;
  }
  
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
  String get name => 'Minimax AI (优化版)';
  
  @override
  String get description => 'AI使用优化的Minimax算法：置换表、移动排序、动态深度、迭代加深';
  
  /// 动态调整搜索深度
  int _getDynamicDepth(BoardState board) {
    // 统计棋盘上的棋子总数
    int totalPieces = 0;
    for (int x = 0; x < 4; x++) {
      for (int y = 0; y < 4; y++) {
        final piece = board.getPiece(Position(x, y));
        if (piece != PieceType.empty) {
          totalPieces++;
        }
      }
    }
    
    // 根据棋子数量调整深度
    if (totalPieces >= 6) {
      return _baseDepth; // 开局，使用基础深度
    } else if (totalPieces >= 4) {
      return _baseDepth + 1; // 中局，增加深度
    } else {
      return _baseDepth + 2; // 残局，显著增加深度以精确计算
    }
  }
  
  /// 生成棋盘哈希值（用于置换表）
  String _getBoardHash(BoardState board) {
    final buffer = StringBuffer();
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        final piece = board.getPiece(Position(x, y));
        buffer.write(piece == PieceType.black ? 'B' : 
                     piece == PieceType.white ? 'W' : 'E',);
      }
    }
    buffer.write(board.currentPlayer == PieceType.black ? 'B' : 'W');
    return buffer.toString();
  }
  
  /// 移动排序启发式
  List<_MoveOption> _sortMoves(
    List<_MoveOption> moves,
    BoardState board,
    PieceType player,
  ) {
    // 为每个移动计算优先级分数
    final scoredMoves = <_ScoredMove>[];
    
    for (final move in moves) {
      int priority = 0;
      
      // 1. 检查是否可以吃子（最高优先级）
      final result = _engine.executeMove(board, move.from, move.to);
      if (result.success && result.captured != null) {
        priority += 1000; // 吃子移动优先级最高
      }
      
      // 2. 检查历史启发式
      final historyKey = '${move.from.x},${move.from.y}-${move.to.x},${move.to.y}';
      priority += _historyTable[historyKey] ?? 0;
      
      // 3. 中心位置优先
      final centerDistance = (move.to.x - 1.5).abs() + (move.to.y - 1.5).abs();
      priority += (4 - centerDistance * 10).toInt();
      
      scoredMoves.add(_ScoredMove(move, priority));
    }
    
    // 按优先级降序排序
    scoredMoves.sort((a, b) => b.priority.compareTo(a.priority));
    return scoredMoves.map((sm) => sm.move).toList();
  }
  
  @override
  Future<AIMoveResult?> selectMove(BoardState board) async {
    final startTime = DateTime.now();
    int nodesEvaluated = 0;
    
    // 清理置换表（避免内存过大）
    if (_transpositionTable.length > _maxTranspositionTableSize) {
      _transpositionTable.clear();
    }
    
    final possibleMoves = _engine.getPossibleMoves(board, board.currentPlayer);
    if (possibleMoves.isEmpty) return null;
    
    // 转换为移动列表
    final moveList = <_MoveOption>[];
    for (final entry in possibleMoves.entries) {
      for (final to in entry.value) {
        moveList.add(_MoveOption(from: entry.key, to: to));
      }
    }
    
    if (moveList.isEmpty) return null;
    
    // 简单难度：30%概率随机移动
    if (difficulty == AIDifficulty.easy && _random.nextDouble() < 0.3) {
      final randomMove = moveList[_random.nextInt(moveList.length)];
      return AIMoveResult(
        from: randomMove.from,
        to: randomMove.to,
        score: 0,
        nodesEvaluated: 1,
        thinkingTime: DateTime.now().difference(startTime),
      );
    }
    
    // 动态调整深度
    final maxDepth = _getDynamicDepth(board);
    
    Position? bestFrom;
    Position? bestTo;
    int bestScore = -9999999;
    
    // 对移动进行排序
    final sortedMoves = _sortMoves(moveList, board, board.currentPlayer);
    
    // 迭代加深搜索（从深度1开始，逐步增加）
    for (int depth = 1; depth <= maxDepth; depth++) {
      // 检查是否超时（困难模式最多1秒）
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds > 1000 && difficulty == AIDifficulty.hard) {
        break;
      }
      
      // 报告进度
      _progressCallback?.call(
        depth / maxDepth,
        '搜索深度 $depth/$maxDepth',
      );
      
      for (final move in sortedMoves) {
        final result = _engine.executeMove(board, move.from, move.to);
        if (!result.success || result.newBoard == null) continue;
        
        nodesEvaluated++;
        final score = -_minimax(
          result.newBoard!,
          depth - 1,
          -9999999,
          9999999,
          false,
          board.currentPlayer,
        );
        
        if (score > bestScore) {
          bestScore = score;
          bestFrom = move.from;
          bestTo = move.to;
          
          // 更新历史表
          final historyKey = '${move.from.x},${move.from.y}-${move.to.x},${move.to.y}';
          _historyTable[historyKey] = (_historyTable[historyKey] ?? 0) + depth;
        }
      }
    }
    
    if (bestFrom == null || bestTo == null) return null;
    
    // 完成进度
    _progressCallback?.call(1.0, '完成，评估了 $nodesEvaluated 个节点');
    
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
    // 检查置换表
    final boardHash = _getBoardHash(board);
    final cached = _transpositionTable[boardHash];
    if (cached != null && cached.depth >= depth) {
      return cached.score;
    }
    
    // 检查游戏结束
    final gameResult = _engine.checkGameOver(board);
    if (gameResult != null) {
      final score = gameResult.winner == aiPlayer
          ? 10000 + depth // AI获胜
          : gameResult.winner == aiPlayer.getOpponent()
              ? -10000 - depth // AI失败
              : 0; // 平局
      
      // 存入置换表
      _transpositionTable[boardHash] = _TranspositionEntry(
        score,
        depth,
        DateTime.now(),
      );
      return score;
    }
    
    // 达到深度限制
    if (depth == 0) {
      final score = BoardEvaluator.evaluate(board, aiPlayer);
      _transpositionTable[boardHash] = _TranspositionEntry(
        score,
        0,
        DateTime.now(),
      );
      return score;
    }
    
    final possibleMoves = _engine.getPossibleMoves(board, board.currentPlayer);
    if (possibleMoves.isEmpty) {
      final score = BoardEvaluator.evaluate(board, aiPlayer);
      _transpositionTable[boardHash] = _TranspositionEntry(
        score,
        depth,
        DateTime.now(),
      );
      return score;
    }
    
    // 转换为移动列表
    final moveList = <_MoveOption>[];
    for (final entry in possibleMoves.entries) {
      for (final to in entry.value) {
        moveList.add(_MoveOption(from: entry.key, to: to));
      }
    }
    
    // 移动排序
    final sortedMoves = _sortMoves(moveList, board, board.currentPlayer);
    
    int finalScore;
    if (isMaximizing) {
      int maxScore = -9999999;
      for (final move in sortedMoves) {
        final result = _engine.executeMove(board, move.from, move.to);
        if (!result.success || result.newBoard == null) continue;
        
        final score = _minimax(result.newBoard!, depth - 1, alpha, beta, false, aiPlayer);
        maxScore = max(maxScore, score);
        alpha = max(alpha, score);
        if (beta <= alpha) break; // Beta剪枝
      }
      finalScore = maxScore;
    } else {
      int minScore = 9999999;
      for (final move in sortedMoves) {
        final result = _engine.executeMove(board, move.from, move.to);
        if (!result.success || result.newBoard == null) continue;
        
        final score = _minimax(result.newBoard!, depth - 1, alpha, beta, true, aiPlayer);
        minScore = min(minScore, score);
        beta = min(beta, score);
        if (beta <= alpha) break; // Alpha剪枝
      }
      finalScore = minScore;
    }
    
    // 存入置换表
    _transpositionTable[boardHash] = _TranspositionEntry(
      finalScore,
      depth,
      DateTime.now(),
    );
    
    return finalScore;
  }
}

/// 移动选项内部类
class _MoveOption {
  final Position from;
  final Position to;
  
  _MoveOption({required this.from, required this.to});
}

/// 带分数的移动（用于排序）
class _ScoredMove {
  final _MoveOption move;
  final int priority;
  
  _ScoredMove(this.move, this.priority);
}
