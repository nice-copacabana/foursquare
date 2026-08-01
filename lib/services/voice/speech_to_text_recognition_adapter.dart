import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_ports.dart';

enum PlatformSpeechStatus { listening, done, notListening }

final class PlatformSpeechResult {
  final String text;
  final double confidence;
  final bool isFinal;

  const PlatformSpeechResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
  });

  @override
  String toString() => 'PlatformSpeechResult(textLength: ${text.length}, '
      'confidence: $confidence, isFinal: $isFinal)';
}

final class PlatformSpeechListenOptions {
  final bool cancelOnError;
  final bool partialResults;
  final bool shortCommand;

  const PlatformSpeechListenOptions({
    required this.cancelOnError,
    required this.partialResults,
    required this.shortCommand,
  });

  const PlatformSpeechListenOptions.shortCommand()
      : cancelOnError = true,
        partialResults = true,
        shortCommand = true;

  @override
  bool operator ==(Object other) =>
      other is PlatformSpeechListenOptions &&
      other.cancelOnError == cancelOnError &&
      other.partialResults == partialResults &&
      other.shortCommand == shortCommand;

  @override
  int get hashCode => Object.hash(cancelOnError, partialResults, shortCommand);
}

abstract interface class PlatformSpeechRecognitionEngine {
  Future<bool> initialize();

  Future<void> listen({
    required String localeId,
    required PlatformSpeechListenOptions options,
    required void Function(PlatformSpeechResult result) onResult,
    required void Function(String details) onError,
    required void Function(PlatformSpeechStatus status) onStatus,
  });

  Future<void> cancel();
}

typedef PlatformSpeechRecognitionEngineFactory = PlatformSpeechRecognitionEngine
    Function();

/// A single-utterance, generation-isolated adapter over speech_to_text.
final class SpeechToTextRecognitionPort implements VoiceRecognitionPort {
  static const _listenOptions = PlatformSpeechListenOptions.shortCommand();

  final PlatformSpeechRecognitionEngineFactory _createEngine;
  final String localeId;

  PlatformSpeechRecognitionEngine? _engine;
  void Function(VoiceRecognitionSample sample)? _onSample;
  void Function(VoicePortFailure failure)? _onFailure;
  int _generation = 0;
  bool _initialized = false;
  bool _sessionOpen = false;
  bool _stopping = false;
  bool _finalDelivered = false;
  bool _disposed = false;

  SpeechToTextRecognitionPort({
    PlatformSpeechRecognitionEngineFactory? createEngine,
    this.localeId = 'zh-CN',
  }) : _createEngine = createEngine ?? _createSpeechToTextEngine;

