import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'board_state.dart';
import 'game_result.dart';
import 'move.dart';
import 'piece_type.dart';
import 'position.dart';

/// Current LAN wire protocol.
abstract final class LanProtocol {
  static const int currentVersion = 1;

  static LanProtocolMessage fromJson(Map<String, dynamic> json) {
    final version = json['protocolVersion'];
    if (version == null) {
      throw const LanProtocolException(
        LanProtocolError.missingProtocolVersion,
        'protocolVersion is required',
      );
    }
    if (version is! int || version != currentVersion) {
      throw LanProtocolException(
        LanProtocolError.unsupportedProtocolVersion,
        'Unsupported protocolVersion: $version',
      );
    }

    final type = _requiredString(json, 'type');
    try {
      switch (type) {
        case LanProtocolMessageType.moveIntentName:
          return LanMoveIntent.fromJson(json);
        case LanProtocolMessageType.moveCommittedName:
          return LanMoveCommitted.fromJson(json);
        case LanProtocolMessageType.moveRejectedName:
          return LanMoveRejected.fromJson(json);
        case LanProtocolMessageType.stateSnapshotName:
          return LanStateSnapshot.fromJson(json);
        default:
          throw LanProtocolException(
            LanProtocolError.unknownMessageType,
            'Unknown LAN message type: $type',
          );
      }
    } on LanProtocolException {
      rethrow;
    } catch (error) {
      throw LanProtocolException(
        LanProtocolError.invalidField,
        'Invalid $type payload: $error',
      );
    }
  }

  static LanProtocolMessage fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw const LanProtocolException(
          LanProtocolError.invalidField,
          'LAN message must be a JSON object',
        );
      }
      return fromJson(decoded);
    } on LanProtocolException {
      rethrow;
    } catch (error) {
      throw LanProtocolException(
        LanProtocolError.invalidField,
        'Invalid LAN message JSON: $error',
      );
    }
  }
}

abstract final class LanProtocolMessageType {
  static const String moveIntentName = 'moveIntent';
  static const String moveCommittedName = 'moveCommitted';
  static const String moveRejectedName = 'moveRejected';
  static const String stateSnapshotName = 'stateSnapshot';
}

enum LanProtocolError {
  missingProtocolVersion,
  unsupportedProtocolVersion,
  unknownMessageType,
  missingField,
  invalidField,
}

class LanProtocolException implements Exception {
  final LanProtocolError error;
  final String message;

  const LanProtocolException(this.error, this.message);

  @override
  String toString() => 'LanProtocolException(${error.name}): $message';
}

sealed class LanProtocolMessage extends Equatable {
  final int protocolVersion;
  final String gameId;

  const LanProtocolMessage._({
    required this.protocolVersion,
    required this.gameId,
  });

  String get type;

  Map<String, dynamic> toJson();

  String toJsonString() => jsonEncode(toJson());
}

class LanMoveIntent extends LanProtocolMessage {
  final String commandId;
  final int expectedRevision;
  final Position from;
  final Position to;

  factory LanMoveIntent({
    required String gameId,
    required String commandId,
    required int expectedRevision,
    required Position from,
    required Position to,
  }) {
    _validateIdentifier(gameId, 'gameId');
    _validateIdentifier(commandId, 'commandId');
    _validateRevision(expectedRevision, 'expectedRevision');
    _validateIntentCoordinates(from, to);
    return LanMoveIntent._(
      gameId: gameId,
      commandId: commandId,
      expectedRevision: expectedRevision,
      from: from,
      to: to,
    );
  }

  const LanMoveIntent._({
    required super.gameId,
    required this.commandId,
    required this.expectedRevision,
    required this.from,
    required this.to,
  }) : super._(protocolVersion: LanProtocol.currentVersion);

  factory LanMoveIntent.fromJson(Map<String, dynamic> json) {
    return LanMoveIntent(
      gameId: _requiredString(json, 'gameId'),
      commandId: _requiredString(json, 'commandId'),
      expectedRevision: _requiredInt(json, 'expectedRevision'),
      from: _positionFromJson(_requiredMap(json, 'from'), 'from'),
      to: _positionFromJson(_requiredMap(json, 'to'), 'to'),
    );
  }

  @override
  String get type => LanProtocolMessageType.moveIntentName;

  @override
  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'type': type,
        'gameId': gameId,
        'commandId': commandId,
        'expectedRevision': expectedRevision,
        'from': _positionToJson(from),
        'to': _positionToJson(to),
      };

  @override
  List<Object?> get props => [
        protocolVersion,
        gameId,
        commandId,
        expectedRevision,
        from,
        to,
      ];
}

