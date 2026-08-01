import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/bloc/game_event.dart';
import 'package:foursquare/bloc/meditation_mode_event.dart';
import 'package:foursquare/bloc/meditation_mode_state.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/piece_type.dart';
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

  test('ordinary voice command event string does not expose command text', () {
    const event = VoiceCommandReceivedEvent(command: secret);

    expect(event.toString(), isNot(contains(secret)));
  });

  test('meditation event and processing state strings hide recognized text',
      () {
    const event = VoiceInputReceived(
      recognizedText: secret,
      confidence: 0.9,
    );
    final state = ProcessingVoiceCommand(
      recognizedText: secret,
      confidence: 0.9,
      board: BoardState.initial(),
      currentPlayer: PieceType.black,
    );

    expect(event.toString(), isNot(contains(secret)));
    expect(state.toString(), isNot(contains(secret)));
  });
}
