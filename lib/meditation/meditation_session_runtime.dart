import 'dart:async';

import '../ai/ai_player.dart';
import '../ai/voice_game_intent.dart';
import '../models/piece_type.dart';
import 'meditation_intent_handler.dart';
import 'meditation_session.dart';
import 'meditation_session_committer.dart';
import 'meditation_session_controller.dart';
import 'meditation_session_persistence.dart';

abstract interface class MeditationDeadlineTimerHandle {
  void cancel();
}

typedef MeditationDeadlineTimerFactory = MeditationDeadlineTimerHandle Function(
  Duration delay,
  Future<void> Function() callback,
);

typedef MeditationBackgroundErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Fully wired, screen-independent runtime for one meditation game.
final class MeditationSessionRuntime {
  final MeditationSessionController _controller;
  final MeditationIntentHandler _handler;
  final MeditationSessionCommitter _committer;
  final MeditationDeadlineTimerFactory _timerFactory;
  final DateTime Function() _now;
  final MeditationBackgroundErrorHandler? _onBackgroundError;
  MeditationDeadlineTimerHandle? _deadlineTimer;
  Future<MeditationActionResult>? _settleFlight;
  Object? _backgroundError;
  bool _disposed = false;

  MeditationSessionRuntime._({
    required MeditationSessionController controller,
    required MeditationIntentHandler handler,
    required MeditationSessionCommitter committer,
    required MeditationDeadlineTimerFactory timerFactory,
    required DateTime Function() now,
    required MeditationBackgroundErrorHandler? onBackgroundError,
  })  : _controller = controller,
        _handler = handler,
        _committer = committer,
        _timerFactory = timerFactory,
        _now = now,
        _onBackgroundError = onBackgroundError;

  static Future<MeditationSessionRuntime> createNew({
    required PieceType humanPlayer,
    required PieceType firstPlayer,
    required AIPlayer aiPlayer,
    required MeditationSessionPersistence persistence,
    required MeditationGameArchiver archiveCompletedGame,
    DateTime Function()? now,
    MeditationDeadlineTimerFactory timerFactory = _createDeadlineTimer,
    MeditationBackgroundErrorHandler? onBackgroundError,
  }) async {
    final currentTime = now ?? DateTime.now;
    final controller = MeditationSessionController.newGame(
      humanPlayer: humanPlayer,
      firstPlayer: firstPlayer,
      aiDifficulty: aiPlayer.difficulty,
      now: currentTime,
    );
    return _attach(
      controller: controller,
      aiPlayer: aiPlayer,
      persistence: persistence,
      archiveCompletedGame: archiveCompletedGame,
      timerFactory: timerFactory,
      now: currentTime,
      onBackgroundError: onBackgroundError,
    );
  }

  static Future<MeditationSessionRuntime?> restore({
    required AIPlayer aiPlayer,
    required MeditationSessionPersistence persistence,
    required MeditationGameArchiver archiveCompletedGame,
    DateTime Function()? now,
    MeditationDeadlineTimerFactory timerFactory = _createDeadlineTimer,
    MeditationBackgroundErrorHandler? onBackgroundError,
  }) async {
    final controller = await persistence.restoreController();
    if (controller == null) {
      return null;
    }
    if (controller.session.aiDifficulty != aiPlayer.difficulty) {
      throw StateError(
        'Restored meditation AI difficulty does not match the player',
      );
    }
    return _attach(
      controller: controller,
      aiPlayer: aiPlayer,
      persistence: persistence,
      archiveCompletedGame: archiveCompletedGame,
      timerFactory: timerFactory,
      now: now ?? DateTime.now,
      onBackgroundError: onBackgroundError,
    );
  }

  static Future<MeditationSessionRuntime> _attach({
    required MeditationSessionController controller,
    required AIPlayer aiPlayer,
    required MeditationSessionPersistence persistence,
    required MeditationGameArchiver archiveCompletedGame,
    required MeditationDeadlineTimerFactory timerFactory,
    required DateTime Function() now,
    required MeditationBackgroundErrorHandler? onBackgroundError,
  }) async {
    final committer = MeditationSessionCommitter(
      persistence: persistence,
      archiveCompletedGame: archiveCompletedGame,
    );
    await committer.commit(controller.session);
    late MeditationSessionRuntime runtime;
    final handler = MeditationIntentHandler(
      controller: controller,
      aiPlayer: aiPlayer,
      onSessionChanged: (session) => runtime._commit(session),
      initialCommittedRevision: controller.session.revision,
    );
    runtime = MeditationSessionRuntime._(
      controller: controller,
      handler: handler,
      committer: committer,
      timerFactory: timerFactory,
      now: now,
      onBackgroundError: onBackgroundError,
    );
    runtime._scheduleDeadline();
    return runtime;
  }

  MeditationSession get session => _controller.session;

  Object? get backgroundError => _backgroundError;

  MeditationPrompt openingPrompt() {
    _ensureActive();
    return _handler.openingPrompt();
  }

  Future<MeditationTurnResponse> start() async {
    _ensureActive();
    return _handler.start();
  }

  Future<MeditationTurnResponse> handle(VoiceGameIntent intent) async {
    _ensureActive();
    return _handler.handle(intent);
  }

  Future<MeditationActionResult> settle() {
    _ensureActive();
    final pending = _settleFlight;
    if (pending != null) {
      return pending;
    }
    final future = _handler.settle();
    _settleFlight = future;
    return future.whenComplete(() {
      if (identical(_settleFlight, future)) {
        _settleFlight = null;
      }
      _scheduleDeadline();
    });
  }

  void dispose() {
    _disposed = true;
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
  }

  Future<void> _commit(MeditationSession session) async {
    if (_disposed) {
      return;
    }
    await _committer.commit(session);
    if (!_disposed) {
      _backgroundError = null;
    }
    _scheduleDeadline();
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('Meditation session runtime has been disposed');
    }
  }

  void _scheduleDeadline() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
    if (_disposed) {
      return;
    }
    final clock = _controller.session.turnClock;
    final deadline = clock?.deadlineUtc;
    if (deadline == null) {
      return;
    }
    final remaining = deadline.difference(_now().toUtc());
    _deadlineTimer = _timerFactory(
      remaining.isNegative ? Duration.zero : remaining,
      _handleDeadline,
    );
  }

  Future<void> _handleDeadline() async {
    if (_disposed) {
      return;
    }
    try {
      await settle();
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      _backgroundError = error;
      _onBackgroundError?.call(error, stackTrace);
    }
  }
}

MeditationDeadlineTimerHandle _createDeadlineTimer(
  Duration delay,
  Future<void> Function() callback,
) =>
    _DartDeadlineTimerHandle(Timer(delay, () => unawaited(callback())));

final class _DartDeadlineTimerHandle implements MeditationDeadlineTimerHandle {
  final Timer _timer;

  const _DartDeadlineTimerHandle(this._timer);

  @override
  void cancel() => _timer.cancel();
}
