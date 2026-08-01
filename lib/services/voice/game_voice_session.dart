import '../../ai/voice_game_intent.dart';
import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../models/piece_type.dart';
import 'platform_voice_adapters.dart';
import 'voice_game_intent_dispatcher.dart';
import 'voice_interaction_controller.dart';
import 'voice_ports.dart';

export 'voice_interaction_controller.dart'
    show VoiceInteractionPhase, VoiceInteractionState;

typedef GameVoiceSessionFactory = GameVoiceSession Function({
  required GameBloc bloc,
  required PieceType controlledPlayer,
});

/// Voice capability boundary for an already-authoritative ordinary PVE game.
abstract interface class GameVoiceSession {
  VoiceInteractionState get state;

  Stream<VoiceInteractionState> get states;

  bool get canAcceptInput;

  Future<void> enableAfterDisclosure();

  Future<void> listenOnce();

  Future<void> updateAvailability({required bool appIsActive});

  Future<void> dispose();
}

/// Sends typed position intents into [GameBloc] without claiming an outcome.
///
/// Ordinary-game narration needs a separate committed-outcome boundary. Until
/// that exists, this session deliberately returns no success speech and ignores
/// control actions whose product semantics have not been defined for PVE.
final class BlocGameVoiceSession implements GameVoiceSession {
  final GameBloc _bloc;
  final PieceType _controlledPlayer;
  late final VoiceInteractionController _voice;
  late final VoiceGameIntentDispatcher _dispatcher;
  Future<void>? _enableOperation;
  Future<void> _availabilityUpdates = Future<void>.value();
  bool _appIsActive = true;

  BlocGameVoiceSession({
    required GameBloc bloc,
    required PieceType controlledPlayer,
    required MicrophonePermissionPort permission,
    required VoiceRecognitionPort recognition,
    required VoiceSynthesisPort synthesis,
  })  : _bloc = bloc,
        _controlledPlayer = controlledPlayer {
    _dispatcher = VoiceGameIntentDispatcher(
      addGameEvent: _bloc.add,
      onControlAction: (_) {},
    );
    _voice = VoiceInteractionController(
      permission: permission,
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: _handleIntent,
    );
  }

  @override
  VoiceInteractionState get state => _voice.state;

  @override
  Stream<VoiceInteractionState> get states => _voice.states;

  @override
  bool get canAcceptInput {
    final state = _bloc.state;
    return _appIsActive &&
        state is GamePlaying &&
        state.mode == GameMode.pve &&
        state.humanPlayer == _controlledPlayer &&
        state.currentPlayer == _controlledPlayer &&
        !state.isAIThinking;
  }

  @override
  Future<void> enableAfterDisclosure() async {
    if (!canAcceptInput) return;
    await _runEnable();
    if (!canAcceptInput) await _voice.interrupt();
  }

  @override
  Future<void> listenOnce() async {
    if (!canAcceptInput) {
      await _voice.interrupt();
      return;
    }
    await _voice.listenOnce();
  }

  @override
  Future<void> updateAvailability({required bool appIsActive}) async {
    _appIsActive = appIsActive;
    final requestedActive = appIsActive;
    _availabilityUpdates = _availabilityUpdates.then((_) async {
      if (!requestedActive) {
        await _voice.interrupt();
        return;
      }
      if (!_appIsActive || !canAcceptInput) {
        await _voice.interrupt();
        return;
      }

      final enabling = _enableOperation;
      if (enabling != null) await enabling;
      if (!_appIsActive || !canAcceptInput) return;

      _voice.resume();
      if (_voice.state.phase == VoiceInteractionPhase.interrupted) {
        await _runEnable();
      }
    });
    await _availabilityUpdates;
  }

  @override
  Future<void> dispose() => _voice.dispose();

  VoiceInteractionReply? _handleIntent(VoiceGameIntent intent) {
    if (!canAcceptInput) return null;
    _dispatcher.dispatch(intent);
    return null;
  }

  Future<void> _runEnable() {
    final current = _enableOperation;
    if (current != null) return current;

    late final Future<void> operation;
    operation = _voice.enableAfterDisclosure().whenComplete(() {
      if (identical(_enableOperation, operation)) {
        _enableOperation = null;
      }
    });
    _enableOperation = operation;
    return operation;
  }
}

GameVoiceSession createProductionGameVoiceSession({
  required GameBloc bloc,
  required PieceType controlledPlayer,
}) {
  final adapters = PlatformVoiceAdapters.create();
  return BlocGameVoiceSession(
    bloc: bloc,
    controlledPlayer: controlledPlayer,
    permission: adapters.permission,
    recognition: adapters.recognition,
    synthesis: adapters.synthesis,
  );
}
