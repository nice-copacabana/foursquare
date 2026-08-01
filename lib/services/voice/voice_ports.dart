enum VoicePermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

enum VoicePortFailure {
  unavailable,
  permissionDenied,
  interrupted,
  recognitionFailed,
  synthesisFailed,
  unrecognized,
}

final class VoiceRecognitionSample {
  final String text;
  final double confidence;
  final bool isFinal;

  const VoiceRecognitionSample({
    required this.text,
    required this.confidence,
    required this.isFinal,
  });

  @override
  String toString() => 'VoiceRecognitionSample(textLength: ${text.length}, '
      'confidence: $confidence, isFinal: $isFinal)';
}

abstract interface class MicrophonePermissionPort {
  Future<VoicePermissionStatus> check();

  Future<VoicePermissionStatus> request();
}

abstract interface class VoiceRecognitionPort {
  Future<bool> initialize();

  Future<void> listenOnce({
    required void Function(VoiceRecognitionSample sample) onSample,
    required void Function(VoicePortFailure failure) onFailure,
  });

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class VoiceSynthesisPort {
  Future<bool> initialize();

  /// Completes only after playback has completed.
  Future<void> speak(String text);

  Future<void> stop();

  Future<void> dispose();
}
