import 'dart:convert';

import '../engine/game_engine.dart';
import '../models/board_state.dart';
import '../models/game_result.dart';
import '../models/lan_protocol.dart';
import '../models/move.dart';
import '../models/piece_type.dart';

typedef LanAuthorityClock = DateTime Function();

/// Pure in-memory authority for one LAN game.
///
/// Network transports submit intents to this class. Only committed messages and
/// snapshots produced here are authoritative.
class LanHostAuthority {
  static const Duration turnDuration = Duration(seconds: 60);
  static const Duration reconnectGrace = Duration(seconds: 30);

  final GameEngine _engine;
  final LanAuthorityClock _clock;
  final String gameId;
  final PieceType startingPlayer;
  final DateTime _startedAtUtc;

  BoardState _boardState;
  List<Move> _moveHistory;
  int _noCapturePlyCount;
  int _revision;
  DateTime? _turnDeadlineUtc;
  GameResult? _gameResult;
  final Map<String, _ProcessedCommand> _processedCommands = {};
  final Map<PieceType, DateTime> _disconnectDeadlinesUtc = {};

  factory LanHostAuthority.newGame({
    required String gameId,
    required PieceType startingPlayer,
    required LanAuthorityClock clock,
    GameEngine? engine,
  }) {
    _validatePlayer(startingPlayer, 'startingPlayer');
    final now = _utc(clock());
    final authority = LanHostAuthority._(
      gameId: gameId,
      startingPlayer: startingPlayer,
      boardState: BoardState.initial(currentPlayer: startingPlayer),
      moveHistory: const [],
      noCapturePlyCount: 0,
      revision: 0,
      turnDeadlineUtc: now.add(turnDuration),
      gameResult: null,
      startedAtUtc: now,
      clock: clock,
      engine: engine ?? GameEngine(),
    );
    authority._engine.startNewGame();
    return authority;
  }

  factory LanHostAuthority.fromSnapshot(
    LanStateSnapshot snapshot, {
    required LanAuthorityClock clock,
    GameEngine? engine,
  }) {
    final now = _utc(clock());
    final authority = LanHostAuthority._(
      gameId: snapshot.gameId,
      startingPlayer: snapshot.startingPlayer,
      boardState: snapshot.boardState,
      moveHistory: snapshot.moveHistory.map(_withUtcTimestamp).toList(),
      noCapturePlyCount: snapshot.noCapturePlyCount,
      revision: snapshot.revision,
      turnDeadlineUtc: snapshot.turnDeadlineUtc,
      gameResult: snapshot.gameResult,
      startedAtUtc: now,
      clock: clock,
      engine: engine ?? GameEngine(),
    );
    authority._engine.startNewGame();
    return authority;
  }

  LanHostAuthority._({
    required this.gameId,
    required this.startingPlayer,
    required BoardState boardState,
    required List<Move> moveHistory,
    required int noCapturePlyCount,
    required int revision,
    required DateTime? turnDeadlineUtc,
    required GameResult? gameResult,
    required DateTime startedAtUtc,
    required LanAuthorityClock clock,
    required GameEngine engine,
  })  : _boardState = boardState,
        _moveHistory = List.of(moveHistory),
        _noCapturePlyCount = noCapturePlyCount,
        _revision = revision,
        _turnDeadlineUtc = turnDeadlineUtc,
        _gameResult = gameResult,
        _startedAtUtc = startedAtUtc,
        _clock = clock,
        _engine = engine;

  BoardState get boardState => _boardState;

  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  int get noCapturePlyCount => _noCapturePlyCount;

  int get revision => _revision;

  DateTime? get turnDeadlineUtc => _turnDeadlineUtc;

  GameResult? get gameResult => _gameResult;

  bool get isFinished => _gameResult != null;

  DateTime? disconnectDeadlineFor(PieceType player) =>
      _disconnectDeadlinesUtc[player];

