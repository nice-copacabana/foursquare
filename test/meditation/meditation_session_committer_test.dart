import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/meditation/meditation_session_committer.dart';
import 'package:foursquare/meditation/meditation_session_controller.dart';
import 'package:foursquare/meditation/meditation_session_persistence.dart';
import 'package:foursquare/meditation/meditation_session_snapshot.dart';
import 'package:foursquare/models/game_record.dart';
import 'package:foursquare/models/piece_type.dart';

void main() {
  final now = DateTime.utc(2026, 8, 1, 12);

  test('进行中修订落盘，终局归档成功后按对局删除存档', () async {
    final repository = _MemoryRepository();
    final persistence = MeditationSessionPersistence(
      repository: repository,
      now: () => now,
    );
    final archived = <GameRecord>[];
    final committer = MeditationSessionCommitter(
      persistence: persistence,
      archiveCompletedGame: (record) async {
        archived.add(record);
        return true;
      },
    );
    final controller = MeditationSessionController.newGame(
      humanPlayer: PieceType.black,
      firstPlayer: PieceType.black,
      now: () => now,
    )..completeOpening();

    await committer.commit(controller.session);
    expect(repository.value?.session, controller.session);

    controller.abandon();
    await committer.commit(controller.session);

    expect(repository.value, isNull);
    expect(archived, hasLength(1));
    expect(archived.single.id, controller.session.matchId);
    expect(archived.single.mode, 'meditation');
    expect(archived.single.humanPlayer, PieceType.black);
    expect(archived.single.startingPlayer, PieceType.black);
    expect(archived.single.difficulty, 'medium');
    expect(archived.single.result, controller.session.gameResult);
  });

  test('终局归档失败时保留已完成存档以便重试', () async {
    final repository = _MemoryRepository();
    final persistence = MeditationSessionPersistence(
      repository: repository,
      now: () => now,
    );
    final committer = MeditationSessionCommitter(
      persistence: persistence,
      archiveCompletedGame: (_) async => false,
    );
    final controller = MeditationSessionController.newGame(
      humanPlayer: PieceType.black,
      firstPlayer: PieceType.black,
      now: () => now,
    )
      ..completeOpening()
      ..abandon();

    await expectLater(
      committer.commit(controller.session),
      throwsStateError,
    );

    expect(repository.value?.session.gameResult, isNotNull);
    expect(repository.value?.session.matchId, controller.session.matchId);
  });
}

final class _MemoryRepository implements MeditationSessionRepository {
  MeditationSessionSnapshot? value;

  @override
  Future<void> delete({String? matchId}) async {
    if (matchId == null || value?.session.matchId == matchId) {
      value = null;
    }
  }

  @override
  Future<MeditationSessionSnapshot?> load() async => value;

  @override
  Future<void> save(MeditationSessionSnapshot snapshot) async {
    value = MeditationSessionSnapshot.fromJson(snapshot.toJson());
  }
}
