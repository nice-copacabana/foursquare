import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/voice/platform_voice_adapters.dart';
import 'package:foursquare/services/voice/voice_ports.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('PermissionHandlerMicrophonePort', () {
    test('does not touch the platform before an explicit operation', () {
      var calls = 0;

      PermissionHandlerMicrophonePort(
        readStatus: () async {
          calls += 1;
          return PermissionStatus.granted;
        },
        requestStatus: () async {
          calls += 1;
          return PermissionStatus.granted;
        },
      );

      expect(calls, 0);
    });

    test('maps plugin permission states without broadening microphone access',
        () async {
      const expected = {
        PermissionStatus.denied: VoicePermissionStatus.denied,
        PermissionStatus.granted: VoicePermissionStatus.granted,
        PermissionStatus.restricted: VoicePermissionStatus.restricted,
        PermissionStatus.limited: VoicePermissionStatus.denied,
        PermissionStatus.permanentlyDenied:
            VoicePermissionStatus.permanentlyDenied,
        PermissionStatus.provisional: VoicePermissionStatus.denied,
      };

      for (final entry in expected.entries) {
        final port = PermissionHandlerMicrophonePort(
          readStatus: () async => entry.key,
          requestStatus: () async => entry.key,
        );

        expect(await port.check(), entry.value);
        expect(await port.request(), entry.value);
      }
    });
  });

  group('SpeechToTextRecognitionPort', () {
    test('creates and initializes its engine lazily', () async {
      final engine = _FakeRecognitionEngine();
      var factoryCalls = 0;
      final port = SpeechToTextRecognitionPort(
        createEngine: () {
          factoryCalls += 1;
          return engine;
        },
      );

      expect(factoryCalls, 0);
      expect(await port.initialize(), isTrue);
      expect(await port.initialize(), isTrue);
      expect(factoryCalls, 1);
      expect(engine.initializeCalls, 1);
    });

    test('uses short-command options and maps results without retaining text',
        () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);
      final samples = <VoiceRecognitionSample>[];

      await port.initialize();
      await port.listenOnce(
        onSample: samples.add,
        onFailure: (_) => fail('unexpected failure'),
      );
      engine.emitResult(
        const PlatformSpeechResult(
          text: '从甲一到甲二',
          confidence: -1,
          isFinal: true,
        ),
      );

      expect(engine.lastLocaleId, 'zh-CN');
      expect(
        engine.lastOptions,
        const PlatformSpeechListenOptions.shortCommand(),
      );
      expect(samples, hasLength(1));
      expect(samples.single.text, '从甲一到甲二');
      expect(samples.single.confidence, 1);
      expect(port.toString(), isNot(contains('从甲一到甲二')));
    });

    test('converts engine errors to a stable failure and hides raw details',
        () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);
      final failures = <VoicePortFailure>[];

      await port.initialize();
      await port.listenOnce(
        onSample: (_) => fail('unexpected sample'),
        onFailure: failures.add,
      );
      engine.emitError('server returned private transcript details');

      expect(failures, [VoicePortFailure.recognitionFailed]);
      expect(port.toString(), isNot(contains('private transcript')));
    });

    test('maps expected terminal conditions without leaking plugin strings',
        () async {
      final cases = {
        'error_permission': VoicePortFailure.permissionDenied,
        'error_speech_recognizer_request_not_authorized':
            VoicePortFailure.permissionDenied,
        'not-allowed': VoicePortFailure.permissionDenied,
        'error_no_match': VoicePortFailure.unrecognized,
        'error_speech_timeout': VoicePortFailure.unrecognized,
        'error_cancelled': VoicePortFailure.interrupted,
        'error_busy': VoicePortFailure.recognitionFailed,
        'error_network': VoicePortFailure.recognitionFailed,
      };

      for (final entry in cases.entries) {
        final engine = _FakeRecognitionEngine();
        final port = SpeechToTextRecognitionPort(createEngine: () => engine);
        final failures = <VoicePortFailure>[];
        await port.initialize();
        await port.listenOnce(onSample: (_) {}, onFailure: failures.add);

        engine.emitError(entry.key);

        expect(failures, [entry.value]);
        await port.dispose();
      }
    });

    test('done without a final result reports unrecognized once', () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);
      final failures = <VoicePortFailure>[];

      await port.initialize();
      await port.listenOnce(onSample: (_) {}, onFailure: failures.add);
      engine.emitStatus(PlatformSpeechStatus.done);
      engine.emitStatus(PlatformSpeechStatus.notListening);

      expect(failures, [VoicePortFailure.unrecognized]);
    });

    test('delivers partial samples but only one final sample', () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);
      final samples = <VoiceRecognitionSample>[];

      await port.initialize();
      await port.listenOnce(onSample: samples.add, onFailure: (_) {});
      engine.emitResult(
        const PlatformSpeechResult(
          text: '甲',
          confidence: 0.8,
          isFinal: false,
        ),
      );
      engine.emitResult(
        const PlatformSpeechResult(
          text: '甲一',
          confidence: 0.9,
          isFinal: true,
        ),
      );
      engine.emitResult(
        const PlatformSpeechResult(
          text: '重复终局',
          confidence: 0.9,
          isFinal: true,
        ),
      );

      expect(samples.map((sample) => sample.text), ['甲', '甲一']);
    });

    test('stop and dispose invalidate late callbacks', () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);
      final samples = <VoiceRecognitionSample>[];
      final failures = <VoicePortFailure>[];

      await port.initialize();
      await port.listenOnce(onSample: samples.add, onFailure: failures.add);
      final staleResult = engine.onResult;
      final staleError = engine.onError;
      await port.stop();
      staleResult?.call(
        const PlatformSpeechResult(
          text: '迟到内容',
          confidence: 0.9,
          isFinal: true,
        ),
      );
      staleError?.call('late error');

      await port.dispose();
      await port.dispose();

      expect(samples, isEmpty);
      expect(failures, isEmpty);
      expect(engine.cancelCalls, 1);
    });

    test('late status and error from an old listen cannot end a new listen',
        () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);
      final secondFailures = <VoicePortFailure>[];

      await port.initialize();
      await port.listenOnce(onSample: (_) {}, onFailure: (_) {});
      final staleStatus = engine.onStatus;
      final staleError = engine.onError;
      await port.stop();
      await port.listenOnce(
        onSample: (_) {},
        onFailure: secondFailures.add,
      );

      staleStatus?.call(PlatformSpeechStatus.notListening);
      staleError?.call('error_permission');

      expect(secondFailures, isEmpty);
      await port.dispose();
    });

    test('rejects listening before successful initialization', () async {
      final engine = _FakeRecognitionEngine(initializeResult: false);
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);

      expect(await port.initialize(), isFalse);
      expect(
        () => port.listenOnce(onSample: (_) {}, onFailure: (_) {}),
        throwsStateError,
      );
    });

    test('rejects a second concurrent listen session', () async {
      final engine = _FakeRecognitionEngine();
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);

      await port.initialize();
      await port.listenOnce(onSample: (_) {}, onFailure: (_) {});

      expect(
        () => port.listenOnce(onSample: (_) {}, onFailure: (_) {}),
        throwsStateError,
      );
      await port.dispose();
    });

    test('does not allow a new listen before cancel terminal acknowledgement',
        () async {
      final engine = _FakeRecognitionEngine(waitForCancelTerminal: true);
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);

      await port.initialize();
      await port.listenOnce(onSample: (_) {}, onFailure: (_) {});
      final stopping = port.stop();
      await Future<void>.delayed(Duration.zero);

      expect(
        () => port.listenOnce(onSample: (_) {}, onFailure: (_) {}),
        throwsStateError,
      );
      engine.emitStatus(PlatformSpeechStatus.notListening);
      await stopping;
      await port.listenOnce(onSample: (_) {}, onFailure: (_) {});
      final disposing = port.dispose();
      await Future<void>.delayed(Duration.zero);
      engine.emitStatus(PlatformSpeechStatus.done);
      await disposing;
    });

    test('a naturally terminal session does not wait for a second cancel ack',
        () async {
      final engine = _FakeRecognitionEngine(waitForCancelTerminal: true);
      final port = SpeechToTextRecognitionPort(createEngine: () => engine);

      await port.initialize();
      await port.listenOnce(onSample: (_) {}, onFailure: (_) {});
      engine.emitStatus(PlatformSpeechStatus.done);

      await port.stop();
      await port.listenOnce(onSample: (_) {}, onFailure: (_) {});
      final disposing = port.dispose();
      await Future<void>.delayed(Duration.zero);
      engine.emitStatus(PlatformSpeechStatus.notListening);
      await disposing;
    });
  });

  group('FlutterTtsSynthesisPort', () {
    test('creates its engine lazily and configures completion awaiting',
        () async {
      final engine = _FakeSynthesisEngine();
      var factoryCalls = 0;
      final port = FlutterTtsSynthesisPort(
        createEngine: () {
          factoryCalls += 1;
          return engine;
        },
      );

      expect(factoryCalls, 0);
      expect(await port.initialize(), isTrue);
      expect(await port.initialize(), isTrue);
      expect(factoryCalls, 1);
      expect(engine.initializeCalls, 1);
      expect(engine.lastLocaleId, 'zh-CN');
      expect(engine.awaitCompletion, isFalse);
    });

    test('speak completes only when engine playback completes', () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);
      var completed = false;

      await port.initialize();
      final speaking = port.speak('已提交的播报').then((_) {
        completed = true;
      });
      engine.acceptSpeech();
      engine.startSpeech();
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      engine.completeSpeech();
      await speaking;
      expect(completed, isTrue);
      expect(port.toString(), isNot(contains('已提交的播报')));
    });

    test('stop releases an awaiting utterance and dispose is idempotent',
        () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final speaking = expectLater(port.speak('待中断播报'), throwsStateError);
      engine.acceptSpeech();
      engine.startSpeech();
      await port.stop();
      await speaking;
      await port.dispose();
      await port.dispose();

      expect(engine.stopCalls, 1);
    });

    test('engine errors fail the active utterance without exposing text',
        () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final expectation = expectLater(port.speak('私密播报'), throwsStateError);
      engine.acceptSpeech();
      engine.startSpeech();
      engine.failSpeech();

      await expectation;
      expect(port.toString(), isNot(contains('私密播报')));
    });

    test('engine rejection before start fails promptly and clears activity',
        () async {
      final engine = _FakeSynthesisEngine(failSpeakImmediately: true);
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();

      await expectLater(port.speak('第一条'), throwsStateError);
      await expectLater(port.speak('第二条'), throwsStateError);
      expect(engine.speakCalls, 2);
    });

    test('an accepted pre-start engine error fails the current utterance',
        () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final speaking = expectLater(port.speak('等待开始'), throwsStateError);
      engine.acceptSpeech();
      await Future<void>.delayed(Duration.zero);
      engine.failSpeech();

      await speaking;
    });

    test('unexpected cancellation fails instead of reporting playback success',
        () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final speaking = expectLater(port.speak('必须完整播报'), throwsStateError);
      engine.acceptSpeech();
      engine.startSpeech();
      engine.cancelSpeech();

      await speaking;
    });

    test('an accepted pre-start cancellation fails the current utterance',
        () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final speaking = expectLater(port.speak('尚未开始'), throwsStateError);
      engine.acceptSpeech();
      await Future<void>.delayed(Duration.zero);
      engine.cancelSpeech();

      await speaking;
    });

    test('rejects a second concurrent utterance', () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final first = port.speak('第一条');
      engine.acceptSpeech();
      engine.startSpeech();

      expect(() => port.speak('第二条'), throwsStateError);
      engine.completeSpeech();
      await first;
    });

    test('a late old terminal callback cannot finish a not-yet-started replay',
        () async {
      final engine = _FakeSynthesisEngine();
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      await port.initialize();
      final first = expectLater(port.speak('第一条'), throwsStateError);
      engine.acceptSpeech();
      engine.startSpeech();
      final staleCancel = engine.cancelCallback;
      await port.stop();
      await first;

      var replayCompleted = false;
      final replay = port.speak('重播').then((_) => replayCompleted = true);
      engine.acceptSpeech();
      staleCancel?.call();
      await Future<void>.delayed(Duration.zero);

      expect(replayCompleted, isFalse);
      engine.startSpeech();
      engine.completeSpeech();
      await replay;
    });

    test('missing stop callback times out and makes the port unavailable',
        () async {
      final engine = _FakeSynthesisEngine(emitCancelOnStop: false);
      final port = FlutterTtsSynthesisPort(
        createEngine: () => engine,
        stopCallbackTimeout: const Duration(milliseconds: 10),
      );

      await port.initialize();
      final speaking = expectLater(port.speak('将被熔断'), throwsStateError);
      engine.acceptSpeech();
      engine.startSpeech();

      await expectLater(port.stop(), throwsA(isA<TimeoutException>()));
      await speaking;
      expect(() => port.speak('不可复用'), throwsStateError);
    });

    test('rejects speaking before successful initialization', () async {
      final engine = _FakeSynthesisEngine(initializeResult: false);
      final port = FlutterTtsSynthesisPort(createEngine: () => engine);

      expect(await port.initialize(), isFalse);
      expect(() => port.speak('不可播报'), throwsStateError);
    });
  });

  test('PlatformVoiceAdapters creates three still-lazy production ports', () {
    final adapters = PlatformVoiceAdapters.create();

    expect(adapters.permission, isA<PermissionHandlerMicrophonePort>());
    expect(adapters.recognition, isA<SpeechToTextRecognitionPort>());
    expect(adapters.synthesis, isA<FlutterTtsSynthesisPort>());
  });
}

