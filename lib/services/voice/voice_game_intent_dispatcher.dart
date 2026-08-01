import '../../ai/voice_game_intent.dart';
import '../../bloc/game_event.dart';

/// Thin boundary from typed voice intents to the existing game event API.
///
/// It never validates moves and never creates AI-authorized moves.
final class VoiceGameIntentDispatcher {
  final void Function(GameEvent) _addGameEvent;
  final void Function(VoiceGameAction) _onControlAction;

  const VoiceGameIntentDispatcher({
    required void Function(GameEvent) addGameEvent,
    required void Function(VoiceGameAction) onControlAction,
  })  : _addGameEvent = addGameEvent,
        _onControlAction = onControlAction;

  void dispatch(VoiceGameIntent intent) {
    switch (intent) {
      case VoicePositionIntent(:final position):
        _addGameEvent(ActivateBoardPositionEvent(position));
      case VoiceMoveIntent(:final from, :final to):
        _addGameEvent(MovePieceEvent(from: from, to: to));
      case VoiceActionIntent(action: VoiceGameAction.cancelSelection):
        _addGameEvent(const DeselectPieceEvent());
      case VoiceActionIntent(:final action):
        _onControlAction(action);
    }
  }
}
