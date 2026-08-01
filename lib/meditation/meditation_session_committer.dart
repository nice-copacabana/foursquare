import '../models/game_record.dart';
import 'meditation_session.dart';
import 'meditation_session_persistence.dart';

typedef MeditationGameArchiver = Future<bool> Function(GameRecord record);

/// Persists every committed authority state and closes terminal sessions.
final class MeditationSessionCommitter {
  final MeditationSessionPersistence _persistence;
  final MeditationGameArchiver _archiveCompletedGame;

  const MeditationSessionCommitter({
    required MeditationSessionPersistence persistence,
    required MeditationGameArchiver archiveCompletedGame,
  })  : _persistence = persistence,
        _archiveCompletedGame = archiveCompletedGame;

  Future<void> commit(MeditationSession session) async {
    await _persistence.save(session);
    final result = session.gameResult;
    if (result == null) {
      return;
    }

    final recorded = await _archiveCompletedGame(
      GameRecord(
        id: session.matchId,
        completedAt: session.startedAt.add(result.duration),
        mode: 'meditation',
        difficulty: session.aiDifficulty.name,
        startingPlayer: session.firstPlayer,
        humanPlayer: session.humanPlayer,
        result: result,
        moves: session.moveHistory,
      ),
    );
    if (!recorded) {
      throw StateError('Completed meditation game could not be archived');
    }
    await _persistence.clear(matchId: session.matchId);
  }
}