class LanMoveCommitted extends LanProtocolMessage {
  final String commandId;
  final int revision;
  final Move move;
  final int noCapturePlyCount;
  final PieceType currentPlayer;
  final DateTime? turnDeadlineUtc;
  final GameResult? gameResult;
  final String stateHash;

  factory LanMoveCommitted({
    required String gameId,
    required String commandId,
    required int revision,
    required Move move,
    required int noCapturePlyCount,
    required PieceType currentPlayer,
    required DateTime? turnDeadlineUtc,
    required GameResult? gameResult,
    required String stateHash,
  }) {
    _validateIdentifier(gameId, 'gameId');
    _validateIdentifier(commandId, 'commandId');
    _validateCommittedRevision(revision);
    _validateMove(move);
    _validateNoCapturePlyCount(noCapturePlyCount);
    _validatePlayer(currentPlayer, 'currentPlayer');
    _validateTurnState(turnDeadlineUtc, gameResult);
    _validateNoCaptureTerminal(noCapturePlyCount, gameResult);
    if (gameResult == null && currentPlayer != move.player.getOpponent()) {
      throw const LanProtocolException(
        LanProtocolError.invalidField,
        'ongoing commit must pass the turn to the opponent',
      );
    }
    _validateIdentifier(stateHash, 'stateHash');
    return LanMoveCommitted._(
      gameId: gameId,
      commandId: commandId,
      revision: revision,
      move: move,
      noCapturePlyCount: noCapturePlyCount,
      currentPlayer: currentPlayer,
      turnDeadlineUtc: turnDeadlineUtc,
      gameResult: gameResult,
      stateHash: stateHash,
    );
  }

  const LanMoveCommitted._({
    required super.gameId,
    required this.commandId,
    required this.revision,
    required this.move,
    required this.noCapturePlyCount,
    required this.currentPlayer,
    required this.turnDeadlineUtc,
    required this.gameResult,
    required this.stateHash,
  }) : super._(protocolVersion: LanProtocol.currentVersion);

  factory LanMoveCommitted.fromJson(Map<String, dynamic> json) {
    return LanMoveCommitted(
      gameId: _requiredString(json, 'gameId'),
      commandId: _requiredString(json, 'commandId'),
      revision: _requiredInt(json, 'revision'),
      move: _moveFromJson(_requiredMap(json, 'move')),
      noCapturePlyCount: _requiredInt(json, 'noCapturePlyCount'),
      currentPlayer: _playerFromJson(json, 'currentPlayer'),
      turnDeadlineUtc: _optionalUtcDateTime(json, 'turnDeadlineUtc'),
      gameResult: _optionalGameResult(json, 'gameResult'),
      stateHash: _requiredString(json, 'stateHash'),
    );
  }

  @override
  String get type => LanProtocolMessageType.moveCommittedName;

  @override
  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'type': type,
        'gameId': gameId,
        'commandId': commandId,
        'revision': revision,
        'move': _moveToJson(move),
        'noCapturePlyCount': noCapturePlyCount,
        'currentPlayer': currentPlayer.name,
        'turnDeadlineUtc': turnDeadlineUtc?.toUtc().toIso8601String(),
        'gameResult': gameResult?.toJson(),
        'stateHash': stateHash,
      };

  @override
  List<Object?> get props => [
        protocolVersion,
        gameId,
        commandId,
        revision,
        move,
        noCapturePlyCount,
        currentPlayer,
        turnDeadlineUtc,
        gameResult,
        stateHash,
      ];
}

enum LanMoveRejectionReason {
  wrongTurn,
  illegalMove,
  staleRevision,
  gameFinished,
  unauthorized,
}

class LanMoveRejected extends LanProtocolMessage {
  final String commandId;
  final int revision;
  final LanMoveRejectionReason reason;

  factory LanMoveRejected({
    required String gameId,
    required String commandId,
    required int revision,
    required LanMoveRejectionReason reason,
  }) {
    _validateIdentifier(gameId, 'gameId');
    _validateIdentifier(commandId, 'commandId');
    _validateRevision(revision, 'revision');
    return LanMoveRejected._(
      gameId: gameId,
      commandId: commandId,
      revision: revision,
      reason: reason,
    );
  }

  const LanMoveRejected._({
    required super.gameId,
    required this.commandId,
    required this.revision,
    required this.reason,
  }) : super._(protocolVersion: LanProtocol.currentVersion);

