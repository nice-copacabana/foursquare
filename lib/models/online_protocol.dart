import 'position.dart';

/// Versioned contract shared with the authoritative online game server.
abstract final class OnlineProtocol {
  static const int currentVersion = 1;
}

enum OnlineProtocolError {
  missingProtocolVersion,
  unsupportedProtocolVersion,
  unknownMessageType,
  missingField,
  invalidField,
}

class OnlineProtocolException implements Exception {
  final OnlineProtocolError error;
  final String message;

  const OnlineProtocolException(this.error, this.message);

  @override
  String toString() => 'OnlineProtocolException(${error.name}): $message';
}

enum OnlinePieceColor { black, white }

enum OnlineGameStatus { playing, finished }

enum OnlineGameWinner { black, white, draw }

enum OnlineGameEndReason {
  pieceCount('piece_count'),
  noCaptureLimit('no_capture_limit'),
  noLegalMoves('no_legal_moves'),
  timeout('timeout'),
  disconnect('disconnect'),
  abandoned('abandoned');

  final String wireName;

  const OnlineGameEndReason(this.wireName);
}

enum OnlineMoveRejectionReason {
  invalidProtocol('invalid_protocol'),
  invalidPayload('invalid_payload'),
  invalidState('invalid_state'),
  rateLimited('rate_limited'),
  roomNotFound('room_not_found'),
  notRoomPlayer('not_room_player'),
  commandConflict('command_conflict'),
  staleRevision('stale_revision'),
  wrongTurn('wrong_turn'),
  gameFinished('game_finished'),
  outOfBounds('out_of_bounds'),
  notYourPiece('not_your_piece'),
  targetOccupied('target_occupied'),
  notAdjacent('not_adjacent');

  final String wireName;

  const OnlineMoveRejectionReason(this.wireName);
}

class OnlineMoveIntent {
  final int protocolVersion;
  final String matchId;
  final String commandId;
  final int expectedRevision;
  final Position from;
  final Position to;

  OnlineMoveIntent({
    required this.matchId,
    required this.commandId,
    required this.expectedRevision,
    required this.from,
    required this.to,
  }) : protocolVersion = OnlineProtocol.currentVersion {
    _validateIdentifier(matchId, 'matchId');
    _validateIdentifier(commandId, 'commandId');
    _validateRevision(expectedRevision, 'expectedRevision');
    _validatePosition(from, 'from');
    _validatePosition(to, 'to');
  }

  Map<String, dynamic> toJson() => {
        'protocolVersion': OnlineProtocol.currentVersion,
        'matchId': matchId,
        'commandId': commandId,
        'expectedRevision': expectedRevision,
        'from': _positionToJson(from),
        'to': _positionToJson(to),
      };
}

class OnlineRecordedMove {
  final String matchId;
  final Position from;
  final Position to;
  final OnlinePieceColor player;
  final List<Position> capturedPieces;

  OnlineRecordedMove._({
    required this.matchId,
    required this.from,
    required this.to,
    required this.player,
    required List<Position> capturedPieces,
  }) : capturedPieces = List.unmodifiable(capturedPieces);

  factory OnlineRecordedMove.fromJson(Map<String, dynamic> json) {
    final capturedPieces = _positionsFromJson(json, 'capturedPieces');
    _validateCapturedPieces(capturedPieces);
    return OnlineRecordedMove._(
      matchId: _requiredString(json, 'matchId'),
      from: _positionFromJson(_requiredMap(json, 'from'), 'from'),
      to: _positionFromJson(_requiredMap(json, 'to'), 'to'),
      player: _enumByName(
        OnlinePieceColor.values,
        _requiredString(json, 'player'),
        'player',
      ),
      capturedPieces: capturedPieces,
    );
  }
}

class OnlineGameState {
  final List<List<OnlinePieceColor?>> board;
  final OnlinePieceColor currentTurn;
  final OnlineGameStatus status;
  final OnlineGameWinner? winner;
  final OnlineGameEndReason? endReason;
  final List<OnlineRecordedMove> moveHistory;
  final int noCapturePly;
  final int revision;

