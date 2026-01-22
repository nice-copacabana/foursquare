import 'package:equatable/equatable.dart';
import '../../models/board_state.dart';
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

  const LanGamePlaying({
    required this.boardState,
    required this.localColor,
    this.moveHistory = const [],
    this.lastMove,
    required this.lastUpdate,
  });

  bool get isLocalTurn => boardState.currentPlayer == localColor;

  LanGamePlaying copyWith({
    BoardState? boardState,
    List<Move>? moveHistory,
    Move? lastMove,
  }) {
    return LanGamePlaying(
      boardState: boardState ?? this.boardState,
      localColor: localColor,
      moveHistory: moveHistory ?? this.moveHistory,
      lastMove: lastMove ?? this.lastMove,
      lastUpdate: DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [boardState, localColor, moveHistory, lastMove, lastUpdate];
}

class LanGameFinished extends LanGameState {
  final BoardState finalBoard;
  final PieceType? winner;
  final String reason;
  final bool isWin; // relative to local player
  final PieceType localColor;
  final List<Move> moveHistory;

  const LanGameFinished({
    required this.finalBoard,
    this.winner,
    required this.reason,
    required this.isWin,
    required this.localColor,
    this.moveHistory = const [],
  });

  @override
  List<Object?> get props =>
      [finalBoard, winner, reason, isWin, localColor, moveHistory];
}

class LanGameError extends LanGameState {
  final String message;
  const LanGameError(this.message);

  @override
  List<Object?> get props => [message];
}

class LanOpponentLeft extends LanGameState {}
