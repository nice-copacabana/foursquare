import 'package:equatable/equatable.dart';

/// Immutable per-turn deadline used by offline and authoritative LAN sessions.
class TurnClock extends Equatable {
  static const Duration defaultTurnDuration = Duration(seconds: 60);

  final DateTime? deadlineUtc;
  final Duration? _pausedRemaining;

  const TurnClock._({
    this.deadlineUtc,
    Duration? pausedRemaining,
  }) : _pausedRemaining = pausedRemaining;

  factory TurnClock.started(
    DateTime now, {
    Duration turnDuration = defaultTurnDuration,
  }) {
    return TurnClock._(deadlineUtc: now.toUtc().add(turnDuration));
  }

  bool get isPaused => deadlineUtc == null;

  Duration remainingAt(DateTime now) {
    if (isPaused) {
      return _pausedRemaining ?? Duration.zero;
    }
    final remaining = deadlineUtc!.difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiredAt(DateTime now) => remainingAt(now) == Duration.zero;

  TurnClock pause(DateTime now) {
    if (isPaused) {
      return this;
    }
    return TurnClock._(pausedRemaining: remainingAt(now));
  }

  TurnClock resume(DateTime now) {
    if (!isPaused) {
      return this;
    }
    return TurnClock._(
      deadlineUtc: now.toUtc().add(_pausedRemaining ?? Duration.zero),
    );
  }

  @override
  List<Object?> get props => [deadlineUtc, _pausedRemaining];
}
