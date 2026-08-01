import 'dart:async';

import '../../ai/voice_game_intent.dart';
import 'voice_ports.dart';

enum VoiceInteractionPhase {
  disabled,
  requestingPermission,
  initializing,
  ready,
  listening,
  processing,
  speaking,
  permissionDenied,
  permissionPermanentlyDenied,
  restricted,
  unavailable,
  interrupted,
  failed,
  disposed,
}

final class VoiceInteractionState {
  final VoiceInteractionPhase phase;
  final VoicePortFailure? failure;

  const VoiceInteractionState(this.phase, {this.failure});

  bool get canListen => phase == VoiceInteractionPhase.ready;

  @override
  String toString() => 'VoiceInteractionState(phase: ${phase.name}, '
      'failure: ${failure?.name})';
}

/// Owns voice permission and audio sequencing, but no game rules.
final class VoiceInteractionController {
  final MicrophonePermissionPort _permission;
  final VoiceRecognitionPort _recognition;
  final VoiceSynthesisPort _synthesis;
  final VoiceGameIntent? Function(String) _interpret;
  final void Function(VoiceGameIntent) _onIntent;
  final StreamController<VoiceInteractionState> _states =
      StreamController<VoiceInteractionState>.broadcast(sync: true);

  VoiceInteractionState _state =
      const VoiceInteractionState(VoiceInteractionPhase.disabled);
  int _generation = 0;
  bool _disposed = false;
  bool _portsReady = false;

  VoiceInteractionController({
    required MicrophonePermissionPort permission,
    required VoiceRecognitionPort recognition,
    required VoiceSynthesisPort synthesis,
    required VoiceGameIntent? Function(String) interpret,
    required void Function(VoiceGameIntent) onIntent,
  })  : _permission = permission,
        _recognition = recognition,
        _synthesis = synthesis,
        _interpret = interpret,
        _onIntent = onIntent;

  VoiceInteractionState get state => _state;

  Stream<VoiceInteractionState> get states => _states.stream;

  Future<void> enableAfterDisclosure() async {
    if (_disposed || _state.phase != VoiceInteractionPhase.disabled) {
      return;
    }

    final generation = ++_generation;
    _emit(
      const VoiceInteractionState(
        VoiceInteractionPhase.requestingPermission,
      ),
    );

    try {
      var permission = await _permission.check();
      if (!_isCurrent(generation)) {
        return;
      }
      if (permission == VoicePermissionStatus.notDetermined ||
          permission == VoicePermissionStatus.denied) {
        permission = await _permission.request();
        if (!_isCurrent(generation)) {
          return;
        }
      }
      if (!_acceptPermission(permission)) {
        return;
      }

      _emit(const VoiceInteractionState(VoiceInteractionPhase.initializing));
      final recognitionReady = await _recognition.initialize();
      if (!_isCurrent(generation)) {
        return;
      }
      final synthesisReady = await _synthesis.initialize();
      if (!_isCurrent(generation)) {
        return;
      }
      if (!recognitionReady || !synthesisReady) {
        _portsReady = false;
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.unavailable,
            failure: VoicePortFailure.unavailable,
          ),
        );
        return;
      }

