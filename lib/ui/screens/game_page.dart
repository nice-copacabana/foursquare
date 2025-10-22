/// Game Page - 完整游戏页面
/// 
/// 职责：
/// - 集成GameBloc状态管理
/// - 显示棋盘和游戏信息
/// - 处理用户交互
/// - 响应游戏状态变化
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../models/position.dart';
import '../widgets/board_widget.dart';
import '../widgets/game_info_panel.dart';
import '../widgets/game_over_dialog.dart';
import 'game_replay_page.dart'; // 导入回放页面

/// 游戏页面
class GamePage extends StatelessWidget {
  final GameMode mode;
  final String? aiDifficulty;

  const GamePage({
    super.key,
    this.mode = GameMode.pvp,
    this.aiDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc()
        ..add(NewGameEvent(
          mode: mode,
          aiDifficulty: aiDifficulty,
        )),
      child: const _GamePageContent(),
    );
  }
}

class _GamePageContent extends StatelessWidget {
  const _GamePageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('四子游戏'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          // 监听游戏结束状态
          if (state is GameOver) {
            _showGameOverDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is GameInitial || state is GameLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is GameError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '错误：${state.errorMessage}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GameBloc>().add(const RestartGameEvent());
                    },
                    child: const Text('重新开始'),
                  ),
                ],
              ),
            );
          }

          // GamePlaying 或 GameOver 状态
          return _buildGameContent(context, state);
        },
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, GameState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        if (isLandscape) {
          // 横屏布局：棋盘在左，信息面板在右
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: _buildBoard(context, state),
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildInfoPanel(context, state),
                ),
              ),
            ],
          );
        } else {
          // 竖屏布局：棋盘在上，信息面板在下
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: _buildBoard(context, state),
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildInfoPanel(context, state),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildBoard(BuildContext context, GameState state) {
    return BoardWidget(
      boardState: state.boardState,
      selectedPiece: state.selectedPiece,
      validMoves: state.validMoves,
      lastMoveFrom: state.lastMove?.from,
      lastMoveTo: state.lastMove?.to,
      onPositionTapped: (position) => _handlePositionTapped(context, state, position),
    );
  }

  Widget _buildInfoPanel(BuildContext context, GameState state) {
    final isAIThinking = state is GamePlaying && state.isAIThinking;

    return GameInfoPanel(
      currentPlayer: state.currentPlayer,
      blackPieceCount: state.blackPieceCount,
      whitePieceCount: state.whitePieceCount,
      moveHistory: state.moveHistory,
      canUndo: state.canUndo && !isAIThinking,
      isAIThinking: isAIThinking,
      onUndo: () {
        context.read<GameBloc>().add(const UndoMoveEvent());
      },
      onRestart: () {
        _showRestartConfirmation(context);
      },
    );
  }

  void _handlePositionTapped(BuildContext context, GameState state, Position position) {
    if (state is! GamePlaying) return;
    if (state.isAIThinking) return;

    final bloc = context.read<GameBloc>();
    final piece = state.boardState.getPiece(position);

    // 如果有选中的棋子
    if (state.selectedPiece != null) {
      // 点击同一个位置 -> 取消选中
      if (state.selectedPiece == position) {
        bloc.add(const DeselectPieceEvent());
      }
      // 点击合法移动位置 -> 移动
      else if (state.validMoves.contains(position)) {
        bloc.add(MovePieceEvent(
          from: state.selectedPiece!,
          to: position,
        ));
      }
      // 点击己方其他棋子 -> 重新选中
      else if (piece == state.currentPlayer) {
        bloc.add(SelectPieceEvent(position));
      }
      // 其他情况 -> 取消选中
      else {
        bloc.add(const DeselectPieceEvent());
      }
    }
    // 没有选中的棋子
    else {
      // 点击己方棋子 -> 选中
      if (piece == state.currentPlayer) {
        bloc.add(SelectPieceEvent(position));
      }
    }
  }

  void _showGameOverDialog(BuildContext context, GameOver state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGameOverDialog(
        context,
        winner: state.winner,
        gameResult: state.gameResult!,
        onRestart: () {
          Navigator.of(context).pop();
          context.read<GameBloc>().add(const RestartGameEvent());
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onReplay: state.moveHistory.isNotEmpty
            ? () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GameReplayPage(
                      moveHistory: state.moveHistory,
                      gameTitle: state.mode == GameMode.pvp
                          ? 'PVP 游戏回放'
                          : 'PVE 游戏回放',
                    ),
                  ),
                );
              }
            : null,
      );
    });
  }

  void _showRestartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重新开始'),
        content: const Text('确定要重新开始游戏吗？当前进度将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameBloc>().add(const RestartGameEvent());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