  factory LanMoveRejected.fromJson(Map<String, dynamic> json) {
    final reasonName = _requiredString(json, 'reason');
    return LanMoveRejected(
      gameId: _requiredString(json, 'gameId'),
      commandId: _requiredString(json, 'commandId'),
      revision: _requiredInt(json, 'revision'),
      reason: _enumByName(
        LanMoveRejectionReason.values,
        reasonName,
        'reason',
      ),
    );
  }

  @override
  String get type => LanProtocolMessageType.moveRejectedName;

  @override
  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'type': type,
        'gameId': gameId,
        'commandId': commandId,
        'revision': revision,
        'reason': reason.name,
      };

  @override
  List<Object?> get props => [
        protocolVersion,
        gameId,
        commandId,
        revision,
        reason,
      ];
}

class LanStateSnapshot extends LanProtocolMessage {
  final int revision;
  final BoardState boardState;
  final PieceType startingPlayer;
  final List<Move> moveHistory;
  final int noCapturePlyCount;
  final DateTime? turnDeadlineUtc;
  final GameResult? gameResult;
  final String stateHash;

  factory LanStateSnapshot({
    required String gameId,
    required int revision,
    required BoardState boardState,
    required PieceType startingPlayer,
    required List<Move> moveHistory,
    required int noCapturePlyCount,
    required DateTime? turnDeadlineUtc,
    required GameResult? gameResult,
    required String stateHash,
  }) {
    _validateIdentifier(gameId, 'gameId');
    _validateRevision(revision, 'revision');
    _validateBoard(boardState);
    _validatePlayer(startingPlayer, 'startingPlayer');
    for (final move in moveHistory) {
      _validateMove(move);
    }
    _validateNoCapturePlyCount(noCapturePlyCount);
    _validateTurnState(turnDeadlineUtc, gameResult);
    _validateNoCaptureTerminal(noCapturePlyCount, gameResult);
    _validateSnapshotTerminalInvariant(boardState, gameResult);
    _validateIdentifier(stateHash, 'stateHash');
    return LanStateSnapshot._(
      gameId: gameId,
      revision: revision,
      boardState: boardState,
      startingPlayer: startingPlayer,
      moveHistory: List.unmodifiable(moveHistory),
      noCapturePlyCount: noCapturePlyCount,
      turnDeadlineUtc: turnDeadlineUtc,
      gameResult: gameResult,
      stateHash: stateHash,
    );
  }

  const LanStateSnapshot._({
    required super.gameId,
    required this.revision,
    required this.boardState,
    required this.startingPlayer,
    required this.moveHistory,
    required this.noCapturePlyCount,
    required this.turnDeadlineUtc,
    required this.gameResult,
    required this.stateHash,
  }) : super._(protocolVersion: LanProtocol.currentVersion);

  factory LanStateSnapshot.fromJson(Map<String, dynamic> json) {
    final history = _requiredList(json, 'moveHistory').map((item) {
      if (item is! Map<String, dynamic>) {
        throw const LanProtocolException(
          LanProtocolError.invalidField,
          'moveHistory entries must be objects',
        );
      }
      return _moveFromJson(item);
    }).toList(growable: false);

    return LanStateSnapshot(
      gameId: _requiredString(json, 'gameId'),
      revision: _requiredInt(json, 'revision'),
      boardState: _boardFromJson(_requiredMap(json, 'boardState')),
      startingPlayer: _playerFromJson(json, 'startingPlayer'),
      moveHistory: history,
      noCapturePlyCount: _requiredInt(json, 'noCapturePlyCount'),
      turnDeadlineUtc: _optionalUtcDateTime(json, 'turnDeadlineUtc'),
      gameResult: _optionalGameResult(json, 'gameResult'),
      stateHash: _requiredString(json, 'stateHash'),
    );
  }

  PieceType get currentPlayer => boardState.currentPlayer;

  @override
  String get type => LanProtocolMessageType.stateSnapshotName;

  @override
  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'type': type,
        'gameId': gameId,
        'revision': revision,
        'boardState': _boardToJson(boardState),
        'startingPlayer': startingPlayer.name,
        'moveHistory': moveHistory.map(_moveToJson).toList(growable: false),
        'noCapturePlyCount': noCapturePlyCount,
        'turnDeadlineUtc': turnDeadlineUtc?.toUtc().toIso8601String(),
        'gameResult': gameResult?.toJson(),
        'stateHash': stateHash,
      };

  @override
  List<Object?> get props => [
        protocolVersion,
        gameId,
        revision,
        boardState,
        startingPlayer,
        moveHistory,
        noCapturePlyCount,
        turnDeadlineUtc,
        gameResult,
        stateHash,
      ];
}