  /// Validates and commits a move intent for the connected player's color.
  LanProtocolMessage handleMoveIntent(
    LanMoveIntent intent, {
    required PieceType sender,
  }) {
    _validatePlayer(sender, 'sender');

    final processed = _processedCommands[intent.commandId];
    if (processed != null) {
      if (processed.sender == sender && processed.intent == intent) {
        return processed.response;
      }
      return LanMoveRejected(
        gameId: gameId,
        commandId: intent.commandId,
        revision: _revision,
        reason: LanMoveRejectionReason.unauthorized,
      );
    }

    tick();

    if (intent.gameId != gameId) {
      return _rememberRejection(
        intent,
        sender,
        LanMoveRejectionReason.unauthorized,
      );
    }
    if (_gameResult != null) {
      return _rememberRejection(
        intent,
        sender,
        LanMoveRejectionReason.gameFinished,
      );
    }
    if (intent.expectedRevision != _revision) {
      return _rememberRejection(
        intent,
        sender,
        LanMoveRejectionReason.staleRevision,
      );
    }
    if (sender != _boardState.currentPlayer) {
      return _rememberRejection(
        intent,
        sender,
        LanMoveRejectionReason.wrongTurn,
      );
    }

    final result = _engine.executeMove(
      _boardState,
      intent.from,
      intent.to,
      noCapturePlyCount: _noCapturePlyCount,
    );
    if (!result.success || result.newBoard == null || result.move == null) {
      return _rememberRejection(
        intent,
        sender,
        LanMoveRejectionReason.illegalMove,
      );
    }

    final authoritativeMove = result.move!.copyWith(
      timestamp: result.move!.timestamp.toUtc(),
    );
    _boardState = result.newBoard!;
    _moveHistory = [..._moveHistory, authoritativeMove];
    _noCapturePlyCount = result.noCapturePlyCount;
    _gameResult = result.gameResult == null
        ? null
        : _withAuthorityMetadata(
            result.gameResult!,
            moveCount: _moveHistory.length,
            duration: _utc(_clock()).difference(_startedAtUtc),
          );
    _revision++;
    _turnDeadlineUtc =
        _gameResult == null ? _utc(_clock()).add(turnDuration) : null;

    final committed = LanMoveCommitted(
      gameId: gameId,
      commandId: intent.commandId,
      revision: _revision,
      move: authoritativeMove,
      noCapturePlyCount: _noCapturePlyCount,
      currentPlayer: _boardState.currentPlayer,
      turnDeadlineUtc: _turnDeadlineUtc,
      gameResult: _gameResult,
      stateHash: stateHash,
    );
    _processedCommands[intent.commandId] = _ProcessedCommand(
      intent: intent,
      sender: sender,
      response: committed,
    );
    return committed;
  }

  /// Advances absolute turn/disconnect deadlines without using timers.
  ///
  /// Returns the terminal result created by this call, if any.
  GameResult? tick() {
    if (_gameResult != null) {
      return null;
    }
    final now = _utc(_clock());
    final turnDeadline = _turnDeadlineUtc;
    final expiredDisconnect = _earliestExpiredDisconnect(now);

    if (turnDeadline != null &&
        !now.isBefore(turnDeadline) &&
        (expiredDisconnect == null ||
            !expiredDisconnect.deadline.isBefore(turnDeadline))) {
      _finish(
        GameResult.timeout(
          timeoutPlayer: _boardState.currentPlayer,
          moveCount: _moveHistory.length,
          duration: now.difference(_startedAtUtc),
        ),
      );
      return _gameResult;
    }

    if (expiredDisconnect != null) {
      _finish(_disconnectResult(expiredDisconnect.player, now));
      return _gameResult;
    }
    return null;
  }

  /// Starts or preserves a 30-second reconnect grace period.
  DateTime markDisconnected(PieceType player) {
    _validatePlayer(player, 'player');
    tick();
    if (_gameResult != null) {
      return _disconnectDeadlinesUtc[player] ?? _utc(_clock());
    }
    return _disconnectDeadlinesUtc.putIfAbsent(
      player,
      () => _utc(_clock()).add(reconnectGrace),
    );
  }

  /// Reconnects within the grace period and returns a full authority snapshot.
  LanStateSnapshot? markReconnected(PieceType player) {
    _validatePlayer(player, 'player');
    tick();
    if (_gameResult != null || !_disconnectDeadlinesUtc.containsKey(player)) {
      return null;
    }
    _disconnectDeadlinesUtc.remove(player);
    return createSnapshot();
  }

