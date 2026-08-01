import 'package:permission_handler/permission_handler.dart';

import 'voice_ports.dart';

typedef PermissionStatusOperation = Future<PermissionStatus> Function();

/// Runtime microphone permission boundary for the hidden voice feature.
///
/// Construction is side-effect free. The platform is touched only when the
/// controller checks or requests permission after the disclosure flow.
final class PermissionHandlerMicrophonePort
    implements MicrophonePermissionPort {
  final PermissionStatusOperation _readStatus;
  final PermissionStatusOperation _requestStatus;

  PermissionHandlerMicrophonePort({
    PermissionStatusOperation? readStatus,
    PermissionStatusOperation? requestStatus,
  })  : _readStatus = readStatus ?? _readMicrophoneStatus,
        _requestStatus = requestStatus ?? _requestMicrophoneStatus;

  @override
  Future<VoicePermissionStatus> check() async =>
      _mapStatus(await _readStatus());

  @override
  Future<VoicePermissionStatus> request() async =>
      _mapStatus(await _requestStatus());

  static VoicePermissionStatus _mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => VoicePermissionStatus.granted,
      PermissionStatus.denied => VoicePermissionStatus.denied,
      PermissionStatus.permanentlyDenied =>
        VoicePermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => VoicePermissionStatus.restricted,
      PermissionStatus.limited ||
      PermissionStatus.provisional =>
        VoicePermissionStatus.denied,
    };
  }

  static Future<PermissionStatus> _readMicrophoneStatus() =>
      Permission.microphone.status;

  static Future<PermissionStatus> _requestMicrophoneStatus() =>
      Permission.microphone.request();

  @override
  String toString() => 'PermissionHandlerMicrophonePort()';
}
