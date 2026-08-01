import 'package:equatable/equatable.dart';

import '../models/board_state.dart';
import '../models/online_protocol.dart' as protocol;
import '../models/piece_type.dart';
import '../models/position.dart';

enum OnlineBattlePhase {
  idle,
  connecting,
  matching,
  playing,
  recovering,
  finished,
  failure,
}

enum OnlineBattleFailure {
  connectionFailed,
  identityUnavailable,
  requestFailed,
  matchRejected,
  resumeNotFound,
  snapshotRejected,
  protocolFailure,
}

class OnlineBattleState extends Equatable {
  final OnlineBattlePhase phase;
  final protocol.OnlineGameState? authoritativeState;
  final protocol.OnlinePieceColor? localColor;
  final int? turnDeadlineEpochMs;
  final bool opponentConnected;
  final int? opponentReconnectDeadlineEpochMs;
  final bool isSynchronized;
  final bool isMovePending;
  final protocol.OnlineMoveRejectionReason? lastMoveRejection;
  final OnlineBattleFailure? failure;

  const OnlineBattleState({
    this.phase = OnlineBattlePhase.idle,
    this.authoritativeState,
    this.localColor,
    this.turnDeadlineEpochMs,
    this.opponentConnected = true,
    this.opponentReconnectDeadlineEpochMs,
    this.isSynchronized = true,
    this.isMovePending = false,
    this.lastMoveRejection,
    this.failure,
  });

  bool get hasBattle => authoritativeState != null && localColor != null;

  bool get isLocalTurn =>
      authoritativeState?.status == protocol.OnlineGameStatus.playing &&
      authoritativeState?.currentTurn == localColor;

  bool get canMove =>
      phase == OnlineBattlePhase.playing &&
      isSynchronized &&
      !isMovePending &&
      isLocalTurn;

  BoardState? get boardState {
    final state = authoritativeState;
    if (state == null) return null;
    final grid = <List<PieceType>>[];
    final blackPieces = <Position>[];
    final whitePieces = <Position>[];
    for (var y = 0; y < state.board.length; y += 1) {
      final row = <PieceType>[];
      for (var x = 0; x < state.board[y].length; x += 1) {
        final piece = switch (state.board[y][x]) {
          protocol.OnlinePieceColor.black => PieceType.black,
          protocol.OnlinePieceColor.white => PieceType.white,
          null => PieceType.empty,
        };
        row.add(piece);
        if (piece == PieceType.black) blackPieces.add(Position(x, y));
        if (piece == PieceType.white) whitePieces.add(Position(x, y));
      }
      grid.add(row);
    }
    return BoardState(
      grid: grid,
      blackPieces: blackPieces,
      whitePieces: whitePieces,
      currentPlayer:
          authoritativeState!.currentTurn == protocol.OnlinePieceColor.black
              ? PieceType.black
              : PieceType.white,
    );
  }

  List<protocol.OnlineRecordedMove> get moveHistory =>
      authoritativeState?.moveHistory ?? const [];

  protocol.OnlineRecordedMove? get lastMove =>
      moveHistory.isEmpty ? null : moveHistory.last;

  OnlineBattleState copyWith({
    OnlineBattlePhase? phase,
    Object? authoritativeState = _unset,
    Object? localColor = _unset,
    Object? turnDeadlineEpochMs = _unset,
    bool? opponentConnected,
    Object? opponentReconnectDeadlineEpochMs = _unset,
    bool? isSynchronized,
    bool? isMovePending,
    Object? lastMoveRejection = _unset,
    Object? failure = _unset,
  }) {
    return OnlineBattleState(
      phase: phase ?? this.phase,
      authoritativeState: identical(authoritativeState, _unset)
          ? this.authoritativeState
          : authoritativeState as protocol.OnlineGameState?,
      localColor: identical(localColor, _unset)
          ? this.localColor
          : localColor as protocol.OnlinePieceColor?,
      turnDeadlineEpochMs: identical(turnDeadlineEpochMs, _unset)
          ? this.turnDeadlineEpochMs
          : turnDeadlineEpochMs as int?,
      opponentConnected: opponentConnected ?? this.opponentConnected,
      opponentReconnectDeadlineEpochMs:
          identical(opponentReconnectDeadlineEpochMs, _unset)
              ? this.opponentReconnectDeadlineEpochMs
              : opponentReconnectDeadlineEpochMs as int?,
      isSynchronized: isSynchronized ?? this.isSynchronized,
      isMovePending: isMovePending ?? this.isMovePending,
      lastMoveRejection: identical(lastMoveRejection, _unset)
          ? this.lastMoveRejection
          : lastMoveRejection as protocol.OnlineMoveRejectionReason?,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as OnlineBattleFailure?,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        authoritativeState,
        localColor,
        turnDeadlineEpochMs,
        opponentConnected,
        opponentReconnectDeadlineEpochMs,
        isSynchronized,
        isMovePending,
        lastMoveRejection,
        failure,
      ];

  @override
  String toString() => 'OnlineBattleState('
      'phase: ${phase.name}, '
      'revision: ${authoritativeState?.revision}, '
      'synchronized: $isSynchronized, '
      'pending: $isMovePending)';
}

const Object _unset = Object();
