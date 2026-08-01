import 'package:equatable/equatable.dart';

import '../ai/ai_player.dart';
import '../models/board_state.dart';
import '../models/game_result.dart';
import '../models/move.dart';
import '../models/piece_type.dart';
import '../models/position.dart';
import '../services/turn_clock.dart';

enum MeditationSessionPhase {
  opening,
  humanTurn,
  aiTurn,
  paused,
  completed,
}

/// Complete, immutable authority state for one meditation game.
final class MeditationSession extends Equatable {
  final String matchId;
  final DateTime startedAt;
  final BoardState boardState;
  final PieceType firstPlayer;
  final PieceType humanPlayer;
  final AIDifficulty aiDifficulty;
  final List<Move> moveHistory;
  final int noCapturePlyCount;
  final TurnClock? turnClock;
  final Position? selectedPosition;
  final List<Position> validMoves;
  final GameResult? gameResult;
  final int revision;

  MeditationSession({
    required this.matchId,
    required DateTime startedAt,
    required this.boardState,
    required this.firstPlayer,
    required this.humanPlayer,
    required this.aiDifficulty,
    List<Move> moveHistory = const [],
    this.noCapturePlyCount = 0,
    required this.turnClock,
    this.selectedPosition,
    List<Position> validMoves = const [],
    this.gameResult,
    this.revision = 0,
  })  : startedAt = startedAt.toUtc(),
        moveHistory = List.unmodifiable(moveHistory),
        validMoves = List.unmodifiable(validMoves) {
    if (!firstPlayer.isPlayer() || !humanPlayer.isPlayer()) {
      throw ArgumentError('Meditation players cannot be empty');
    }
    if (noCapturePlyCount < 0 || revision < 0) {
      throw ArgumentError('Session counters cannot be negative');
    }
    if (gameResult != null && turnClock != null) {
      throw ArgumentError(
        'A terminal meditation session cannot keep an active clock',
      );
    }
    if (gameResult == null && turnClock == null) {
      if (moveHistory.isNotEmpty ||
          selectedPosition != null ||
          validMoves.isNotEmpty ||
          boardState.currentPlayer != firstPlayer) {
        throw ArgumentError('Opening meditation session must be pristine');
      }
    }
    if (gameResult != null &&
        (selectedPosition != null || validMoves.isNotEmpty)) {
      throw ArgumentError('Completed meditation session cannot keep selection');
    }
    if (selectedPosition == null && validMoves.isNotEmpty) {
      throw ArgumentError('Valid moves require a selected position');
    }
    if (boardState.currentPlayer != humanPlayer && selectedPosition != null) {
      throw ArgumentError('AI turn cannot keep a human selection');
    }
  }

  PieceType get currentPlayer => boardState.currentPlayer;

  PieceType get aiPlayer => humanPlayer.getOpponent();

  Move? get lastMove => moveHistory.isEmpty ? null : moveHistory.last;

  MeditationSessionPhase get phase {
    if (gameResult != null) {
      return MeditationSessionPhase.completed;
    }
    if (turnClock == null) {
      return MeditationSessionPhase.opening;
    }
    if (turnClock?.isPaused ?? false) {
      return MeditationSessionPhase.paused;
    }
    return currentPlayer == humanPlayer
        ? MeditationSessionPhase.humanTurn
        : MeditationSessionPhase.aiTurn;
  }

  MeditationSession copyWith({
    BoardState? boardState,
    List<Move>? moveHistory,
    int? noCapturePlyCount,
    TurnClock? turnClock,
    bool clearTurnClock = false,
    Position? selectedPosition,
    List<Position>? validMoves,
    bool clearSelection = false,
    GameResult? gameResult,
    int? revision,
  }) {
    return MeditationSession(
      matchId: matchId,
      startedAt: startedAt,
      boardState: boardState ?? this.boardState,
      firstPlayer: firstPlayer,
      humanPlayer: humanPlayer,
      aiDifficulty: aiDifficulty,
      moveHistory: moveHistory ?? this.moveHistory,
      noCapturePlyCount: noCapturePlyCount ?? this.noCapturePlyCount,
      turnClock: clearTurnClock ? null : (turnClock ?? this.turnClock),
      selectedPosition:
          clearSelection ? null : (selectedPosition ?? this.selectedPosition),
      validMoves: clearSelection ? const [] : (validMoves ?? this.validMoves),
      gameResult: gameResult ?? this.gameResult,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
        matchId,
        startedAt,
        boardState,
        firstPlayer,
        humanPlayer,
        aiDifficulty,
        moveHistory,
        noCapturePlyCount,
        turnClock,
        selectedPosition,
        validMoves,
        gameResult,
        revision,
      ];

  @override
  String toString() =>
      'MeditationSession(matchId: $matchId, phase: ${phase.name}, '
      'revision: $revision, moves: ${moveHistory.length})';
}