final class _FakeRecognitionEngine implements PlatformSpeechRecognitionEngine {
  _FakeRecognitionEngine({
    this.initializeResult = true,
    this.waitForCancelTerminal = false,
  });

  final bool initializeResult;
  final bool waitForCancelTerminal;
  int initializeCalls = 0;
  int cancelCalls = 0;
  String? lastLocaleId;
  PlatformSpeechListenOptions? lastOptions;
  void Function(PlatformSpeechResult result)? onResult;
  void Function(String details)? onError;
  void Function(PlatformSpeechStatus status)? onStatus;
  Completer<void>? _cancelTerminal;
  bool _terminalSeen = false;

  @override
  Future<bool> initialize() async {
    initializeCalls += 1;
    return initializeResult;
  }

  @override
  Future<void> listen({
    required String localeId,
    required PlatformSpeechListenOptions options,
    required void Function(PlatformSpeechResult result) onResult,
    required void Function(String details) onError,
    required void Function(PlatformSpeechStatus status) onStatus,
  }) async {
    lastLocaleId = localeId;
    lastOptions = options;
    this.onResult = onResult;
    this.onError = onError;
    this.onStatus = onStatus;
    _terminalSeen = false;
  }

  void emitResult(PlatformSpeechResult result) => onResult?.call(result);