  OnlineGameState._({
    required List<List<OnlinePieceColor?>> board,
    required this.currentTurn,
    required this.status,
    required this.winner,
    required this.endReason,
    required List<OnlineRecordedMove> moveHistory,
    required this.noCapturePly,
    required this.revision,
  })  : board = List.unmodifiable(
          board.map((row) => List<OnlinePieceColor?>.unmodifiable(row)),
        ),
        moveHistory = List.unmodifiable(moveHistory);

  factory OnlineGameState.fromJson(Map<String, dynamic> json) {
    final status = _enumByName(
      OnlineGameStatus.values,
      _requiredString(json, 'status'),
      'status',
    );
    final winner = _optionalEnumByName(
      OnlineGameWinner.values,
      json['winner'],
      'winner',
    );
    final endReason = _optionalEnumByWireName(
      OnlineGameEndReason.values,
      json['endReason'],
      'endReason',
      (reason) => reason.wireName,
    );
    if (status == OnlineGameStatus.playing &&
        (winner != null || endReason != null)) {
      throw const OnlineProtocolException(
        OnlineProtocolError.invalidField,
        'playing state cannot contain winner or endReason',
      );
    }
    if (status == OnlineGameStatus.finished &&
        (winner == null || endReason == null)) {
      throw const OnlineProtocolException(
        OnlineProtocolError.missingField,
        'finished state requires winner and endReason',
      );
    }
    if (status == OnlineGameStatus.finished &&
        ((endReason == OnlineGameEndReason.noCaptureLimit &&
                winner != OnlineGameWinner.draw) ||
            (endReason != OnlineGameEndReason.noCaptureLimit &&
                winner == OnlineGameWinner.draw))) {
      throw const OnlineProtocolException(
        OnlineProtocolError.invalidField,
        'winner and endReason must describe the same terminal result',
      );
    }

    final noCapturePly = _requiredInt(json, 'noCapturePly');
    if (noCapturePly < 0 || noCapturePly > 50) {
      throw const OnlineProtocolException(
        OnlineProtocolError.invalidField,
        'noCapturePly must be between 0 and 50',
      );
    }
    final revision = _requiredInt(json, 'revision');
    _validateRevision(revision, 'revision');

    return OnlineGameState._(
      board: _boardFromJson(json),
      currentTurn: _enumByName(
        OnlinePieceColor.values,
        _requiredString(json, 'currentTurn'),
        'currentTurn',
      ),
      status: status,
      winner: winner,
      endReason: endReason,
      moveHistory: _recordedMovesFromJson(json),
      noCapturePly: noCapturePly,
      revision: revision,
    );
  }
}

sealed class OnlineMoveDecision {
  final int protocolVersion;
  final String commandId;

  const OnlineMoveDecision._({
    required this.protocolVersion,
    required this.commandId,
  });

  factory OnlineMoveDecision.fromJson(Map<String, dynamic> json) {
    _validateProtocolVersion(json);
    switch (_requiredString(json, 'type')) {
      case 'committed':
        return OnlineMoveCommitted.fromJson(json);
      case 'rejected':
        return OnlineMoveRejected.fromJson(json);
      default:
        throw OnlineProtocolException(
          OnlineProtocolError.unknownMessageType,
          'Unknown online move decision type: ${json['type']}',
        );
    }
  }
}

class OnlineMoveCommitted extends OnlineMoveDecision {
  final OnlineGameState state;
  final List<Position> capturedPieces;
  final int turnDeadlineEpochMs;

  OnlineMoveCommitted._({
    required super.commandId,
    required this.state,
    required List<Position> capturedPieces,
    required this.turnDeadlineEpochMs,
  })  : capturedPieces = List.unmodifiable(capturedPieces),
        super._(protocolVersion: OnlineProtocol.currentVersion);

