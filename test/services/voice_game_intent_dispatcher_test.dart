import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ai/voice_game_intent.dart';
import 'package:foursquare/bloc/game_event.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/voice/voice_game_intent_dispatcher.dart';

void main() {
  late List<GameEvent> gameEvents;
  late List<VoiceGameAction> controlActions;
  late VoiceGameIntentDispatcher dispatcher;

  setUp(() {
    gameEvents = [];
    controlActions = [];
    dispatcher = VoiceGameIntentDispatcher(
      addGameEvent: gameEvents.add,
      onControlAction: controlActions.add,
    );
  });

  test('a position uses the source-neutral board activation event', () {
    dispatcher.dispatch(const VoicePositionIntent(Position(1, 2)));

    expect(
      gameEvents,
      [const ActivateBoardPositionEvent(Position(1, 2))],
    );
    expect(controlActions, isEmpty);
  });

  test('an explicit move can never be marked as an AI move', () {
    dispatcher.dispatch(
      const VoiceMoveIntent(
        from: Position(0, 0),
        to: Position(0, 1),
      ),
    );

    final event = gameEvents.single as MovePieceEvent;
    expect(event.from, const Position(0, 0));
    expect(event.to, const Position(0, 1));
    expect(event.isAIMove, isFalse);
  });

  test('cancel selection maps to the existing game event', () {
    dispatcher.dispatch(
      const VoiceActionIntent(VoiceGameAction.cancelSelection),
    );

    expect(gameEvents, [const DeselectPieceEvent()]);
    expect(controlActions, isEmpty);
  });

  for (final action in [
    VoiceGameAction.repeat,
    VoiceGameAction.pause,
    VoiceGameAction.resume,
    VoiceGameAction.exit,
  ]) {
    test('${action.name} remains a voice lifecycle action', () {
      dispatcher.dispatch(VoiceActionIntent(action));

      expect(gameEvents, isEmpty);
      expect(controlActions, [action]);
    });
  }
}
