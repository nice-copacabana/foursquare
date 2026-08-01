import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/online_game_bloc.dart';
import '../../bloc/online_game_event.dart';
import '../../bloc/online_game_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/board_state.dart';
import '../../models/online_protocol.dart';
import '../../models/piece_type.dart';
import '../../models/position.dart';
import '../../services/online_game_transport.dart';
import '../../services/online_identity_service.dart';
import '../widgets/themed_board_widget.dart';

class OnlineGamePage extends StatelessWidget {
  const OnlineGamePage({
    super.key,
    required this.transport,
    this.identityService,
    this.now,
  });

  final OnlineGameTransportClient transport;
  final OnlineIdentityService? identityService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnlineGameBloc(
        transport: transport,
        identityService: identityService ?? OnlineIdentityService(),
      ),
      child: OnlineGameView(now: now ?? DateTime.now),
    );
  }
}

class OnlineGameView extends StatefulWidget {
  const OnlineGameView({
    super.key,
    this.now = DateTime.now,
  });

  final DateTime Function() now;

  @override
  State<OnlineGameView> createState() => _OnlineGameViewState();
}

class _OnlineGameViewState extends State<OnlineGameView> {
  Timer? _ticker;
  Position? _selected;
  List<Position> _validMoves = const [];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onlineBattleTitle)),
      body: SafeArea(
        child: BlocConsumer<OnlineGameBloc, OnlineBattleState>(
          listener: (context, state) {
            if (!state.canMove || state.isMovePending) _clearSelection();
          },
          builder: (context, state) => switch (state.phase) {
            OnlineBattlePhase.idle => _buildIntro(context, l10n),
            OnlineBattlePhase.connecting => _buildProgress(
                context,
                l10n.onlineConnecting,
                canCancel: false,
              ),
            OnlineBattlePhase.matching => _buildProgress(
                context,
                l10n.onlineSearching,
                canCancel: true,
              ),
            OnlineBattlePhase.recovering => _buildProgress(
                context,
                l10n.onlineRecovering,
                canCancel: false,
                canRetry: true,
                canLeave: true,
              ),
            OnlineBattlePhase.failure => _buildFailure(context, state, l10n),
            OnlineBattlePhase.playing ||
            OnlineBattlePhase.finished =>
              _buildBattle(context, state, l10n),
          },
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_rounded, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    l10n.onlineIntroTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.onlineIntroBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<OnlineGameBloc>()
                        .add(const StartOnlineMatching()),
                    icon: const Icon(Icons.search_rounded),
                    label: Text(l10n.onlineFindOpponent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(
    BuildContext context,
    String message, {
    required bool canCancel,
    bool canRetry = false,
    bool canLeave = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message, textAlign: TextAlign.center),
            if (canRetry) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context
                    .read<OnlineGameBloc>()
                    .add(const RetryOnlineConnection()),
                child: Text(l10n.onlineRetry),
              ),
            ],
            if (canCancel || canLeave) ...[
              SizedBox(height: canRetry ? 8 : 24),
              OutlinedButton(
                onPressed: () => context.read<OnlineGameBloc>().add(
                      canCancel
                          ? const CancelOnlineMatching()
                          : const LeaveOnlineGame(),
                    ),
                child: Text(
                  canCancel ? l10n.onlineCancelSearch : l10n.onlineLeave,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFailure(
    BuildContext context,
    OnlineBattleState state,
    AppLocalizations l10n,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              _failureMessage(state.failure, l10n),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context
                  .read<OnlineGameBloc>()
                  .add(const RetryOnlineConnection()),
              child: Text(l10n.onlineRetry),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<OnlineGameBloc>().add(const LeaveOnlineGame()),
              child: Text(l10n.onlineLeave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattle(
    BuildContext context,
    OnlineBattleState state,
    AppLocalizations l10n,
  ) {
    final board = state.boardState;
    if (board == null || state.localColor == null) {
      return _buildFailure(
        context,
        state.copyWith(failure: OnlineBattleFailure.protocolFailure),
        l10n,
      );
    }
    final localSide = state.localColor == OnlinePieceColor.black
        ? l10n.blackSide
        : l10n.whiteSide;
    final lastMove = state.lastMove;
    final finished = state.phase == OnlineBattlePhase.finished;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(constraints.maxWidth - 32, 520.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  finished
                                      ? _resultTitle(state, l10n)
                                      : state.isLocalTurn
                                          ? l10n.onlineYourTurn
                                          : l10n.onlineOpponentTurn,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(l10n.onlineYourSide(localSide)),
                              ],
                            ),
                          ),
                          if (!finished && state.turnDeadlineEpochMs != null)
                            Text(
                              l10n.turnSecondsRemaining(
                                _secondsUntil(state.turnDeadlineEpochMs!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!state.opponentConnected) ...[
                    const SizedBox(height: 8),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        leading: const Icon(Icons.wifi_off_rounded),
                        title: Text(l10n.onlineOpponentDisconnected),
                        subtitle: state.opponentReconnectDeadlineEpochMs == null
                            ? null
                            : Text(
                                l10n.onlineReconnectSeconds(
                                  _secondsUntil(
                                    state.opponentReconnectDeadlineEpochMs!,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox.square(
                    dimension: boardSize,
                    child: AbsorbPointer(
                      absorbing: !state.canMove,
                      child: ThemedBoardWidget(
                        boardState: board,
                        selectedPiece: _selected,
                        validMoves: _validMoves,
                        lastMoveFrom: lastMove?.from,
                        lastMoveTo: lastMove?.to,
                        capturedPiecePosition:
                            lastMove?.capturedPieces.firstOrNull,
                        flipBoard: state.localColor == OnlinePieceColor.white,
                        onPositionTapped: (position) =>
                            _onPositionTapped(context, state, position),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.isMovePending) Text(l10n.onlineWaitingForServer),
                  if (state.lastMoveRejection != null)
                    Text(
                      l10n.onlineMoveRejected,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (finished) ...[
                    const SizedBox(height: 8),
                    Text(_endReason(state, l10n), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context
                        .read<OnlineGameBloc>()
                        .add(const LeaveOnlineGame()),
                    child: Text(l10n.onlineLeave),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPositionTapped(
    BuildContext context,
    OnlineBattleState state,
    Position position,
  ) {
    if (!state.canMove) return;
    final board = state.boardState!;
    final localPiece = state.localColor == OnlinePieceColor.black
        ? PieceType.black
        : PieceType.white;
    if (board.getPiece(position) == localPiece) {
      setState(() {
        _selected = position;
        _validMoves = _adjacentEmptyPositions(board, position);
      });
      return;
    }
    final selected = _selected;
    if (selected != null && _validMoves.contains(position)) {
      context.read<OnlineGameBloc>().add(
            SubmitOnlineMove(from: selected, to: position),
          );
    }
    _clearSelection();
  }

  List<Position> _adjacentEmptyPositions(BoardState board, Position from) {
    const offsets = [
      Position(0, -1),
      Position(1, 0),
      Position(0, 1),
      Position(-1, 0),
    ];
    return offsets
        .map((offset) => Position(from.x + offset.x, from.y + offset.y))
        .where((position) => position.isValid() && board.isEmpty(position))
        .toList(growable: false);
  }

  void _clearSelection() {
    if (_selected == null && _validMoves.isEmpty) return;
    setState(() {
      _selected = null;
      _validMoves = const [];
    });
  }

  int _secondsUntil(int epochMs) {
    final remainingMs = epochMs - widget.now().millisecondsSinceEpoch;
    return remainingMs <= 0 ? 0 : (remainingMs + 999) ~/ 1000;
  }

  String _resultTitle(OnlineBattleState state, AppLocalizations l10n) {
    final winner = state.authoritativeState?.winner;
    if (winner == OnlineGameWinner.draw) return l10n.onlineGameDraw;
    final localWon = (winner == OnlineGameWinner.black &&
            state.localColor == OnlinePieceColor.black) ||
        (winner == OnlineGameWinner.white &&
            state.localColor == OnlinePieceColor.white);
    return localWon ? l10n.onlineYouWin : l10n.onlineYouLose;
  }

  String _endReason(OnlineBattleState state, AppLocalizations l10n) {
    final game = state.authoritativeState;
    final blackWon = game?.winner == OnlineGameWinner.black;
    return switch (game?.endReason) {
      OnlineGameEndReason.pieceCount => blackWon
          ? l10n.endReasonPieceCountBlack
          : l10n.endReasonPieceCountWhite,
      OnlineGameEndReason.noLegalMoves => blackWon
          ? l10n.endReasonNoLegalMovesBlack
          : l10n.endReasonNoLegalMovesWhite,
      OnlineGameEndReason.noCaptureLimit => l10n.endReasonNoCaptureLimit,
      OnlineGameEndReason.timeout =>
        blackWon ? l10n.endReasonTimeoutBlack : l10n.endReasonTimeoutWhite,
      OnlineGameEndReason.disconnect => blackWon
          ? l10n.endReasonDisconnectBlack
          : l10n.endReasonDisconnectWhite,
      OnlineGameEndReason.abandoned =>
        blackWon ? l10n.endReasonAbandonedBlack : l10n.endReasonAbandonedWhite,
      null => l10n.endReasonUnknown,
    };
  }

  String _failureMessage(
    OnlineBattleFailure? failure,
    AppLocalizations l10n,
  ) {
    return switch (failure) {
      OnlineBattleFailure.connectionFailed => l10n.onlineFailureConnection,
      OnlineBattleFailure.identityUnavailable => l10n.onlineFailureIdentity,
      OnlineBattleFailure.requestFailed => l10n.onlineFailureRequest,
      OnlineBattleFailure.matchRejected => l10n.onlineFailureMatch,
      OnlineBattleFailure.resumeNotFound => l10n.onlineFailureResume,
      OnlineBattleFailure.snapshotRejected => l10n.onlineFailureSnapshot,
      OnlineBattleFailure.protocolFailure || null => l10n.onlineFailureProtocol,
    };
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
