/// AI Player - AI接口定义
/// 
/// 职责：
/// - 定义AI接口
/// - AI难度级别枚举
/// - AI移动选择抽象
library;

import '../models/board_state.dart';
import '../models/position.dart';

/// AI难度级别
enum AIDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case AIDifficulty.easy:
        return '简单';
      case AIDifficulty.medium:
        return '中等';
      case AIDifficulty.hard:
        return '困难';
    }
  }

  String get description {
    switch (this) {
      case AIDifficulty.easy:
        return 'AI会犯一些错误';
      case AIDifficulty.medium:
        return 'AI会认真思考';
      case AIDifficulty.hard:
        return 'AI会使用最优策略';
    }
  }

  static AIDifficulty fromString(String str) {
    switch (str.toLowerCase()) {
      case 'easy':
        return AIDifficulty.easy;
      case 'medium':
        return AIDifficulty.medium;
      case 'hard':
        return AIDifficulty.hard;
      default:
        return AIDifficulty.medium;
    }
  }
}

/// AI移动结果
class AIMoveResult {
  final Position from;
  final Position to;
  final int score;
  final int nodesEvaluated;
  final Duration thinkingTime;

  const AIMoveResult({
    required this.from,
    required this.to,
    required this.score,
    this.nodesEvaluated = 0,
    this.thinkingTime = Duration.zero,
  });

  @override
  String toString() =>
      'AIMoveResult(from: $from, to: $to, score: $score, nodes: $nodesEvaluated, time: ${thinkingTime.inMilliseconds}ms)';
}

/// AI玩家抽象接口
abstract class AIPlayer {
  final AIDifficulty difficulty;

  const AIPlayer(this.difficulty);

  /// 选择最佳移动
  /// 
  /// 返回null表示无法移动
  Future<AIMoveResult?> selectMove(BoardState board);

  /// AI名称
  String get name;

  /// AI描述
  String get description;
}
