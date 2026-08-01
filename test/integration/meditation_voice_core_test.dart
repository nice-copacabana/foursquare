import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ai/ai_player.dart';
import 'package:foursquare/ai/voice_game_intent.dart';
import 'package:foursquare/meditation/meditation_intent_handler.dart';
import 'package:foursquare/meditation/meditation_session.dart';
import 'package:foursquare/meditation/meditation_session_controller.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/voice/voice_interaction_controller.dart';
import 'package:foursquare/services/voice/voice_ports.dart';

void main() {
  test('fake voice ports complete a human and AI turn without a screen',
      () async {
    final order = <String>[];
    final recognition = _ScriptRecognition(order);
    final synthesis = _RecordingSynthesis(order);
    final sessionController = MeditationSessionController.newGame(
      humanPlayer: PieceType.black,
      firstPlayer: PieceType.black,
      now: () => DateTime.utc(2026, 8, 1, 12),
    );
    final handler = MeditationIntentHandler(
      controller: sessionController,
      aiPlayer: _SingleMoveAI(),
    );
    final voice = VoiceInteractionController(
      permission: _GrantedPermission(),
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: (intent) async {
        final response = await handler.handle(intent);
        return VoiceInteractionReply(response.prompt.text);
      },
    );
    addTearDown(voice.dispose);

    await voice.enableAfterDisclosure();
    expect(await voice.announce(handler.openingPrompt().text), isTrue);
    final started = await handler.start();
    expect(await voice.announce(started.prompt.text), isTrue);
    expect(recognition.listenCalls, 0);

    await voice.listenOnce();
    recognition.emitFinal('横一竖一');
    await _waitUntilReady(voice, expectedSpeakCalls: 3, synthesis: synthesis);
    expect(sessionController.session.selectedPosition, const Position(0, 0));

    await voice.listenOnce();
    recognition.emitFinal('横一竖二');
    await _waitUntilReady(voice, expectedSpeakCalls: 4, synthesis: synthesis);

    expect(sessionController.session.moveHistory, hasLength(2));
    expect(sessionController.session.phase, MeditationSessionPhase.humanTurn);
    expect(recognition.listenCalls, 2);
    expect(synthesis.spoken.last, contains('您从横一竖一移动到横一竖二'));
    expect(synthesis.spoken.last, contains('对手从横一竖四移动到横一竖三'));
    expect(
      order.indexOf('recognition.stop.2'),
      lessThan(order.indexOf('synthesis.speak.4')),
    );
    expect(voice.state.toString(), isNot(contains('横一竖二')));
  });

  test('opening clock waits until a failed announcement is replayed', () async {
    final order = <String>[];
    final synthesis = _RecordingSynthesis(order)..failuresRemaining = 1;
    final sessionController = MeditationSessionController.newGame(
      humanPlayer: PieceType.black,
      firstPlayer: PieceType.black,
      now: () => DateTime.utc(2026, 8, 1, 12),
    );
    final handler = MeditationIntentHandler(
      controller: sessionController,
      aiPlayer: _SingleMoveAI(),
    );
    final voice = VoiceInteractionController(
      permission: _GrantedPermission(),
      recognition: _ScriptRecognition(order),
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: (_) => null,
    );
    addTearDown(voice.dispose);
    await voice.enableAfterDisclosure();

    expect(await voice.announce(handler.openingPrompt().text), isFalse);
    expect(sessionController.session.phase, MeditationSessionPhase.opening);
    expect(sessionController.session.turnClock, isNull);

    expect(await voice.replayPendingReply(), isTrue);
    await handler.start();

    expect(sessionController.session.phase, MeditationSessionPhase.humanTurn);
    expect(sessionController.session.turnClock, isNotNull);
  });
}

Future<void> _waitUntilReady(
  VoiceInteractionController voice, {
  required int expectedSpeakCalls,
  required _RecordingSynthesis synthesis,
}) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (voice.state.phase == VoiceInteractionPhase.ready &&
        synthesis.spoken.length == expectedSpeakCalls) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Voice loop did not settle: state=${voice.state}, '
    'speakCalls=${synthesis.spoken.length}',
  );
}

final class _GrantedPermission implements MicrophonePermissionPort {
  @override
  Future<VoicePermissionStatus> check() async => VoicePermissionStatus.granted;

  @override
  Future<VoicePermissionStatus> request() async =>
      VoicePermissionStatus.granted;
}

final class _ScriptRecognition implements VoiceRecognitionPort {
  final List<String> order;
  int listenCalls = 0;
  int stopCalls = 0;
  void Function(VoiceRecognitionSample sample)? _onSample;

  _ScriptRecognition(this.order);

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> listenOnce({
    required void Function(VoiceRecognitionSample sample) onSample,
    required void Function(VoicePortFailure failure) onFailure,
  }) async {
    listenCalls += 1;
    order.add('recognition.listen.$listenCalls');
    _onSample = onSample;
  }

  void emitFinal(String text) {
    _onSample?.call(
      VoiceRecognitionSample(
        text: text,
        confidence: 0.95,
        isFinal: true,
      ),
    );
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    order.add('recognition.stop.$stopCalls');
  }

  @override
  Future<void> dispose() async {}
}

final class _RecordingSynthesis implements VoiceSynthesisPort {
  final List<String> order;
  final List<String> spoken = [];
  int failuresRemaining = 0;

  _RecordingSynthesis(this.order);

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    order.add('synthesis.speak.${spoken.length}');
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('synthetic TTS failure');
    }
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _SingleMoveAI extends AIPlayer {
  _SingleMoveAI() : super(AIDifficulty.easy);

  @override
  Future<AIMoveResult?> selectMove(BoardState board) async {
    return const AIMoveResult(
      from: Position(0, 3),
      to: Position(0, 2),
      score: 1,
    );
  }

  @override
  String get name => 'Single move AI';

  @override
  String get description => 'Deterministic integration AI';
}