  @override
  Future<bool> initialize() async {
    if (_disposed) return false;
    if (_initialized) return true;

    final engine = _engine ??= _createEngine();
    try {
      _initialized = await engine.initialize();
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> listenOnce({
    required void Function(VoiceRecognitionSample sample) onSample,
    required void Function(VoicePortFailure failure) onFailure,
  }) async {
    if (_disposed || !_initialized) {
      throw StateError('Voice recognition is not available.');
    }
    if (_sessionOpen || _stopping) {
      throw StateError('A voice recognition session is already active.');
    }

    final generation = ++_generation;
    _sessionOpen = true;
    _finalDelivered = false;
    _onSample = onSample;
    _onFailure = onFailure;
    try {
      await _engine!.listen(
        localeId: localeId,
        options: _listenOptions,
        onResult: (result) => _handleResult(result, generation),
        onError: (details) => _handleEngineError(details, generation),
        onStatus: (status) => _handleEngineStatus(status, generation),
      );
    } catch (_) {
      if (generation == _generation) {
        _clearSession();
        ++_generation;
      }
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (!_sessionOpen) return;
    _clearSession();
    ++_generation;
    _stopping = true;
    try {
      await _engine!.cancel();
    } catch (_) {
      _initialized = false;
      rethrow;
    } finally {
      _stopping = false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_sessionOpen) {
      _clearSession();
      ++_generation;
      await _engine?.cancel();
    }
  }

  void _handleResult(PlatformSpeechResult result, int generation) {
    if (_disposed || !_sessionOpen || generation != _generation) return;
    if (result.isFinal && _finalDelivered) return;
    if (result.isFinal) _finalDelivered = true;

    _onSample?.call(
      VoiceRecognitionSample(
        text: result.text,
        confidence: _normalizeConfidence(result.confidence),
        isFinal: result.isFinal,
      ),
    );
  }

  void _handleEngineError(String details, int generation) {
    if (_disposed ||
        !_sessionOpen ||
        generation != _generation ||
        _onFailure == null) {
      return;
    }
    final failure = _mapFailure(details);
    final callback = _onFailure;
    _onFailure = null;
    _onSample = null;
    callback?.call(failure);
  }

  void _handleEngineStatus(PlatformSpeechStatus status, int generation) {
    if (_disposed ||
        !_sessionOpen ||
        generation != _generation ||
        _finalDelivered ||
        _onFailure == null) {
      return;
    }
    if (status == PlatformSpeechStatus.done ||
        status == PlatformSpeechStatus.notListening) {
      final callback = _onFailure;
      _onFailure = null;
      _onSample = null;
      callback?.call(VoicePortFailure.unrecognized);
    }
  }

  void _clearSession() {
    _sessionOpen = false;
    _finalDelivered = false;
    _onSample = null;
    _onFailure = null;
  }

  static double _normalizeConfidence(double confidence) {
    if (confidence < 0) return 1;
    return confidence.clamp(0, 1).toDouble();
  }

  static VoicePortFailure _mapFailure(String details) {
    final normalized = details.toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('not_allowed') ||
        normalized.contains('not-allowed') ||
        normalized.contains('not_authorized') ||
        normalized.contains('not-authorized')) {
      return VoicePortFailure.permissionDenied;
    }
    if (normalized.contains('no_match') ||
        normalized.contains('speech_timeout')) {
      return VoicePortFailure.unrecognized;
    }
    if (normalized.contains('cancel') || normalized.contains('interrupt')) {
      return VoicePortFailure.interrupted;
    }
    return VoicePortFailure.recognitionFailed;
  }

  @override
  String toString() => 'SpeechToTextRecognitionPort('
      'initialized: $_initialized, active: $_sessionOpen)';
}

PlatformSpeechRecognitionEngine _createSpeechToTextEngine() =>
    _SpeechToTextEngine(SpeechToText());

final class _SpeechToTextEngine implements PlatformSpeechRecognitionEngine {
  static const _cancelTerminalTimeout = Duration(seconds: 1);

  final SpeechToText _speech;
  void Function(String details)? _onError;
  void Function(PlatformSpeechStatus status)? _onStatus;
  Completer<void>? _cancelTerminal;
  bool _terminalSeen = false;

  _SpeechToTextEngine(this._speech);

  @override
  Future<bool> initialize() {
    return _speech.initialize(
      onError: (SpeechRecognitionError error) => _onError?.call(error.errorMsg),
      onStatus: (status) {
        final mapped = switch (status) {
          SpeechToText.listeningStatus => PlatformSpeechStatus.listening,
          SpeechToText.doneStatus => PlatformSpeechStatus.done,
          SpeechToText.notListeningStatus => PlatformSpeechStatus.notListening,
          _ => null,
        };
        if (mapped == null) return;
        if (mapped == PlatformSpeechStatus.done ||
            mapped == PlatformSpeechStatus.notListening) {
          _terminalSeen = true;
        }
        final cancelTerminal = _cancelTerminal;
        if (cancelTerminal != null &&
            !cancelTerminal.isCompleted &&
            (mapped == PlatformSpeechStatus.done ||
                mapped == PlatformSpeechStatus.notListening)) {
          cancelTerminal.complete();
          return;
        }
        _onStatus?.call(mapped);
      },
      debugLogging: false,
    );
  }

  @override
  Future<void> listen({
    required String localeId,
    required PlatformSpeechListenOptions options,
    required void Function(PlatformSpeechResult result) onResult,
    required void Function(String details) onError,
    required void Function(PlatformSpeechStatus status) onStatus,
  }) async {
    _terminalSeen = false;
    _onError = onError;
    _onStatus = onStatus;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(
          PlatformSpeechResult(
            text: result.recognizedWords,
            confidence: result.hasConfidenceRating ? result.confidence : -1,
            isFinal: result.finalResult,
          ),
        );
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        cancelOnError: options.cancelOnError,
        partialResults: options.partialResults,
        listenMode: options.shortCommand
            ? ListenMode.confirmation
            : ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> cancel() async {
    _onError = null;
    _onStatus = null;
    if (_terminalSeen) return;
    final terminal = Completer<void>();
    _cancelTerminal = terminal;
    try {
      await _speech.cancel();
      if (!terminal.isCompleted) {
        await terminal.future.timeout(_cancelTerminalTimeout);
      }
    } finally {
      if (identical(_cancelTerminal, terminal)) _cancelTerminal = null;
    }
  }
}
