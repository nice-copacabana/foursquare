import 'package:equatable/equatable.dart';

import '../models/position.dart';
import 'voice_command_parser.dart';

/// A typed game-facing intent produced from one final voice result.
sealed class VoiceGameIntent extends Equatable {
  const VoiceGameIntent();
}

final class VoicePositionIntent extends VoiceGameIntent {
  final Position position;

  const VoicePositionIntent(this.position);

  @override
  List<Object?> get props => [position];
}

final class VoiceMoveIntent extends VoiceGameIntent {
  final Position from;
  final Position to;

  const VoiceMoveIntent({required this.from, required this.to});

  @override
  List<Object?> get props => [from, to];
}

enum VoiceGameAction {
  cancelSelection,
  repeat,
  pause,
  resume,
  exit,
  confirmExit,
  cancelExit,
  retry,
  myPieces,
  opponentPieces,
  pieceCount,
  availableMoves,
}

final class VoiceActionIntent extends VoiceGameIntent {
  final VoiceGameAction action;

  const VoiceActionIntent(this.action);

  @override
  List<Object?> get props => [action];
}

/// Converts recognition text into a small set of game-neutral intents.
///
/// It only recognizes syntax. Move legality remains the responsibility of the
/// game BLoC and engine.
class VoiceGameIntentParser {
  static const String _coordinateSource =
      r'(?:[a-d][1-4]|横[一二三四1234]竖[一二三四1234]|'
      r'行[一二三四1234]列[一二三四1234]|左上|右上|左下|右下)';
  static final RegExp _singlePosition = RegExp(
    '^(?:移动到|移到|选择|选中)?($_coordinateSource)\$',
  );
  static final RegExp _move = RegExp(
    '^(?:从|将)($_coordinateSource)(?:移动到|移到|到)'
    '($_coordinateSource)\$',
  );

  static const Map<String, VoiceGameAction> _actions = {
    '取消': VoiceGameAction.cancelSelection,
    '取消选择': VoiceGameAction.cancelSelection,
    '重复': VoiceGameAction.repeat,
    '重复一遍': VoiceGameAction.repeat,
    '再说一遍': VoiceGameAction.repeat,
    '暂停': VoiceGameAction.pause,
    '继续': VoiceGameAction.resume,
    '恢复': VoiceGameAction.resume,
    '退出': VoiceGameAction.exit,
    '退出语音': VoiceGameAction.exit,
    '退出语音模式': VoiceGameAction.exit,
    '确认': VoiceGameAction.confirmExit,
    '确认退出': VoiceGameAction.confirmExit,
    '确定退出': VoiceGameAction.confirmExit,
    '取消退出': VoiceGameAction.cancelExit,
    '继续对局': VoiceGameAction.resume,
    '重试': VoiceGameAction.retry,
    '请重试': VoiceGameAction.retry,
    '我的棋子在哪': VoiceGameAction.myPieces,
    '我的棋子在哪里': VoiceGameAction.myPieces,
    '对方棋子在哪': VoiceGameAction.opponentPieces,
    '对方棋子在哪里': VoiceGameAction.opponentPieces,
    '还剩几个': VoiceGameAction.pieceCount,
    '剩几个棋子': VoiceGameAction.pieceCount,
    '可以走哪': VoiceGameAction.availableMoves,
    '可以走哪里': VoiceGameAction.availableMoves,
  };

  static VoiceGameIntent? parse(String text) {
    var cleaned = text.trim().toLowerCase();
    cleaned = cleaned
        .replaceFirst(RegExp(r'^[，,。.!！?？]+'), '')
        .replaceFirst(RegExp(r'[，,。.!！?？]+$'), '');
    if (RegExp(r'[，,。.!！?？]').hasMatch(cleaned)) {
      return null;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty) {
      return null;
    }

    final action = _actions[cleaned];
    if (action != null) {
      return VoiceActionIntent(action);
    }

    final move = _parseMove(cleaned);
    if (move != null) {
      return move;
    }

    final positionMatch = _singlePosition.firstMatch(cleaned);
    if (positionMatch == null) {
      return null;
    }
    final position = VoiceCommandParser.parse(positionMatch.group(1)!);
    return position == null ? null : VoicePositionIntent(position);
  }

  static VoiceMoveIntent? _parseMove(String text) {
    final match = _move.firstMatch(text);
    if (match == null) {
      return null;
    }

    final from = VoiceCommandParser.parse(match.group(1)!);
    final to = VoiceCommandParser.parse(match.group(2)!);
    if (from == null || to == null) {
      return null;
    }

    return VoiceMoveIntent(from: from, to: to);
  }
}
