import '../ai/ai_player.dart';
import '../engine/move_validator.dart';
import '../models/game_result.dart';
import '../models/game_save.dart';
import '../models/piece_type.dart';
import '../models/position.dart';
import '../services/turn_clock.dart';
import 'meditation_session.dart';
import 'meditation_session_controller.dart';

/// Versioned, speech-free persistence document for one meditation session.
final class MeditationSessionSnapshot {
  static const int currentSchemaVersion = 1;
  static const String recordType = 'meditation_session';

  final MeditationSession session;
  final int? _remainingMilliseconds;

  const MeditationSessionSnapshot._(
    this.session,
    this._remainingMilliseconds,
  );

  factory MeditationSessionSnapshot.capture(
    MeditationSession session, {
    required DateTime now,
  }) {
    final clock = session.turnClock;
    final remaining = clock?.remainingAt(now);
    if (remaining != null &&
        (remaining.isNegative ||
            remaining > TurnClock.defaultTurnDuration ||
            (clock!.isPaused && remaining == Duration.zero))) {
      throw StateError('Meditation clock is not persistable');
    }
    return MeditationSessionSnapshot._(
      session,
      remaining?.inMilliseconds,
    );
  }

  factory MeditationSessionSnapshot.fromJson(Map<String, dynamic> json) {
    try {
      if (json['schemaVersion'] != currentSchemaVersion) {
        throw const FormatException('Unsupported meditation snapshot version');
      }
      if (json['recordType'] != recordType) {
        throw const FormatException('Unexpected meditation record type');
      }

      final startedAt = _dateTime(json['startedAt'], 'startedAt');
      final firstPlayer = _player(json['firstPlayer'], 'firstPlayer');
      final humanPlayer = _player(json['humanPlayer'], 'humanPlayer');
      final currentPlayer = _player(json['currentPlayer'], 'currentPlayer');
      final aiDifficulty = _enumByName(
        AIDifficulty.values,
        json['aiDifficulty'],
        'aiDifficulty',
      );
      final boardJson = _map(json['boardState'], 'boardState');
      _validateBoardJson(boardJson);
      final boardState = BoardStateData.fromJson(
        boardJson,
      ).toBoardState(currentPlayer);
      final movesJson = _list(json['moveHistory'], 'moveHistory');
      final moveHistory = movesJson.map((raw) {
        final moveJson = _map(raw, 'moveHistory item');
        _validateMoveJson(moveJson);
        return MoveData.fromJson(moveJson).toMove();
      }).toList(growable: false);
      final selectedPosition = json['selectedPosition'] == null
          ? null
          : _position(json['selectedPosition'], 'selectedPosition');
      final validMoves = selectedPosition == null
          ? const <Position>[]
          : MoveValidator().getValidMoves(boardState, selectedPosition);
      final gameResult = json['gameResult'] == null
          ? null
          : GameResult.fromJson(_map(json['gameResult'], 'gameResult'));
      final decodedClock = _decodeClock(
        json,
        anchor: startedAt,
        gameResult: gameResult,
      );
      final session = MeditationSession(
        matchId: _nonEmptyString(json['matchId'], 'matchId'),
        startedAt: startedAt,
        boardState: boardState,
        firstPlayer: firstPlayer,
        humanPlayer: humanPlayer,
        aiDifficulty: aiDifficulty,
        moveHistory: moveHistory,
        noCapturePlyCount: _nonNegativeInt(
          json['noCapturePlyCount'],
          'noCapturePlyCount',
        ),
        turnClock: decodedClock.clock,
        selectedPosition: selectedPosition,
        validMoves: validMoves,
        gameResult: gameResult,
        revision: _nonNegativeInt(json['revision'], 'revision'),
      );
      _validateClockState(json['clockState'], session.phase);
      return MeditationSessionSnapshot._(
        session,
        decodedClock.remainingMilliseconds,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid meditation snapshot', error);
    }
  }

  Map<String, dynamic> toJson() {
    final phase = session.phase;
    final clockState = switch (phase) {
      MeditationSessionPhase.opening => 'opening',
      MeditationSessionPhase.paused => 'paused',
      MeditationSessionPhase.completed => 'completed',
      MeditationSessionPhase.humanTurn ||
      MeditationSessionPhase.aiTurn =>
        'active',
    };
    return {
      'schemaVersion': currentSchemaVersion,
      'recordType': recordType,
      'matchId': session.matchId,
      'startedAt': session.startedAt.toUtc().toIso8601String(),
      'firstPlayer': session.firstPlayer.name,
      'humanPlayer': session.humanPlayer.name,
      'currentPlayer': session.currentPlayer.name,
      'aiDifficulty': session.aiDifficulty.name,
      'boardState': BoardStateData.fromBoardState(session.boardState).toJson(),
      'moveHistory': session.moveHistory
          .map((move) => MoveData.fromMove(move).toJson())
          .toList(growable: false),
      'noCapturePlyCount': session.noCapturePlyCount,
      'clockState': clockState,
      'remainingMilliseconds': _remainingMilliseconds,
      'selectedPosition': session.selectedPosition == null
          ? null
          : PositionData.fromPosition(session.selectedPosition!).toJson(),
      'gameResult': session.gameResult?.toJson(),
      'revision': session.revision,
    };
  }

  MeditationSessionController restoreController({DateTime Function()? now}) {
    final clock = now ?? DateTime.now;
    final restoredAt = clock();
    final phase = session.phase;
    final duration = Duration(milliseconds: _remainingMilliseconds ?? 0);
    final restoredSession = switch (phase) {
      MeditationSessionPhase.humanTurn ||
      MeditationSessionPhase.aiTurn =>
        session.copyWith(
          turnClock: TurnClock.started(restoredAt, turnDuration: duration),
        ),
      MeditationSessionPhase.paused => session.copyWith(
          turnClock: TurnClock.paused(duration),
        ),
      MeditationSessionPhase.opening ||
      MeditationSessionPhase.completed =>
        session,
    };
    return MeditationSessionController.restore(restoredSession, now: clock);
  }

  static ({TurnClock? clock, int? remainingMilliseconds}) _decodeClock(
    Map<String, dynamic> json, {
    required DateTime anchor,
    required GameResult? gameResult,
  }) {
    final state = json['clockState'];
    switch (state) {
      case 'opening':
      case 'completed':
        if (json['remainingMilliseconds'] != null) {
          throw const FormatException('Clockless snapshot has clock data');
        }
        if (state == 'opening' && gameResult != null ||
            state == 'completed' && gameResult == null) {
          throw const FormatException('Clock state contradicts result');
        }
        return (clock: null, remainingMilliseconds: null);
      case 'active':
        final milliseconds = _nonNegativeInt(
          json['remainingMilliseconds'],
          'remainingMilliseconds',
        );
        if (milliseconds > TurnClock.defaultTurnDuration.inMilliseconds) {
          throw const FormatException('Active clock exceeds turn duration');
        }
        return (
          clock: TurnClock.started(
            anchor,
            turnDuration: Duration(milliseconds: milliseconds),
          ),
          remainingMilliseconds: milliseconds,
        );
      case 'paused':
        final milliseconds = _positiveInt(
          json['remainingMilliseconds'],
          'remainingMilliseconds',
        );
        if (milliseconds > TurnClock.defaultTurnDuration.inMilliseconds) {
          throw const FormatException('Paused clock exceeds turn duration');
        }
        return (
          clock: TurnClock.paused(Duration(milliseconds: milliseconds)),
          remainingMilliseconds: milliseconds,
        );
      default:
        throw const FormatException('Unknown meditation clock state');
    }
  }

  static void _validateClockState(
    Object? encoded,
    MeditationSessionPhase phase,
  ) {
    final valid = switch (phase) {
      MeditationSessionPhase.opening => encoded == 'opening',
      MeditationSessionPhase.paused => encoded == 'paused',
      MeditationSessionPhase.completed => encoded == 'completed',
      MeditationSessionPhase.humanTurn ||
      MeditationSessionPhase.aiTurn =>
        encoded == 'active',
    };
    if (!valid) {
      throw const FormatException('Clock state contradicts session phase');
    }
  }

  static void _validateBoardJson(Map<String, dynamic> json) {
    final grid = _list(json['grid'], 'boardState.grid');
    if (grid.length != 4) {
      throw const FormatException('Board must have four rows');
    }
    for (final rawRow in grid) {
      final row = _list(rawRow, 'boardState row');
      if (row.length != 4 ||
          row.any(
            (cell) => cell != 'black' && cell != 'white' && cell != 'empty',
          )) {
        throw const FormatException('Board row is invalid');
      }
    }
    for (final key in ['blackPieces', 'whitePieces']) {
      for (final raw in _list(json[key], 'boardState.$key')) {
        _position(raw, 'boardState.$key item');
      }
    }
  }

  static void _validateMoveJson(Map<String, dynamic> json) {
    _position(json['from'], 'move.from');
    _position(json['to'], 'move.to');
    _player(json['player'], 'move.player');
    _dateTime(json['timestamp'], 'move.timestamp');
    for (final raw in _list(json['capturedPositions'], 'capturedPositions')) {
      _position(raw, 'capturedPositions item');
    }
  }

  static Position _position(Object? raw, String field) {
    final json = _map(raw, field);
    final x = json['x'];
    final y = json['y'];
    if (x is! int || y is! int) {
      throw FormatException('$field must contain integer coordinates');
    }
    final position = Position(x, y);
    if (!position.isValid()) {
      throw FormatException('$field is outside the board');
    }
    return position;
  }

  static PieceType _player(Object? raw, String field) {
    final player = _enumByName(PieceType.values, raw, field);
    if (!player.isPlayer()) {
      throw FormatException('$field cannot be empty');
    }
    return player;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? raw,
    String field,
  ) {
    if (raw is! String) {
      throw FormatException('$field must be a string');
    }
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    throw FormatException('$field has an unknown value');
  }

  static Map<String, dynamic> _map(Object? raw, String field) {
    if (raw is! Map) {
      throw FormatException('$field must be an object');
    }
    try {
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      throw FormatException('$field must use string keys');
    }
  }

  static List<dynamic> _list(Object? raw, String field) {
    if (raw is! List) {
      throw FormatException('$field must be a list');
    }
    return raw;
  }

  static String _nonEmptyString(Object? raw, String field) {
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('$field must be a non-empty string');
    }
    return raw;
  }

  static DateTime _dateTime(Object? raw, String field) {
    if (raw is! String) {
      throw FormatException('$field must be an ISO timestamp');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('$field must be an ISO timestamp');
    }
    return parsed.toUtc();
  }

  static int _nonNegativeInt(Object? raw, String field) {
    if (raw is! int || raw < 0) {
      throw FormatException('$field must be a non-negative integer');
    }
    return raw;
  }

  static int _positiveInt(Object? raw, String field) {
    if (raw is! int || raw <= 0) {
      throw FormatException('$field must be a positive integer');
    }
    return raw;
  }
}