  void emitError(String details) => onError?.call(details);

  void emitStatus(PlatformSpeechStatus status) {
    final terminal = _cancelTerminal;
    if (terminal != null &&
        !terminal.isCompleted &&
        (status == PlatformSpeechStatus.done ||
            status == PlatformSpeechStatus.notListening)) {
      terminal.complete();
      _terminalSeen = true;
      return;
    }
    if (status == PlatformSpeechStatus.done ||
        status == PlatformSpeechStatus.notListening) {
      _terminalSeen = true;
    }
    onStatus?.call(status);
  }

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    if (_terminalSeen) return;
    if (waitForCancelTerminal) {
      final terminal = Completer<void>();
      _cancelTerminal = terminal;
      try {
        await terminal.future;
      } finally {
        if (identical(_cancelTerminal, terminal)) _cancelTerminal = null;
      }
    }
  }
}

final class _FakeSynthesisEngine implements PlatformSpeechSynthesisEngine {
  _FakeSynthesisEngine({
    this.initializeResult = true,
    this.emitCancelOnStop = true,
    this.failSpeakImmediately = false,
  });

  final bool initializeResult;
  final bool emitCancelOnStop;
  final bool failSpeakImmediately;
  int initializeCalls = 0;
  int speakCalls = 0;
  int stopCalls = 0;
  String? lastLocaleId;
  bool? awaitCompletion;
  Completer<void>? _speech;
  void Function()? _onComplete;
  void Function()? _onStart;
  void Function()? _onCancel;
  void Function()? _onError;

  @override
  Future<bool> initialize({
    required String localeId,
    required bool awaitCompletion,
    required void Function() onStart,
    required void Function() onComplete,
    required void Function() onCancel,
    required void Function() onError,
  }) async {
    initializeCalls += 1;
    lastLocaleId = localeId;
    this.awaitCompletion = awaitCompletion;
    _onStart = onStart;
    _onComplete = onComplete;
    _onCancel = onCancel;
    _onError = onError;
    return initializeResult;
  }

  @override
  Future<void> speak(String text) {
    speakCalls += 1;
    if (failSpeakImmediately) {
      return Future<void>.error(StateError('rejected'));
    }
    _speech = Completer<void>();
    return _speech!.future;
  }

  void completeSpeech() {
    _onComplete?.call();
  }

  void startSpeech() => _onStart?.call();

  void cancelSpeech() => _onCancel?.call();

  void Function()? get cancelCallback => _onCancel;

  void acceptSpeech() {
    if (!(_speech?.isCompleted ?? true)) {
      _speech!.complete();
    }
  }

  void failSpeech() {
    _onError?.call();
    acceptSpeech();
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (emitCancelOnStop) _onCancel?.call();
  }
}
