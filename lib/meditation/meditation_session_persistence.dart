import 'dart:convert';

import 'package:hive/hive.dart';

import 'meditation_session.dart';
import 'meditation_session_controller.dart';
import 'meditation_session_snapshot.dart';

/// Replaceable persistence boundary for meditation sessions.
abstract interface class MeditationSessionRepository {
  Future<void> save(MeditationSessionSnapshot snapshot);

  Future<MeditationSessionSnapshot?> load();

  Future<void> delete({String? matchId});
}

/// Device repository isolated from the generic visual-game save slot.
final class HiveMeditationSessionRepository
    implements MeditationSessionRepository {
  static const String boxName = 'meditation_session';
  static const String storageKey = 'current_meditation_session_v1';

  static final Expando<_MeditationWriteQueue> _writeQueues =
      Expando<_MeditationWriteQueue>();

  final Box<dynamic> _box;

  HiveMeditationSessionRepository(this._box);

  @override
  Future<void> save(MeditationSessionSnapshot snapshot) {
    return _serializeWrite(() async {
      final encoded = jsonEncode(snapshot.toJson());
      final current = await load();
      if (current != null) {
        final currentSession = current.session;
        final nextSession = snapshot.session;
        if (currentSession.matchId != nextSession.matchId) {
          throw StateError(
            'A different meditation session already owns the save slot',
          );
        }
        if (nextSession.revision < currentSession.revision) {
          throw StateError('A stale meditation revision cannot be saved');
        }
        if (nextSession.revision == currentSession.revision) {
          final currentJson = current.toJson();
          final nextJson = snapshot.toJson();
          if (jsonEncode(currentJson) == encoded) {
            return;
          }
          final currentRemaining = currentJson['remainingMilliseconds'] as int?;
          final nextRemaining = nextJson['remainingMilliseconds'] as int?;
          currentJson.remove('remainingMilliseconds');
          nextJson.remove('remainingMilliseconds');
          final sameAuthorityState =
              jsonEncode(currentJson) == jsonEncode(nextJson);
          final activeClockAdvanced = currentJson['clockState'] == 'active' &&
              currentRemaining != null &&
              nextRemaining != null &&
              nextRemaining < currentRemaining;
          if (!sameAuthorityState || !activeClockAdvanced) {
            throw StateError(
              'Conflicting meditation snapshots share a revision',
            );
          }
        }
      }
      await _box.put(storageKey, encoded);
    });
  }

  @override
  Future<MeditationSessionSnapshot?> load() async {
    final encoded = _box.get(storageKey);
    if (encoded == null) {
      return null;
    }
    if (encoded is! String) {
      throw const FormatException('Meditation snapshot must be JSON text');
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Meditation snapshot must be an object');
    }
    return MeditationSessionSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> delete({String? matchId}) {
    return _serializeWrite(() async {
      if (matchId != null) {
        final current = await load();
        if (current == null || current.session.matchId != matchId) {
          return;
        }
      }
      await _box.delete(storageKey);
    });
  }

  Future<void> _serializeWrite(Future<void> Function() operation) {
    final queue = _writeQueues[_box] ??= _MeditationWriteQueue();
    final result = queue.tail.then((_) => operation());
    queue.tail = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }
}

/// Shared within one isolate so two adapters around the same box cannot race.
final class _MeditationWriteQueue {
  Future<void> tail = Future<void>.value();
}

/// Coordinates capture and strict authority restoration without owning UI.
final class MeditationSessionPersistence {
  final MeditationSessionRepository _repository;
  final DateTime Function() _now;

  MeditationSessionPersistence({
    required MeditationSessionRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  Future<void> save(MeditationSession session) {
    return _repository.save(
      MeditationSessionSnapshot.capture(session, now: _now()),
    );
  }

  Future<MeditationSessionController?> restoreController() async {
    final snapshot = await _repository.load();
    return snapshot?.restoreController(now: _now);
  }

  Future<void> clear({String? matchId}) => _repository.delete(matchId: matchId);
}
