/// Board Evaluation - 棋盘评估函数
/// 
/// 职责：
/// - 评估棋盘局面优劣
/// - 为AI提供决策依据
library;

import '../models/board_state.dart';
import '../models/piece_type.dart';
import '../models/position.dart';

/// 棋盘评估器
class BoardEvaluator {
  /// 评估棋盘局面
  /// 
  /// 返回分数：
  /// - 正数表示白方优势
  /// - 负数表示黑方优势
  /// - 0表示均势
  static int evaluate(BoardState board, PieceType player) {
    int score = 0;
    
    // 1. 棋子数量差异 (最重要)
    score += _evaluatePieceCount(board, player);
    
    // 2. 位置优势
    score += _evaluatePositions(board, player);
    
    // 3. 移动能力
    score += _evaluateMobility(board, player);
    
    return score;
  }
  
  /// 评估棋子数量
  static int _evaluatePieceCount(BoardState board, PieceType player) {
    final isWhite = player == PieceType.white;
    final myCount = isWhite ? board.whitePieces.length : board.blackPieces.length;
    final oppCount = isWhite ? board.blackPieces.length : board.whitePieces.length;
    
    // 每个棋子价值1000分
    return (myCount - oppCount) * 1000;
  }
  
  /// 评估棋子位置
  static int _evaluatePositions(BoardState board, PieceType player) {
    int score = 0;
    final isWhite = player == PieceType.white;
    final myPieces = isWhite ? board.whitePieces : board.blackPieces;
    
    for (final pos in myPieces) {
      // 中心位置更有价值
      score += _getPositionValue(pos);
    }
    
    return score;
  }
  
  /// 获取位置价值
  static int _getPositionValue(Position pos) {
    // 中心位置价值更高
    const centerPositions = [
      Position(1, 1), Position(1, 2),
      Position(2, 1), Position(2, 2),
    ];
    
    if (centerPositions.contains(pos)) {
      return 20;
    }
    return 10;
  }
  
  /// 评估移动能力
  static int _evaluateMobility(BoardState board, PieceType player) {
    // 可移动的棋子数量
    int mobility = 0;
    final isWhite = player == PieceType.white;
    final myPieces = isWhite ? board.whitePieces : board.blackPieces;
    
    for (final pos in myPieces) {
      final adjacent = pos.getAdjacentPositions();
      for (final adj in adjacent) {
        if (board.getPiece(adj) == PieceType.empty) {
          mobility++;
        }
      }
    }
    
    return mobility * 5;
  }
}
