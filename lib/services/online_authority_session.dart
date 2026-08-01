import 'package:uuid/uuid.dart';

import '../models/online_protocol.dart';
import '../models/position.dart';

typedef OnlineCommandIdGenerator = String Function();

enum OnlineSessionUpdate {
  applied,
  rejected,
  duplicate,
  requiresSnapshot,
  ignored,
}

enum OnlineSessionError {
  commandPending,
  gameFinished,
  wrongTurn,
  differentMatch,
  colorChanged,
  stateMatchMismatch,
  nonTerminalGameOver,
}

class OnlineSessionException implements Exception {
  final OnlineSessionError error;

  const OnlineSessionException(this.error);

  @override
  String toString() => 'OnlineSessionException(${error.name})';
}

/// Applies only complete server-authoritative states to the online board.
///
/// Creating a move intent never mutates [state]. The state changes only after
/// a contiguous committed decision or a full snapshot from the server.
class OnlineAuthoritySession {
  OnlineAuthoritySession({
    required OnlineStateSnapshot snapshot,
    OnlineCommandIdGenerator? commandIdGenerator,
  })  : _matchId = snapshot.matchId,
        _color = snapshot.color,
        _state = snapshot.state,
        _turnDeadlineEpochMs = snapshot.turnDeadlineEpochMs,
        _commandIdGenerator = commandIdGenerator ?? (() => const Uuid().v4()) {
    if (!_stateBelongsToMatch(snapshot.state)) {
      throw const OnlineSessionException(
        OnlineSessionError.stateMatchMismatch,
      );
    }
  }

  final String _matchId;
  final OnlineCommandIdGenerator _commandIdGenerator;

  final OnlinePieceColor _color;
  OnlineGameState _state;
  int _turnDeadlineEpochMs;
  OnlineMoveIntent? _pendingIntent;
  OnlineMoveRejectionReason? _lastRejection;

  String get matchId => _matchId;
  OnlinePieceColor get color => _color;
  OnlineGameState get state => _state;
  int get turnDeadlineEpochMs => _turnDeadlineEpochMs;
  String? get pendingCommandId => _pendingIntent?.commandId;
  OnlineMoveRejectionReason? get lastRejection => _lastRejection;

  OnlineMoveIntent createMoveIntent({
    required Position from,
    required Position to,
  }) {
    if (_pendingIntent != null) {
      throw const OnlineSessionException(OnlineSessionError.commandPending);
    }
    if (_state.status != OnlineGameStatus.playing) {
      throw const OnlineSessionException(OnlineSessionError.gameFinished);
    }
    if (_state.currentTurn != _color) {
      throw const OnlineSessionException(OnlineSessionError.wrongTurn);
    }

    final OnlineMoveIntent intent = OnlineMoveIntent(
      matchId: _matchId,
      commandId: _commandIdGenerator(),
      expectedRevision: _state.revision,
      from: from,
      to: to,
    );
    _pendingIntent = intent;
    _lastRejection = null;
    return intent;
  }

  bool discardPendingIntent(String commandId) {
    if (_pendingIntent?.commandId != commandId) return false;
    _clearPending();
    return true;
  }

  OnlineSessionUpdate applyDecision(OnlineMoveDecision decision) {
    if (decision is OnlineMoveRejected) {
      return _applyRejection(decision);
    }

    final OnlineMoveCommitted committed = decision as OnlineMoveCommitted;
    if (committed.state.revision <= _state.revision) {
      if (_pendingIntent?.commandId == committed.commandId &&
          committed.state.revision == _state.revision) {
        return OnlineSessionUpdate.requiresSnapshot;
      }
      return OnlineSessionUpdate.duplicate;
    }
    if (committed.state.revision != _state.revision + 1 ||
        !_stateBelongsToMatch(committed.state)) {
      _clearPending();
      return OnlineSessionUpdate.requiresSnapshot;
    }

    _state = committed.state;
    _turnDeadlineEpochMs = committed.turnDeadlineEpochMs;
    _clearPending();
    return OnlineSessionUpdate.applied;
  }

  OnlineSessionUpdate applySnapshot(OnlineStateSnapshot snapshot) {
    if (snapshot.matchId != _matchId) {
      throw const OnlineSessionException(OnlineSessionError.differentMatch);
    }
    if (snapshot.color != _color) {
      throw const OnlineSessionException(OnlineSessionError.colorChanged);
    }
    if (!_stateBelongsToMatch(snapshot.state)) {
      throw const OnlineSessionException(
        OnlineSessionError.stateMatchMismatch,
      );
    }
    if (snapshot.state.revision < _state.revision) {
      return OnlineSessionUpdate.ignored;
    }

    _state = snapshot.state;
    _turnDeadlineEpochMs = snapshot.turnDeadlineEpochMs;
    _clearPending();
    return OnlineSessionUpdate.applied;
  }

  OnlineSessionUpdate applyGameOver({
    required String matchId,
    required OnlineGameState state,
  }) {
    if (matchId != _matchId) {
      throw const OnlineSessionException(OnlineSessionError.differentMatch);
    }
    if (state.status != OnlineGameStatus.finished) {
      throw const OnlineSessionException(
        OnlineSessionError.nonTerminalGameOver,
      );
    }
    if (!_stateBelongsToMatch(state)) {
      throw const OnlineSessionException(
        OnlineSessionError.stateMatchMismatch,
      );
    }
    if (state.revision < _state.revision) {
      return OnlineSessionUpdate.ignored;
    }
    if (state.revision == _state.revision &&
        _state.status == OnlineGameStatus.finished) {
      return OnlineSessionUpdate.duplicate;
    }

    _state = state;
    _clearPending();
    return OnlineSessionUpdate.applied;
  }

  OnlineSessionUpdate _applyRejection(OnlineMoveRejected rejected) {
    if (_pendingIntent?.commandId != rejected.commandId) {
      return OnlineSessionUpdate.ignored;
    }

    _pendingIntent = null;
    _lastRejection = rejected.reason;
    if (rejected.reason == OnlineMoveRejectionReason.staleRevision ||
        rejected.currentRevision != _state.revision) {
      return OnlineSessionUpdate.requiresSnapshot;
    }
    return OnlineSessionUpdate.rejected;
  }

  bool _stateBelongsToMatch(OnlineGameState candidate) {
    return candidate.moveHistory.every((move) => move.matchId == _matchId);
  }

  void _clearPending() {
    _pendingIntent = null;
    _lastRejection = null;
  }
}
