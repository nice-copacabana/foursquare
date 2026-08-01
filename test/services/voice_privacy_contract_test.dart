import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/meditation/meditation_intent_handler.dart';
import 'package:foursquare/services/voice/voice_interaction_controller.dart';
import 'package:foursquare/services/voice/voice_ports.dart';
import 'package:foursquare/services/voice_recognition_service.dart';

void main() {
  const secret = '不要写入日志的语音原文';

  test('recognition result string does not expose recognized text', () {
    final result = VoiceRecognitionResult(
      text: secret,
      confidence: 0.9,
      isFinal: true,
      timestamp: DateTime(2026),
    );

    expect(result.toString(), isNot(contains(secret)));
  });

  test('ordinary recognition sample string does not expose command text', () {
    const sample = VoiceRecognitionSample(
      text: secret,
      confidence: 0.9,
      isFinal: true,
    );

    expect(sample.toString(), isNot(contains(secret)));
  });

  test('voice and meditation response strings hide spoken text', () {
    const reply = VoiceInteractionReply(secret);
    const prompt = MeditationPrompt(secret);
    const response = MeditationTurnResponse(
      prompt: prompt,
      exitConfirmationRequested: true,
    );
    const state = VoiceInteractionState(
      VoiceInteractionPhase.ready,
      failure: VoicePortFailure.synthesisFailed,
    );

    expect(reply.toString(), isNot(contains(secret)));
    expect(prompt.toString(), isNot(contains(secret)));
    expect(response.toString(), isNot(contains(secret)));
    expect(state.toString(), isNot(contains(secret)));
  });
}
