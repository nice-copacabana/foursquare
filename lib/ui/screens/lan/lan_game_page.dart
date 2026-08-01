import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../engine/move_validator.dart';
import '../../../models/board_state.dart';
import '../../../models/game_result.dart';
import '../../../models/piece_type.dart';
import '../../../models/move.dart';
import '../../../models/position.dart';
import '../../../bloc/lan_game_bloc.dart';
import '../../../bloc/lan_game_event.dart';
import '../../../bloc/lan_game_state.dart';
import '../../widgets/animated_board_widget.dart';
import '../../widgets/game_info_panel.dart';
import '../../widgets/game_over_dialog.dart';
import '../game_replay_page.dart';

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
    return const _LanGameViewBody();
  }
}

class _LanGameViewBody extends StatefulWidget {
  const _LanGameViewBody();

  @override
  State<_LanGameViewBody> createState() => _LanGameViewBodyState();
}

class _LanGameViewBodyState extends State<_LanGameViewBody> {
  final MoveValidator _moveValidator = MoveValidator();
  Position? _selectedPiece;
  List<Position> _validMoves = const [];
  Timer? _displayTicker;

  @override
  void initState() {
    super.initState();
    _displayTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _displayTicker?.cancel();
    super.dispose();
  }

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
    final canMove = state is LanGamePlaying && state.isLocalTurn;
    final turnRemaining =
        state is LanGamePlaying && state.turnDeadlineUtc != null
            ? state.turnDeadlineUtc!.difference(DateTime.now().toUtc())
            : Duration.zero;

    return Column(
      children: [
        if (state is LanGamePlaying &&
            (!state.isSynchronized || state.isReconnecting))
          MaterialBanner(
            content: Text(
              state.isReconnecting ? '连接中断，正在等待重连…' : '正在同步主机棋局…',
            ),
            leading: const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedBoardWidget(
                boardState: board,
                selectedPiece: _selectedPiece,
                validMoves: _validMoves,
                lastMoveFrom: history.isNotEmpty ? history.last.from : null,
                lastMoveTo: history.isNotEmpty ? history.last.to : null,
                capturedPiecePosition:
                    history.isNotEmpty ? history.last.capturedPiece : null,
                flipBoard: localColor == PieceType.white,
                onPositionTapped: (position) => _handlePositionTapped(
                  context,
                  board,
                  localColor,
                  position,
                  canMove,
                ),
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
            turnRemaining:
                turnRemaining.isNegative ? Duration.zero : turnRemaining,
            onRestart: null,
          ),
        ),
      ],
    );
  }

  void _handlePositionTapped(
    BuildContext context,
    BoardState board,
    PieceType localColor,
    Position position,
    bool canMove,
  ) {
    if (!canMove) {
      return;
    }

    final piece = board.getPiece(position);
    if (_selectedPiece == null) {
      if (piece == localColor) {
        setState(() {
          _selectedPiece = position;
          _validMoves = _moveValidator.getValidMoves(board, position);
        });
      }
      return;
    }

    if (_selectedPiece == position) {
      setState(() {
        _selectedPiece = null;
        _validMoves = const [];
      });
      return;
    }

    if (piece == localColor) {
      setState(() {
        _selectedPiece = position;
        _validMoves = _moveValidator.getValidMoves(board, position);
      });
      return;
    }

    if (_validMoves.contains(position)) {
      context.read<LanGameBloc>().add(
            LanLocalPlayerMoved(
              Move.now(
                from: _selectedPiece!,
                to: position,
                player: localColor,
              ),
            ),
          );
      setState(() {
        _selectedPiece = null;
        _validMoves = const [];
      });
    }
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
        gameResult: _toGameResult(state),
        onRestart: () {
          Navigator.pop(context);
          context.read<LanGameBloc>().add(LanRestartGame());
        },
        onExit: () {
          Navigator.pop(context);
          context.read<LanGameBloc>().add(LanExitGame());
          Navigator.pop(context);
        },
        onReplay: state.moveHistory.isEmpty
            ? null
            : () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameReplayPage(
                      moveHistory: state.moveHistory,
                      startingPlayer: state.startingPlayer,
                      gameTitle: '局域网对局回放',
                    ),
                  ),
                );
              },
      ),
    );
  }

  GameResult _toGameResult(LanGameFinished state) {
    if (state.authoritativeResult != null) {
      return state.authoritativeResult!;
    }
    if (state.winner == PieceType.black) {
      return GameResult.blackWin(
        reason: state.reason,
        moveCount: state.moveHistory.length,
        duration: Duration.zero,
      );
    }
    if (state.winner == PieceType.white) {
      return GameResult.whiteWin(
        reason: state.reason,
        moveCount: state.moveHistory.length,
        duration: Duration.zero,
      );
    }
    return GameResult.draw(
      reason: state.reason,
      moveCount: state.moveHistory.length,
      duration: Duration.zero,
    );
  }
}
