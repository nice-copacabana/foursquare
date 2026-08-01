import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ai/voice_game_intent.dart';
import 'package:foursquare/models/position.dart';

void main() {
  test('single coordinate becomes a position intent', () {
    final intent = VoiceGameIntentParser.parse('横一竖二');

    expect(intent, isA<VoicePositionIntent>());
    expect(
      (intent! as VoicePositionIntent).position,
      const Position(0, 1),
    );
  });

  test('one sentence move keeps both coordinates', () {
    final intent = VoiceGameIntentParser.parse('从A1移动到A2');

    expect(intent, isA<VoiceMoveIntent>());
    final move = intent! as VoiceMoveIntent;
    expect(move.from, const Position(0, 0));
    expect(move.to, const Position(0, 1));
  });

  test('traditional coordinate move keeps both coordinates', () {
    final intent = VoiceGameIntentParser.parse(
      '将横一竖一移到横四竖四',
    );

    expect(
      intent,
      const VoiceMoveIntent(
        from: Position(0, 0),
        to: Position(3, 3),
      ),
    );
  });

  for (final testCase in [
    ('取消选择', VoiceGameAction.cancelSelection),
    ('重复一遍', VoiceGameAction.repeat),
    ('暂停', VoiceGameAction.pause),
    ('继续', VoiceGameAction.resume),
    ('继续对局', VoiceGameAction.resume),
    ('退出语音模式', VoiceGameAction.exit),
    ('确认退出', VoiceGameAction.confirmExit),
    ('取消退出', VoiceGameAction.cancelExit),
    ('重试', VoiceGameAction.retry),
    ('我的棋子在哪', VoiceGameAction.myPieces),
    ('对方棋子在哪', VoiceGameAction.opponentPieces),
    ('还剩几个', VoiceGameAction.pieceCount),
    ('可以走哪', VoiceGameAction.availableMoves),
  ]) {
    test('parses ${testCase.$1} as a typed action', () {
      final intent = VoiceGameIntentParser.parse(testCase.$1);

      expect(intent, isA<VoiceActionIntent>());
      expect((intent! as VoiceActionIntent).action, testCase.$2);
    });
  }

  test('ambiguous center is not converted into an intent', () {
    expect(VoiceGameIntentParser.parse('移动到中间'), isNull);
  });

  test('move without a source stays a single position intent', () {
    expect(
      VoiceGameIntentParser.parse('移动到A2'),
      const VoicePositionIntent(Position(0, 1)),
    );
  });

  for (final unsafeText in [
    '不要移动到A2',
    'A1到A2',
    '从A1移动到A2再到A3',
    'A1然后退出',
    '确认，退出',
    '继续，对局',
  ]) {
    test('rejects non-whitelisted sentence: $unsafeText', () {
      expect(VoiceGameIntentParser.parse(unsafeText), isNull);
    });
  }
}
