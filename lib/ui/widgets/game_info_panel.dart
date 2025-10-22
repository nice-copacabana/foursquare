/// Game Info Panel - 游戏信息面板
/// 
/// 职责：
/// - 显示当前玩家
/// - 显示双方棋子数量
/// - 显示移动历史
/// - 提供撤销按钮
library;

import 'package:flutter/material.dart';
import '../../models/piece_type.dart';
import '../../models/move.dart';

/// 游戏信息面板
class GameInfoPanel extends StatelessWidget {
  final PieceType currentPlayer;
  final int blackPieceCount;
  final int whitePieceCount;
  final List<Move> moveHistory;
  final bool canUndo;
  final VoidCallback? onUndo;
  final VoidCallback? onRestart;
  final bool isAIThinking;
  final double aiThinkingProgress;
  final String aiThinkingStatus;

  const GameInfoPanel({
    super.key,
    required this.currentPlayer,
    required this.blackPieceCount,
    required this.whitePieceCount,
    required this.moveHistory,
    required this.canUndo,
    this.onUndo,
    this.onRestart,
    this.isAIThinking = false,
    this.aiThinkingProgress = 0.0,
    this.aiThinkingStatus = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前玩家指示器
          _CurrentPlayerIndicator(
            currentPlayer: currentPlayer,
            isAIThinking: isAIThinking,
          ),
          const SizedBox(height: 16),
          
          // AI思考指示器
          if (isAIThinking)
            _AIThinkingIndicator(
              progress: aiThinkingProgress,
              status: aiThinkingStatus,
            ),
          if (isAIThinking) const SizedBox(height: 16),
          
          // 棋子数量统计
          _PieceCountSection(
            blackCount: blackPieceCount,
            whiteCount: whitePieceCount,
          ),
          const SizedBox(height: 16),
          
          // 移动历史
          _MoveHistorySection(
            moveHistory: moveHistory,
          ),
          const SizedBox(height: 16),
          
          // 操作按钮
          _ActionButtons(
            canUndo: canUndo,
            onUndo: onUndo,
            onRestart: onRestart,
          ),
        ],
      ),
    );
  }
}

/// 当前玩家指示器
class _CurrentPlayerIndicator extends StatelessWidget {
  final PieceType currentPlayer;
  final bool isAIThinking;

  const _CurrentPlayerIndicator({
    required this.currentPlayer,
    required this.isAIThinking,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPlayer == PieceType.black
                ? Colors.grey.shade800
                : Colors.white,
            border: Border.all(
              color: Colors.grey.shade400,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (currentPlayer == PieceType.black
                        ? Colors.amber
                        : Colors.blue)
                    .withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentPlayer == PieceType.black ? '黑方回合' : '白方回合',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAIThinking)
                const Text(
                  'AI思考中...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 棋子数量统计区域
class _PieceCountSection extends StatelessWidget {
  final int blackCount;
  final int whiteCount;

  const _PieceCountSection({
    required this.blackCount,
    required this.whiteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _PieceCounter(
          label: '黑方',
          count: blackCount,
          color: Colors.grey.shade800,
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey.shade300,
        ),
        _PieceCounter(
          label: '白方',
          count: whiteCount,
          color: Colors.white,
          borderColor: Colors.grey.shade400,
        ),
      ],
    );
  }
}

/// 单个棋子计数器
class _PieceCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color? borderColor;

  const _PieceCounter({
    required this.label,
    required this.count,
    required this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 2)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 移动历史区域
class _MoveHistorySection extends StatelessWidget {
  final List<Move> moveHistory;

  const _MoveHistorySection({
    required this.moveHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '移动历史 (${moveHistory.length}步)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: moveHistory.isEmpty
              ? const Center(
                  child: Text(
                    '暂无移动记录',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: moveHistory.length,
                  itemBuilder: (context, index) {
                    final move = moveHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: move.player == PieceType.black
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${move.from} → ${move.to}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (move.capturedPiece != null)
                            const Row(
                              children: [
                                SizedBox(width: 4),
                                Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// AI思考指示器
class _AIThinkingIndicator extends StatelessWidget {
  final double progress;
  final String status;

  const _AIThinkingIndicator({
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI思考中',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue.shade400,
              ),
              minHeight: 6,
            ),
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 操作按钮区域
class _ActionButtons extends StatelessWidget {
  final bool canUndo;
  final VoidCallback? onUndo;
  final VoidCallback? onRestart;

  const _ActionButtons({
    required this.canUndo,
    this.onUndo,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('撤销'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新开始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