void _validateIdentifier(String value, String field) {
  if (value.trim().isEmpty) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must not be blank',
    );
  }
}

void _validateRevision(int value, String field) {
  if (value < 0) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be non-negative',
    );
  }
}

void _validateCommittedRevision(int revision) {
  if (revision < 1) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'committed revision must be positive',
    );
  }
}

void _validateNoCapturePlyCount(int value) {
  if (value < 0 || value > 50) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'noCapturePlyCount must be between 0 and 50',
    );
  }
}

void _validateNoCaptureTerminal(int value, GameResult? result) {
  if (value == 50 && result == null) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'noCapturePlyCount 50 must be a terminal state',
    );
  }
}

void _validatePlayer(PieceType player, String field) {
  if (player == PieceType.empty) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be black or white',
    );
  }
}

void _validateIntentCoordinates(Position from, Position to) {
  if (!from.isValid() || !to.isValid()) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'move coordinates must be on the 4x4 board',
    );
  }
}

void _validateCommittedMoveCoordinates(Position from, Position to) {
  if (!from.isValid() || !to.isValid() || from.distanceTo(to) != 1) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'move coordinates must be valid orthogonally adjacent positions',
    );
  }
}

void _validateMove(Move move) {
  _validateCommittedMoveCoordinates(move.from, move.to);
  _validatePlayer(move.player, 'move.player');
  if (move.capturedPieces.length > 2 ||
      move.capturedPieces.toSet().length != move.capturedPieces.length ||
      move.capturedPieces.any(
        (position) =>
            !position.isValid() || position == move.from || position == move.to,
      )) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'capturedPieces must contain at most two unique valid positions',
    );
  }
}

void _validateTurnState(DateTime? deadline, GameResult? result) {
  if (result == null) {
    if (deadline == null || !deadline.isUtc) {
      throw const LanProtocolException(
        LanProtocolError.invalidField,
        'ongoing state requires a UTC turnDeadlineUtc',
      );
    }
  } else {
    if (!result.isGameOver) {
      throw const LanProtocolException(
        LanProtocolError.invalidField,
        'gameResult must be terminal',
      );
    }
    if (deadline != null) {
      throw const LanProtocolException(
        LanProtocolError.invalidField,
        'finished state must not have a turnDeadlineUtc',
      );
    }
  }
}

void _validateBoard(BoardState board) {
  if (board.grid.length != 4 || board.grid.any((row) => row.length != 4)) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'boardState must contain a 4x4 grid',
    );
  }
  _validatePlayer(board.currentPlayer, 'boardState.currentPlayer');

  final black = <Position>[];
  final white = <Position>[];
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      final position = Position(x, y);
      switch (board.grid[y][x]) {
        case PieceType.black:
          black.add(position);
        case PieceType.white:
          white.add(position);
        case PieceType.empty:
          break;
      }
    }
  }
  if (board.blackPieces.length != black.length ||
      board.whitePieces.length != white.length ||
      black.toSet().difference(board.blackPieces.toSet()).isNotEmpty ||
      board.blackPieces.toSet().difference(black.toSet()).isNotEmpty ||
      white.toSet().difference(board.whitePieces.toSet()).isNotEmpty ||
      board.whitePieces.toSet().difference(white.toSet()).isNotEmpty) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'boardState piece lists must match its grid',
    );
  }
}

void _validateSnapshotTerminalInvariant(
  BoardState board,
  GameResult? result,
) {
  if (result != null) {
    return;
  }
  if (board.getPieceCount(PieceType.black) <= 1 ||
      board.getPieceCount(PieceType.white) <= 1) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'ongoing snapshot cannot contain a side with at most one piece',
    );
  }
  final currentSideCanMove = board
      .getAllPieces(board.currentPlayer)
      .any((piece) => piece.getAdjacentPositions().any(board.isEmpty));
  if (!currentSideCanMove) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'ongoing snapshot requires a legal move for the current side',
    );
  }
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw LanProtocolException(
      LanProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! String || value.trim().isEmpty) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be a non-blank string',
    );
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw LanProtocolException(
      LanProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! int) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be an integer',
    );
  }
  return value;
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value == null) {
    throw LanProtocolException(
      LanProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! Map<String, dynamic>) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be an object',
    );
  }
  return value;
}

