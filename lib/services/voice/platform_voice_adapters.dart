export 'flutter_tts_synthesis_adapter.dart';
export 'permission_handler_microphone_adapter.dart';
export 'speech_to_text_recognition_adapter.dart';

import 'flutter_tts_synthesis_adapter.dart';
import 'permission_handler_microphone_adapter.dart';
import 'speech_to_text_recognition_adapter.dart';
import 'voice_ports.dart';

/// Side-effect-free production bundle. Individual plugins stay lazy until the
/// controller reaches their explicit permission or initialization operation.
final class PlatformVoiceAdapters {
  final MicrophonePermissionPort permission;
  final VoiceRecognitionPort recognition;
  final VoiceSynthesisPort synthesis;

  const PlatformVoiceAdapters({
    required this.permission,
    required this.recognition,
    required this.synthesis,
  });

  factory PlatformVoiceAdapters.create({String localeId = 'zh-CN'}) {
    return PlatformVoiceAdapters(
      permission: PermissionHandlerMicrophonePort(),
      recognition: SpeechToTextRecognitionPort(localeId: localeId),
      synthesis: FlutterTtsSynthesisPort(localeId: localeId),
    );
  }
}
