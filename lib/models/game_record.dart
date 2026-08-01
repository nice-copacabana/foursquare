import 'package:equatable/equatable.dart';

import 'game_result.dart';
import 'move.dart';
import 'piece_type.dart';

/// Immutable completed-match archive used by statistics and replay.
class GameRecord extends Equatable {
  const GameRecord({
    required this.id,
    required this.completedAt,
    required this.mode,
    required this.startingPlayer,
    required this.result,
    required this.moves,
    this.difficulty,
    this.humanPlayer,
  });

  static const int historyLimit = 20;

  final String id;
  final DateTime completedAt;
  final String mode;
  final String? difficulty;
  final PieceType startingPlayer;
  final PieceType? humanPlayer;
  final GameResult result;
  final List<Move> moves;

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'id': id,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'mode': mode,
        'difficulty': difficulty,
        'startingPlayer': startingPlayer.name,
        'humanPlayer': humanPlayer?.name,
        'result': result.toJson(),
        'moves': moves.map((move) => move.toJson()).toList(growable: false),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    final rawMoves = json['moves'];
    if (rawMoves is! List) {
      throw const FormatException('Game record moves must be a list.');
    }
    return GameRecord(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String).toUtc(),
      mode: json['mode'] as String,
      difficulty: json['difficulty'] as String?,
      startingPlayer: PieceType.values.byName(json['startingPlayer'] as String),
      humanPlayer: json['humanPlayer'] == null
          ? null
          : PieceType.values.byName(json['humanPlayer'] as String),
      result: GameResult.fromJson(
        Map<String, dynamic>.from(json['result'] as Map),
      ),
      moves: rawMoves
          .map(
            (move) => Move.fromJson(Map<String, dynamic>.from(move as Map)),
          )
          .toList(growable: false),
    );
  }

  static List<GameRecord> retainRecent(
    Iterable<GameRecord> records, {
    int limit = historyLimit,
  }) {
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'Must not be negative.');
    }
    final sorted = records.toList(growable: false)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final seen = <String>{};
    final retained = <GameRecord>[];
    for (final record in sorted) {
      if (!seen.add(record.id)) continue;
      retained.add(record);
      if (retained.length == limit) break;
    }
    return List.unmodifiable(retained);
  }

  @override
  List<Object?> get props => [
        id,
        completedAt,
        mode,
        difficulty,
        startingPlayer,
        humanPlayer,
        result,
        moves,
      ];
}