      _portsReady = true;
      _emit(const VoiceInteractionState(VoiceInteractionPhase.ready));
    } catch (_) {
      if (_isCurrent(generation)) {
        _portsReady = false;
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.unavailable,
            failure: VoicePortFailure.unavailable,
          ),
        );
      }
    }
  }

  Future<void> listenOnce() async {
    if (_disposed || !_state.canListen) {
      return;
    }

    final generation = _generation;
    var finalHandled = false;
    _emit(const VoiceInteractionState(VoiceInteractionPhase.listening));

    try {
      await _recognition.listenOnce(
        onSample: (sample) {
          if (!_isCurrent(generation) ||
              _state.phase != VoiceInteractionPhase.listening ||
              !sample.isFinal ||
              finalHandled) {
            return;
          }
          finalHandled = true;
          unawaited(_handleFinalSample(sample, generation));
        },
        onFailure: (failure) {
          if (!_isCurrent(generation) ||
              _state.phase != VoiceInteractionPhase.listening) {
            return;
          }
          unawaited(_handleRecognitionFailure(failure, generation));
        },
      );
      if (!_isCurrent(generation)) {
        await _ignorePortFailure(_recognition.stop());
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        ++_generation;
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.failed,
            failure: VoicePortFailure.recognitionFailed,
          ),
        );
        await _ignorePortFailure(_recognition.stop());
      }
    }
  }

  Future<void> announce(String text) async {
    if (_disposed ||
        (_state.phase != VoiceInteractionPhase.ready &&
            _state.phase != VoiceInteractionPhase.listening)) {
      return;
    }

    final wasListening = _state.phase == VoiceInteractionPhase.listening;
    final generation = ++_generation;
    _emit(const VoiceInteractionState(VoiceInteractionPhase.speaking));
    try {
      if (wasListening) {
        final recognitionStopped =
            await _portOperationSucceeded(_recognition.stop());
        if (!_isCurrent(generation)) {
          return;
        }
        if (!recognitionStopped) {
          _emit(
            const VoiceInteractionState(
              VoiceInteractionPhase.failed,
              failure: VoicePortFailure.interrupted,
            ),
          );
          return;
        }
      }
      await _synthesis.speak(text);
      if (_isCurrent(generation)) {
        _emit(const VoiceInteractionState(VoiceInteractionPhase.ready));
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.failed,
            failure: VoicePortFailure.synthesisFailed,
          ),
        );
      }
    }
  }

  Future<void> interrupt() async {
    if (_disposed || !_isInterruptible(_state.phase)) {
      return;
    }

    final generation = ++_generation;
    _emit(const VoiceInteractionState(VoiceInteractionPhase.interrupted));
    final stopped = await _stopBothPorts();
    if (_isCurrent(generation) && !stopped) {
      _emit(
        const VoiceInteractionState(
          VoiceInteractionPhase.failed,
          failure: VoicePortFailure.interrupted,
        ),
      );
    }
  }

  void resume() {
    if (!_disposed &&
        _portsReady &&
        _state.phase == VoiceInteractionPhase.interrupted) {
      _emit(const VoiceInteractionState(VoiceInteractionPhase.ready));
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _portsReady = false;
    ++_generation;
    _state = const VoiceInteractionState(VoiceInteractionPhase.disposed);
    if (!_states.isClosed) {
      _states.add(_state);
    }

    await Future.wait([
      _ignorePortFailure(_recognition.stop()),
      _ignorePortFailure(_synthesis.stop()),
    ]);
    await Future.wait([
      _ignorePortFailure(_recognition.dispose()),
      _ignorePortFailure(_synthesis.dispose()),
    ]);
    await _states.close();
  }

  Future<void> _handleFinalSample(
    VoiceRecognitionSample sample,
    int generation,
  ) async {
    _emit(const VoiceInteractionState(VoiceInteractionPhase.processing));
    try {
      await _recognition.stop();
      if (!_isCurrent(generation)) {
        return;
      }

      final intent = _interpret(sample.text);
      if (intent != null) {
        _onIntent(intent);
      }
      if (_isCurrent(generation)) {
        _emit(
          VoiceInteractionState(
            VoiceInteractionPhase.ready,
            failure: intent == null ? VoicePortFailure.unrecognized : null,
          ),
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.failed,
            failure: VoicePortFailure.recognitionFailed,
          ),
        );
      }
    }
  }

  Future<void> _handleRecognitionFailure(
    VoicePortFailure failure,
    int generation,
  ) async {
    if (!_isCurrent(generation) ||
        _state.phase != VoiceInteractionPhase.listening) {
      return;
    }

    ++_generation;
    _emit(
      VoiceInteractionState(
        VoiceInteractionPhase.failed,
        failure: failure,
      ),
    );
    await _ignorePortFailure(_recognition.stop());
  }

  bool _acceptPermission(VoicePermissionStatus permission) {
    switch (permission) {
      case VoicePermissionStatus.granted:
        return true;
      case VoicePermissionStatus.denied:
      case VoicePermissionStatus.notDetermined:
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.permissionDenied,
            failure: VoicePortFailure.permissionDenied,
          ),
        );
      case VoicePermissionStatus.permanentlyDenied:
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.permissionPermanentlyDenied,
            failure: VoicePortFailure.permissionDenied,
          ),
        );
      case VoicePermissionStatus.restricted:
        _emit(
          const VoiceInteractionState(
            VoiceInteractionPhase.restricted,
            failure: VoicePortFailure.permissionDenied,
          ),
        );
    }
    return false;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  static bool _isInterruptible(VoiceInteractionPhase phase) {
    return phase == VoiceInteractionPhase.ready ||
        phase == VoiceInteractionPhase.listening ||
        phase == VoiceInteractionPhase.processing ||
        phase == VoiceInteractionPhase.speaking;
  }

  Future<bool> _stopBothPorts() async {
    final results = await Future.wait([
      _portOperationSucceeded(_recognition.stop()),
      _portOperationSucceeded(_synthesis.stop()),
    ]);
    return results.every((result) => result);
  }

  static Future<bool> _portOperationSucceeded(Future<void> operation) async {
    try {
      await operation;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _ignorePortFailure(Future<void> operation) async {
    await _portOperationSucceeded(operation);
  }

  void _emit(VoiceInteractionState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    _states.add(state);
  }
}