  LanStateSnapshot createSnapshot() {
    return LanStateSnapshot(
      gameId: gameId,
      revision: _revision,
      boardState: _boardState,
      startingPlayer: startingPlayer,
      moveHistory: _moveHistory,
      noCapturePlyCount: _noCapturePlyCount,
      turnDeadlineUtc: _turnDeadlineUtc,
      gameResult: _gameResult,
      stateHash: stateHash,
    );
  }

  String get stateHash {
    final payload = jsonEncode({
      'protocolVersion': LanProtocol.currentVersion,
      'gameId': gameId,
      'revision': _revision,
      'grid': _boardState.grid
          .map((row) => row.map((piece) => piece.name).toList())
          .toList(),
      'currentPlayer': _boardState.currentPlayer.name,
      'startingPlayer': startingPlayer.name,
      'moveHistory': _moveHistory.map((move) => move.toJson()).toList(),
      'noCapturePlyCount': _noCapturePlyCount,
      'turnDeadlineUtc': _turnDeadlineUtc?.toUtc().toIso8601String(),
      'gameResult': _gameResult?.toJson(),
    });
    return _fnv1a64(payload);
  }

  LanMoveRejected _rememberRejection(
    LanMoveIntent intent,
    PieceType sender,
    LanMoveRejectionReason reason,
  ) {
    final rejected = LanMoveRejected(
      gameId: gameId,
      commandId: intent.commandId,
      revision: _revision,
      reason: reason,
    );
    _processedCommands[intent.commandId] = _ProcessedCommand(
      intent: intent,
      sender: sender,
      response: rejected,
    );
    return rejected;
  }

  _ExpiredDisconnect? _earliestExpiredDisconnect(DateTime now) {
    _ExpiredDisconnect? earliest;
    for (final entry in _disconnectDeadlinesUtc.entries) {
      if (now.isBefore(entry.value)) {
        continue;
      }
      if (earliest == null || entry.value.isBefore(earliest.deadline)) {
        earliest = _ExpiredDisconnect(entry.key, entry.value);
      }
    }
    return earliest;
  }

  void _finish(GameResult result) {
    _gameResult = result;
    _turnDeadlineUtc = null;
    _disconnectDeadlinesUtc.clear();
    _revision++;
  }

  GameResult _disconnectResult(PieceType disconnectedPlayer, DateTime now) {
    final winner = disconnectedPlayer.getOpponent();
    final reason = '${disconnectedPlayer.getDisplayName()}断线超时';
    if (winner == PieceType.black) {
      return GameResult.blackWin(
        reason: reason,
        endReason: GameEndReason.disconnect,
        moveCount: _moveHistory.length,
        duration: now.difference(_startedAtUtc),
      );
    }
    return GameResult.whiteWin(
      reason: reason,
      endReason: GameEndReason.disconnect,
      moveCount: _moveHistory.length,
      duration: now.difference(_startedAtUtc),
    );
  }
}

class _ProcessedCommand {
  final LanMoveIntent intent;
  final PieceType sender;
  final LanProtocolMessage response;

  const _ProcessedCommand({
    required this.intent,
    required this.sender,
    required this.response,
  });
}

class _ExpiredDisconnect {
  final PieceType player;
  final DateTime deadline;

  const _ExpiredDisconnect(this.player, this.deadline);
}

DateTime _utc(DateTime value) => value.toUtc();

void _validatePlayer(PieceType player, String field) {
  if (player == PieceType.empty) {
    throw ArgumentError.value(player, field, 'must be black or white');
  }
}

String _fnv1a64(String value) {
  const offsetBasis = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  const mask = 0xffffffffffffffff;
  var hash = offsetBasis;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

Move _withUtcTimestamp(Move move) {
  return move.copyWith(timestamp: move.timestamp.toUtc());
}

GameResult _withAuthorityMetadata(
  GameResult result, {
  required int moveCount,
  required Duration duration,
}) {
  return GameResult(
    status: result.status,
    winner: result.winner,
    reason: result.reason,
    endReason: result.endReason,
    moveCount: moveCount,
    duration: duration,
  );
}
