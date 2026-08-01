import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import 'voice_ports.dart';

abstract interface class PlatformSpeechSynthesisEngine {
  Future<bool> initialize({
    required String localeId,
    required bool awaitCompletion,
    required void Function() onStart,
    required void Function() onComplete,
    required void Function() onCancel,
    required void Function() onError,
  });

  Future<void> speak(String text);

  Future<void> stop();
}

typedef PlatformSpeechSynthesisEngineFactory = PlatformSpeechSynthesisEngine
    Function();

final class _ActiveUtterance {
  final Completer<void> completion = Completer<void>();
  bool accepted = false;
  bool started = false;
}

/// Completion-aware, single-utterance adapter over flutter_tts.
final class FlutterTtsSynthesisPort implements VoiceSynthesisPort {
  final PlatformSpeechSynthesisEngineFactory _createEngine;
  final String localeId;
  final Duration stopCallbackTimeout;

  PlatformSpeechSynthesisEngine? _engine;
  _ActiveUtterance? _active;
  Completer<void>? _stopSignal;
  bool _initialized = false;
  bool _engineStopped = false;
  bool _stopping = false;
  bool _disposed = false;

  FlutterTtsSynthesisPort({
    PlatformSpeechSynthesisEngineFactory? createEngine,
    this.localeId = 'zh-CN',
    this.stopCallbackTimeout = const Duration(seconds: 1),
  }) : _createEngine = createEngine ?? _createFlutterTtsEngine;

  @override
  Future<bool> initialize() async {
    if (_disposed) return false;
    if (_initialized) return true;

    final engine = _engine ??= _createEngine();
    try {
      _initialized = await engine.initialize(
        localeId: localeId,
        awaitCompletion: false,
        onStart: _startActive,
        onComplete: _completeActive,
        onCancel: _failAcceptedActive,
        onError: _failAcceptedActive,
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> speak(String text) {
    if (_disposed || !_initialized) {
      throw StateError('Voice synthesis is not available.');
    }
    if (_stopping || _active != null) {
      throw StateError('A voice utterance is already active.');
    }

    final utterance = _ActiveUtterance();
    _active = utterance;
    _engineStopped = false;
    unawaited(_observeEngineSpeech(utterance, text));
    return utterance.completion.future;
  }

  @override
  Future<void> stop() async {
    if (!_initialized || _engineStopped || _stopping) return;
    _stopping = true;
    final utterance = _active;
    final stopSignal = utterance == null ? null : Completer<void>();
    _stopSignal = stopSignal;
    try {
      await _engine!.stop();
      if (stopSignal != null && !stopSignal.isCompleted) {
        await stopSignal.future.timeout(stopCallbackTimeout);
      }
      _engineStopped = true;
    } catch (_) {
      if (identical(_active, utterance)) _failActive(force: true);
      _initialized = false;
      _engineStopped = true;
      rethrow;
    } finally {
      if (identical(_stopSignal, stopSignal)) _stopSignal = null;
      _stopping = false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    try {
      if (_initialized && !_engineStopped) await stop();
    } finally {
      _disposed = true;
      _initialized = false;
      _failActive();
    }
  }

  Future<void> _observeEngineSpeech(
    _ActiveUtterance utterance,
    String text,
  ) async {
    try {
      await _engine!.speak(text);
      if (identical(_active, utterance)) utterance.accepted = true;
    } catch (_) {
      if (identical(_active, utterance)) _failActive(force: true);
    }
  }

  void _startActive() {
    _active?.started = true;
  }

  void _completeActive() {
    final utterance = _active;
    if (utterance != null && !utterance.started && !_stopping) return;
    _active = null;
    if (utterance != null && !utterance.completion.isCompleted) {
      utterance.completion.complete();
    }
    _completeStopSignal();
  }

  void _failActive({bool force = false}) {
    final utterance = _active;
    if (utterance != null && !utterance.started && !_stopping && !force) {
      return;
    }
    _active = null;
    if (utterance != null && !utterance.completion.isCompleted) {
      utterance.completion.completeError(
        StateError('Voice synthesis failed.'),
      );
    }
    _completeStopSignal();
  }

  void _failAcceptedActive() {
    final utterance = _active;
    if (utterance != null && utterance.accepted) {
      _failActive(force: true);
      return;
    }
    _failActive();
  }

  void _completeStopSignal() {
    final signal = _stopSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
  }

  @override
  String toString() => 'FlutterTtsSynthesisPort('
      'initialized: $_initialized, speaking: ${_active != null})';
}

PlatformSpeechSynthesisEngine _createFlutterTtsEngine() =>
    _FlutterTtsEngine(FlutterTts());

final class _FlutterTtsEngine implements PlatformSpeechSynthesisEngine {
  final FlutterTts _tts;

  const _FlutterTtsEngine(this._tts);

  @override
  Future<bool> initialize({
    required String localeId,
    required bool awaitCompletion,
    required void Function() onStart,
    required void Function() onComplete,
    required void Function() onCancel,
    required void Function() onError,
  }) async {
    _tts.setStartHandler(onStart);
    _tts.setCompletionHandler(onComplete);
    _tts.setCancelHandler(onCancel);
    _tts.setErrorHandler((_) => onError());
    final completionResult = await _tts.awaitSpeakCompletion(awaitCompletion);
    final languageResult = await _tts.setLanguage(localeId);
    return _succeeded(completionResult) && _succeeded(languageResult);
  }

  @override
  Future<void> speak(String text) async {
    final result = await _tts.speak(text);
    if (!_succeeded(result)) {
      throw StateError('Voice synthesis was rejected.');
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  static bool _succeeded(Object? result) => result == 1 || result == true;
}