  factory OnlineMoveCommitted.fromJson(Map<String, dynamic> json) {
    _validateProtocolVersion(json);
    final capturedPieces = _positionsFromJson(json, 'capturedPieces');
    _validateCapturedPieces(capturedPieces);
    return OnlineMoveCommitted._(
      commandId: _requiredString(json, 'commandId'),
      state: OnlineGameState.fromJson(_requiredMap(json, 'state')),
      capturedPieces: capturedPieces,
      turnDeadlineEpochMs: _requiredEpochMs(json, 'turnDeadlineEpochMs'),
    );
  }
}

class OnlineMoveRejected extends OnlineMoveDecision {
  final OnlineMoveRejectionReason reason;
  final int currentRevision;

  OnlineMoveRejected._({
    required super.commandId,
    required this.reason,
    required this.currentRevision,
  }) : super._(protocolVersion: OnlineProtocol.currentVersion);

  factory OnlineMoveRejected.fromJson(Map<String, dynamic> json) {
    _validateProtocolVersion(json);
    final currentRevision = _requiredInt(json, 'currentRevision');
    _validateRevision(currentRevision, 'currentRevision');
    return OnlineMoveRejected._(
      commandId: _requiredString(json, 'commandId'),
      reason: _enumByWireName(
        OnlineMoveRejectionReason.values,
        _requiredString(json, 'reason'),
        'reason',
        (reason) => reason.wireName,
      ),
      currentRevision: currentRevision,
    );
  }
}

/// Full server state used after matching, reconnecting, or detecting a gap.
class OnlineStateSnapshot {
  final int protocolVersion;
  final String matchId;
  final OnlinePieceColor color;
  final OnlineGameState state;
  final int turnDeadlineEpochMs;
  final bool opponentConnected;
  final int? opponentReconnectDeadlineEpochMs;

  OnlineStateSnapshot._({
    required this.matchId,
    required this.color,
    required this.state,
    required this.turnDeadlineEpochMs,
    required this.opponentConnected,
    required this.opponentReconnectDeadlineEpochMs,
  }) : protocolVersion = OnlineProtocol.currentVersion;

  factory OnlineStateSnapshot.fromJson(Map<String, dynamic> json) {
    _validateProtocolVersion(json);
    return OnlineStateSnapshot._(
      matchId: _requiredString(json, 'matchId'),
      color: _enumByName(
        OnlinePieceColor.values,
        _requiredString(json, 'color'),
        'color',
      ),
      state: OnlineGameState.fromJson(_requiredMap(json, 'state')),
      turnDeadlineEpochMs: _requiredEpochMs(json, 'turnDeadlineEpochMs'),
      opponentConnected: _requiredBool(json, 'opponentConnected'),
      opponentReconnectDeadlineEpochMs: _optionalEpochMs(
        json,
        'opponentReconnectDeadlineEpochMs',
      ),
    );
  }
}

void _validateProtocolVersion(Map<String, dynamic> json) {
  final version = json['protocolVersion'];
  if (version == null) {
    throw const OnlineProtocolException(
      OnlineProtocolError.missingProtocolVersion,
      'protocolVersion is required',
    );
  }
  if (version is! int || version != OnlineProtocol.currentVersion) {
    throw OnlineProtocolException(
      OnlineProtocolError.unsupportedProtocolVersion,
      'Unsupported protocolVersion: $version',
    );
  }
}

void _validateIdentifier(String value, String field) {
  if (value.isEmpty ||
      value.length > 128 ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be a safe identifier of at most 128 characters',
    );
  }
}

void _validateRevision(int value, String field) {
  if (value < 0) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be non-negative',
    );
  }
}

void _validatePosition(Position position, String field) {
  if (!position.isValid()) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be on the 4x4 board',
    );
  }
}

void _validateCapturedPieces(List<Position> positions) {
  if (positions.length > 2 || positions.toSet().length != positions.length) {
    throw const OnlineProtocolException(
      OnlineProtocolError.invalidField,
      'capturedPieces must contain at most two unique positions',
    );
  }
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw OnlineProtocolException(
      OnlineProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! String || value.trim().isEmpty) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be a non-blank string',
    );
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw OnlineProtocolException(
      OnlineProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! int) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be an integer',
    );
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw OnlineProtocolException(
      OnlineProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! bool) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be a boolean',
    );
  }
  return value;
}