List<dynamic> _requiredList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw LanProtocolException(
      LanProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! List<dynamic>) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be an array',
    );
  }
  return value;
}

Position _positionFromJson(Map<String, dynamic> json, String field) {
  final x = _requiredInt(json, 'x');
  final y = _requiredInt(json, 'y');
  final position = Position(x, y);
  if (!position.isValid()) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be on the 4x4 board',
    );
  }
  return position;
}

Map<String, dynamic> _positionToJson(Position position) => {
      'x': position.x,
      'y': position.y,
    };

PieceType _playerFromJson(Map<String, dynamic> json, String field) {
  final name = _requiredString(json, field);
  final player = _enumByName(PieceType.values, name, field);
  _validatePlayer(player, field);
  return player;
}

T _enumByName<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  throw LanProtocolException(
    LanProtocolError.invalidField,
    'Unknown $field: $name',
  );
}

DateTime? _optionalUtcDateTime(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be an ISO-8601 UTC string or null',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be an ISO-8601 UTC string',
    );
  }
  return parsed;
}

GameResult? _optionalGameResult(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value == null) {
    return null;
  }
  if (value is! Map<String, dynamic>) {
    throw LanProtocolException(
      LanProtocolError.invalidField,
      '$field must be an object or null',
    );
  }
  return GameResult.fromJson(value);
}

Map<String, dynamic> _moveToJson(Move move) => {
      'from': _positionToJson(move.from),
      'to': _positionToJson(move.to),
      'player': move.player.name,
      'capturedPieces':
          move.capturedPieces.map(_positionToJson).toList(growable: false),
      'timestamp': move.timestamp.toUtc().toIso8601String(),
    };

Move _moveFromJson(Map<String, dynamic> json) {
  final capturedJson = _requiredList(json, 'capturedPieces');
  final capturedPieces = capturedJson.map((item) {
    if (item is! Map<String, dynamic>) {
      throw const LanProtocolException(
        LanProtocolError.invalidField,
        'capturedPieces entries must be objects',
      );
    }
    return _positionFromJson(item, 'capturedPieces');
  }).toList(growable: false);
  final timestamp = _optionalUtcDateTime(json, 'timestamp');
  if (timestamp == null) {
    throw const LanProtocolException(
      LanProtocolError.missingField,
      'timestamp is required',
    );
  }
  final move = Move(
    from: _positionFromJson(_requiredMap(json, 'from'), 'move.from'),
    to: _positionFromJson(_requiredMap(json, 'to'), 'move.to'),
    player: _playerFromJson(json, 'player'),
    capturedPieces: capturedPieces,
    timestamp: timestamp,
  );
  _validateMove(move);
  return move;
}

Map<String, dynamic> _boardToJson(BoardState board) => {
      'grid': board.grid
          .map(
            (row) => row.map((piece) => piece.name).toList(growable: false),
          )
          .toList(growable: false),
      'currentPlayer': board.currentPlayer.name,
    };

BoardState _boardFromJson(Map<String, dynamic> json) {
  final gridJson = _requiredList(json, 'grid');
  if (gridJson.length != 4) {
    throw const LanProtocolException(
      LanProtocolError.invalidField,
      'boardState.grid must contain four rows',
    );
  }

  final grid = <List<PieceType>>[];
  final black = <Position>[];
  final white = <Position>[];
  for (var y = 0; y < gridJson.length; y++) {
    final rowJson = gridJson[y];
    if (rowJson is! List<dynamic> || rowJson.length != 4) {
      throw const LanProtocolException(
        LanProtocolError.invalidField,
        'each boardState.grid row must contain four cells',
      );
    }
    final row = <PieceType>[];
    for (var x = 0; x < rowJson.length; x++) {
      final cell = rowJson[x];
      if (cell is! String) {
        throw const LanProtocolException(
          LanProtocolError.invalidField,
          'boardState.grid cells must be strings',
        );
      }
      final piece = _enumByName(PieceType.values, cell, 'boardState.grid');
      row.add(piece);
      if (piece == PieceType.black) {
        black.add(Position(x, y));
      } else if (piece == PieceType.white) {
        white.add(Position(x, y));
      }
    }
    grid.add(row);
  }

  final board = BoardState(
    grid: grid,
    blackPieces: black,
    whitePieces: white,
    currentPlayer: _playerFromJson(json, 'currentPlayer'),
  );
  _validateBoard(board);
  return board;
}
