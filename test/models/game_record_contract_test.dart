import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/game_record.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';

void main() {
  test('完成对局记录往返保留先手、执色、终局原因和完整双吃历史', () {
    final completedAt = DateTime.utc(2026, 8, 1, 12, 3);
    final record = GameRecord(
      id: 'match-1',
      completedAt: completedAt,
      mode: 'pve',
      difficulty: 'hard',
      startingPlayer: PieceType.white,
      humanPlayer: PieceType.black,
      result: GameResult.blackWin(
        reason: '白方无合法移动',
        endReason: GameEndReason.noLegalMoves,
        moveCount: 1,
        duration: const Duration(minutes: 3),
      ),
      moves: [
        Move(
          from: const Position(1, 0),
          to: const Position(1, 1),
          player: PieceType.black,
          capturedPieces: const [Position(0, 1), Position(2, 1)],
          timestamp: completedAt,
        ),
      ],
    );

    final restored = GameRecord.fromJson(record.toJson());

    expect(restored, record);
    expect(restored.moves.single.captureCount, 2);
    expect(restored.result.endReason, GameEndReason.noLegalMoves);
  });

  test('历史只保留按完成时间倒序的最近20局并按id去重', () {
    final records = List.generate(
      22,
      (index) => GameRecord(
        id: index == 21 ? 'match-20' : 'match-$index',
        completedAt: DateTime.utc(2026, 8, 1).add(Duration(minutes: index)),
        mode: 'pvp',
        startingPlayer: PieceType.black,
        result: GameResult.draw(
          reason: '连续50回合未吃子',
          moveCount: 50,
          duration: const Duration(minutes: 5),
        ),
        moves: const [],
      ),
    );

    final retained = GameRecord.retainRecent(records);

    expect(retained, hasLength(20));
    expect(retained.first.id, 'match-20');
    expect(retained.map((record) => record.id).toSet(), hasLength(20));
    expect(retained.last.id, 'match-1');
  });
}