int _requiredEpochMs(Map<String, dynamic> json, String field) {
  final value = _requiredInt(json, field);
  if (value < 0) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be non-negative',
    );
  }
  return value;
}

int? _optionalEpochMs(Map<String, dynamic> json, String field) {
  if (json[field] == null) return null;
  return _requiredEpochMs(json, field);
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value == null) {
    throw OnlineProtocolException(
      OnlineProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! Map<String, dynamic>) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be an object',
    );
  }
  return value;
}

List<dynamic> _requiredList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) {
    throw OnlineProtocolException(
      OnlineProtocolError.missingField,
      '$field is required',
    );
  }
  if (value is! List<dynamic>) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be an array',
    );
  }
  return value;
}

Position _positionFromJson(Map<String, dynamic> json, String field) {
  final position = Position(
    _requiredInt(json, 'x'),
    _requiredInt(json, 'y'),
  );
  _validatePosition(position, field);
  return position;
}

Map<String, int> _positionToJson(Position position) => {
      'x': position.x,
      'y': position.y,
    };

List<Position> _positionsFromJson(
  Map<String, dynamic> json,
  String field,
) {
  return _requiredList(json, field).map((item) {
    if (item is! Map<String, dynamic>) {
      throw OnlineProtocolException(
        OnlineProtocolError.invalidField,
        '$field entries must be objects',
      );
    }
    return _positionFromJson(item, field);
  }).toList(growable: false);
}

List<List<OnlinePieceColor?>> _boardFromJson(Map<String, dynamic> json) {
  final rows = _requiredList(json, 'board');
  if (rows.length != 4) {
    throw const OnlineProtocolException(
      OnlineProtocolError.invalidField,
      'board must contain four rows',
    );
  }
  return rows.map((row) {
    if (row is! List<dynamic> || row.length != 4) {
      throw const OnlineProtocolException(
        OnlineProtocolError.invalidField,
        'each board row must contain four cells',
      );
    }
    return row.map((cell) {
      if (cell == null) return null;
      return _enumByName(
        OnlinePieceColor.values,
        cell,
        'board cell',
      );
    }).toList(growable: false);
  }).toList(growable: false);
}

List<OnlineRecordedMove> _recordedMovesFromJson(
  Map<String, dynamic> json,
) {
  return _requiredList(json, 'moveHistory').map((item) {
    if (item is! Map<String, dynamic>) {
      throw const OnlineProtocolException(
        OnlineProtocolError.invalidField,
        'moveHistory entries must be objects',
      );
    }
    return OnlineRecordedMove.fromJson(item);
  }).toList(growable: false);
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? value,
  String field,
) {
  if (value is! String) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be a string',
    );
  }
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw OnlineProtocolException(
    OnlineProtocolError.invalidField,
    'Unknown $field: $value',
  );
}

T _enumByWireName<T extends Enum>(
  List<T> values,
  String value,
  String field,
  String Function(T value) wireName,
) {
  for (final candidate in values) {
    if (wireName(candidate) == value) return candidate;
  }
  throw OnlineProtocolException(
    OnlineProtocolError.invalidField,
    'Unknown $field: $value',
  );
}

T? _optionalEnumByName<T extends Enum>(
  List<T> values,
  Object? value,
  String field,
) {
  if (value == null) return null;
  return _enumByName(values, value, field);
}

T? _optionalEnumByWireName<T extends Enum>(
  List<T> values,
  Object? value,
  String field,
  String Function(T value) wireName,
) {
  if (value == null) return null;
  if (value is! String) {
    throw OnlineProtocolException(
      OnlineProtocolError.invalidField,
      '$field must be a string or null',
    );
  }
  return _enumByWireName(values, value, field, wireName);
}
