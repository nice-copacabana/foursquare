import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/piece_type.dart';
import '../../models/move.dart';
import '../../bloc/lan_game_bloc.dart';
import '../../bloc/lan_game_event.dart';
import '../../bloc/lan_game_state.dart';
import '../widgets/animated_board_widget.dart';
import '../widgets/game_info_panel.dart';
import '../widgets/game_over_dialog.dart';

class LanGamePage extends StatelessWidget {
  final bool isHost;

  const LanGamePage({
    super.key,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LanGameBloc()..add(StartLanGame(isHost: isHost)),
      child: const LanGameView(),
    );
  }
}

class LanGameView extends StatelessWidget {
  const LanGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网对战'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _showExitDialog(context);
          },
        ),
      ),
      body: BlocConsumer<LanGameBloc, LanGameState>(
        listener: (context, state) {
          if (state is LanGameFinished) {
            _showGameOverDialog(context, state);
          } else if (state is LanOpponentLeft) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('对方已离开游戏')),
            );
            Navigator.pop(context);
          } else if (state is LanGameError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is LanGameInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LanGamePlaying || state is LanGameFinished) {
            BoardState? board;
            PieceType? localColor;
            List<Move> history = [];

            if (state is LanGamePlaying) {
              board = state.boardState;
              localColor = state.localColor;
              history = state.moveHistory;
            } else if (state is LanGameFinished) {
              board = state.finalBoard;
              // We need localColor here ideally, but state.winner logic handles it?
              // The finished state doesn't hold localColor.
              // We should probably preserve playing state or make Finished extend Playing?
              // For now, let's assume we can't easily get local color if we switch state completely.
              // I should update LanGameFinished to include previous state info or localColor.
              // Quick fix: LanGamePlaying persists until reset?
              // Actually LanGameFinished is a separate state.
              // Let's modify LanGameBlock to keep LanGamePlaying as data or make Finished hold it.
            }

            if (board != null) {
              // If Finished, we might lose localColor reference if not careful.
              // Checking usage: GameInfoPanel needs currentPlayer, etc.
              // Let's rely on Bloc holding data or state structure.
              // I'll update LanGameState to include localColor in Finished if needed.
              // For now, let's cast safely or default.
            }

            // Simplification: Let's assume Playing state for UI rendering even if finished overlay is shown.
            // If I change state to LanGameFinished, the builder rebuilds.
            // I need LanGameFinished to contain the board data.

            return _buildGameUI(context, state);
          }

          return const Center(child: Text('Unknown State'));
        },
      ),
    );
  }

  Widget _buildGameUI(BuildContext context, LanGameState state) {
    BoardState board;
    PieceType localColor;
    List<Move> history;

    if (state is LanGamePlaying) {
      board = state.boardState;
      localColor = state.localColor;
      history = state.moveHistory;
    } else if (state is LanGameFinished) {
      board = state.finalBoard;
      localColor = state.localColor;
      history = state.moveHistory;
    } else {
      return const SizedBox.shrink();
    }

    // Determine user interaction
    // Can only move if it's my turn AND game is playing.
    final canMove =
        (state is LanGamePlaying) && (board.currentPlayer == localColor);

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedBoardWidget(
                boardState: board,
                onMove: (from, to) {
                  if (canMove) {
                    context.read<LanGameBloc>().add(
                          LanLocalPlayerMoved(Move(
                            from: from,
                            to: to,
                            player: localColor,
                          ),),
                        );
                  }
                },
                interactive: canMove,
                // Highlight local player's pieces? or something?
                // AnimatedBoardWidget handles piece display.
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: GameInfoPanel(
            currentPlayer: board.currentPlayer,
            blackPieceCount: board.blackPieces.length,
            whitePieceCount: board.whitePieces.length,
            moveHistory: history,
            canUndo: false, // No undo in LAN for now
            canRedo: false,
            onRestart: null, // Restart logic to be added
          ),
        ),
      ],
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出游戏?'),
        content: const Text('这将断开连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<LanGameBloc>().add(LanExitGame());
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close Game Page
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, LanGameFinished state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        winner: state.winner,
        reason: state.reason,
        onRestart: () {
          Navigator.pop(context);
          // Implement restart?
          // context.read<LanGameBloc>().add(LanRestartGame());
        },
        onExit: () {
          Navigator.pop(context);
          context.read<LanGameBloc>().add(LanExitGame());
          Navigator.pop(context);
        },
      ),
    );
  }
}
