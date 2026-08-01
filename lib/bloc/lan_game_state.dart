import 'package:equatable/equatable.dart';
import '../../models/board_state.dart';
import '../../models/game_result.dart';
import '../../models/lan_protocol.dart';
import '../../models/move.dart';
import '../../models/piece_type.dart';

abstract class LanGameState extends Equatable {
  const LanGameState();

  @override
  List<Object?> get props => [];
}

class LanGameInitial extends LanGameState {
  const LanGameInitial();
}

class LanGamePlaying extends LanGameState {
  final BoardState boardState;
  final PieceType localColor; // Host is Black, Client is White
  final List<Move> moveHistory;
  final Move? lastMove;
  final DateTime lastUpdate;
  final String? gameId;
  final int revision;
  final PieceType startingPlayer;
  final int noCapturePlyCount;
  final DateTime? turnDeadlineUtc;
  final DateTime? disconnectDeadlineUtc;
  final bool isSynchronized;
  final bool isReconnecting;
  final String? pendingCommandId;
  final LanMoveRejectionReason? lastRejection;
  final String? stateHash;

  const LanGamePlaying({
    required this.boardState,
    required this.localColor,
    this.moveHistory = const [],
    this.lastMove,
    required this.lastUpdate,
    this.gameId,
    this.revision = 0,
    this.startingPlayer = PieceType.black,
    this.noCapturePlyCount = 0,
    this.turnDeadlineUtc,
    this.disconnectDeadlineUtc,
    this.isSynchronized = true,
    this.isReconnecting = false,
    this.pendingCommandId,
    this.lastRejection,
    this.stateHash,
  });

  bool get isLocalTurn =>
      isSynchronized &&
      !isReconnecting &&
      pendingCommandId == null &&
      boardState.currentPlayer == localColor;

  LanGamePlaying copyWith({
    BoardState? boardState,
    List<Move>? moveHistory,
    Move? lastMove,
    bool clearLastMove = false,
    String? gameId,
    int? revision,
    PieceType? startingPlayer,
    int? noCapturePlyCount,
    DateTime? turnDeadlineUtc,
    bool clearTurnDeadline = false,
    DateTime? disconnectDeadlineUtc,
    bool clearDisconnectDeadline = false,
    bool? isSynchronized,
    bool? isReconnecting,
    String? pendingCommandId,
    bool clearPendingCommand = false,
    LanMoveRejectionReason? lastRejection,
    bool clearLastRejection = false,
    String? stateHash,
    DateTime? lastUpdate,
  }) {
    return LanGamePlaying(
      boardState: boardState ?? this.boardState,
      localColor: localColor,
      moveHistory: moveHistory ?? this.moveHistory,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      lastUpdate: lastUpdate ?? DateTime.now(),
      gameId: gameId ?? this.gameId,
      revision: revision ?? this.revision,
      startingPlayer: startingPlayer ?? this.startingPlayer,
      noCapturePlyCount: noCapturePlyCount ?? this.noCapturePlyCount,
      turnDeadlineUtc:
          clearTurnDeadline ? null : (turnDeadlineUtc ?? this.turnDeadlineUtc),
      disconnectDeadlineUtc: clearDisconnectDeadline
          ? null
          : (disconnectDeadlineUtc ?? this.disconnectDeadlineUtc),
      isSynchronized: isSynchronized ?? this.isSynchronized,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      pendingCommandId: clearPendingCommand
          ? null
          : (pendingCommandId ?? this.pendingCommandId),
      lastRejection:
          clearLastRejection ? null : (lastRejection ?? this.lastRejection),
      stateHash: stateHash ?? this.stateHash,
    );
  }

  @override
  List<Object?> get props => [
        boardState,
        localColor,
        moveHistory,
        lastMove,
        lastUpdate,
        gameId,
        revision,
        startingPlayer,
        noCapturePlyCount,
        turnDeadlineUtc,
        disconnectDeadlineUtc,
        isSynchronized,
        isReconnecting,
        pendingCommandId,
        lastRejection,
        stateHash,
      ];
}

class LanGameFinished extends LanGameState {
  final BoardState finalBoard;
  final PieceType? winner;
  final String reason;
  final bool isWin; // relative to local player
  final PieceType localColor;
  final List<Move> moveHistory;
  final String? gameId;
  final int revision;
  final PieceType startingPlayer;
  final int noCapturePlyCount;
  final GameResult? authoritativeResult;
  final String? stateHash;

  const LanGameFinished({
    required this.finalBoard,
    this.winner,
    required this.reason,
    required this.isWin,
    required this.localColor,
    this.moveHistory = const [],
    this.gameId,
    this.revision = 0,
    this.startingPlayer = PieceType.black,
    this.noCapturePlyCount = 0,
    this.authoritativeResult,
    this.stateHash,
  });

  @override
  List<Object?> get props => [
        finalBoard,
        winner,
        reason,
        isWin,
        localColor,
        moveHistory,
        gameId,
        revision,
        startingPlayer,
        noCapturePlyCount,
        authoritativeResult,
        stateHash,
      ];
}

class LanGameError extends LanGameState {
  final String message;
  const LanGameError(this.message);

  @override
  List<Object?> get props => [message];
}

class LanOpponentLeft extends LanGameState {}
