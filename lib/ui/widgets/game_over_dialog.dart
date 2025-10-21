/// Game Over Dialog - 游戏结束对话框
/// 
/// 职责：
/// - 显示游戏结束信息
/// - 显示胜负结果和原因
/// - 提供重新开始和返回选项
library;

import 'package:flutter/material.dart';
import '../../models/piece_type.dart';
import '../../models/game_result.dart';

/// 游戏结束对话框
class GameOverDialog extends StatelessWidget {
  final PieceType? winner;
  final GameResult gameResult;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GameOverDialog({
    super.key,
    required this.winner,
    required this.gameResult,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题图标
            Icon(
              _getResultIcon(),
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            
            // 结果标题
            Text(
              _getResultTitle(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // 结果详情
            Text(
              gameResult.reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            
            // 按钮组
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 退出按钮
                _DialogButton(
                  icon: Icons.close,
                  label: '退出',
                  onPressed: onExit,
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                
                // 重新开始按钮
                _DialogButton(
                  icon: Icons.refresh,
                  label: '再来一局',
                  onPressed: onRestart,
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取渐变色
  List<Color> _getGradientColors() {
    switch (gameResult.status) {
      case GameStatus.blackWin:
        return [Colors.amber.shade700, Colors.orange.shade800];
      case GameStatus.whiteWin:
        return [Colors.blue.shade600, Colors.indigo.shade700];
      case GameStatus.draw:
        return [Colors.grey.shade600, Colors.grey.shade800];
      default:
        return [Colors.grey.shade600, Colors.grey.shade800];
    }
  }

  /// 获取结果图标
  IconData _getResultIcon() {
    switch (gameResult.status) {
      case GameStatus.blackWin:
      case GameStatus.whiteWin:
        return Icons.emoji_events;
      case GameStatus.draw:
        return Icons.handshake;
      default:
        return Icons.info;
    }
  }

  /// 获取结果标题
  String _getResultTitle() {
    switch (gameResult.status) {
      case GameStatus.blackWin:
        return '黑方获胜！';
      case GameStatus.whiteWin:
        return '白方获胜！';
      case GameStatus.draw:
        return '平局';
      default:
        return '游戏结束';
    }
  }
}

/// 对话框按钮组件
class _DialogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const _DialogButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示游戏结束对话框的辅助函数
Future<void> showGameOverDialog(
  BuildContext context, {
  required PieceType? winner,
  required GameResult gameResult,
  required VoidCallback onRestart,
  required VoidCallback onExit,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => GameOverDialog(
      winner: winner,
      gameResult: gameResult,
      onRestart: onRestart,
      onExit: onExit,
    ),
  );
}
