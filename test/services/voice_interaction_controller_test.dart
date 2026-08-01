import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ai/voice_game_intent.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/voice/voice_interaction_controller.dart';
import 'package:foursquare/services/voice/voice_ports.dart';

void main() {
  late _FakePermissionPort permission;
  late _FakeRecognitionPort recognition;
  late _FakeSynthesisPort synthesis;
  late List<VoiceGameIntent> intents;
  late VoiceInteractionController controller;

  setUp(() {
    permission = _FakePermissionPort();
    recognition = _FakeRecognitionPort();
    synthesis = _FakeSynthesisPort();
    intents = [];
    controller = VoiceInteractionController(
      permission: permission,
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: intents.add,
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('starts disabled without touching any voice port', () {
    expect(controller.state.phase, VoiceInteractionPhase.disabled);
    expect(permission.requestCalls, 0);
    expect(recognition.initializeCalls, 0);
    expect(synthesis.initializeCalls, 0);
  });

  test('disclosure acceptance requests permission and initializes both ports',
      () async {
    await controller.enableAfterDisclosure();

    expect(permission.requestCalls, 1);
    expect(recognition.initializeCalls, 1);
    expect(synthesis.initializeCalls, 1);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
  });

  test('permission denial does not initialize voice services', () async {
    permission.requestResult = VoicePermissionStatus.denied;

    await controller.enableAfterDisclosure();

    expect(controller.state.phase, VoiceInteractionPhase.permissionDenied);
    expect(recognition.initializeCalls, 0);
    expect(synthesis.initializeCalls, 0);
  });

  test('interrupt and resume cannot bypass denied permission', () async {
    permission.requestResult = VoicePermissionStatus.denied;
    await controller.enableAfterDisclosure();

    await controller.interrupt();
    controller.resume();
    await controller.listenOnce();

    expect(controller.state.phase, VoiceInteractionPhase.permissionDenied);
    expect(recognition.listenCalls, 0);
  });

  test('an existing denied status is requested after disclosure', () async {
    permission.current = VoicePermissionStatus.denied;

    await controller.enableAfterDisclosure();

    expect(permission.requestCalls, 1);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
  });

  for (final testCase in [
    (
      VoicePermissionStatus.permanentlyDenied,
      VoiceInteractionPhase.permissionPermanentlyDenied,
    ),
    (
      VoicePermissionStatus.restricted,
      VoiceInteractionPhase.restricted,
    ),
  ]) {
    test('${testCase.$1.name} maps to a stable state', () async {
      permission.current = testCase.$1;

      await controller.enableAfterDisclosure();

      expect(controller.state.phase, testCase.$2);
      expect(recognition.initializeCalls, 0);
      expect(synthesis.initializeCalls, 0);
    });
  }

  test('voice service initialization failure is unavailable', () async {
    recognition.initializeResult = false;

    await controller.enableAfterDisclosure();

    expect(controller.state.phase, VoiceInteractionPhase.unavailable);
    expect(controller.state.failure, VoicePortFailure.unavailable);
  });

  test('a final recognition result emits only a typed intent', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    recognition.emitFinal('横一竖二');
    await Future<void>.delayed(Duration.zero);

    expect(intents, hasLength(1));
    expect(intents.single, isA<VoicePositionIntent>());
    expect(controller.state.phase, VoiceInteractionPhase.ready);
    expect(controller.state.toString(), isNot(contains('横一竖二')));
  });

  test('partial and duplicate final results never duplicate an intent',
      () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    recognition.emit('A1', isFinal: false);
    recognition.emitFinal('A1');
    recognition.emitFinal('A2');
    await Future<void>.delayed(Duration.zero);

    expect(intents, [const VoicePositionIntent(Position(0, 0))]);
  });

  test('unrecognized text returns ready without retaining the text', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    recognition.emitFinal('这是不能解析的秘密原文');
    await Future<void>.delayed(Duration.zero);

    expect(intents, isEmpty);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
    expect(controller.state.failure, VoicePortFailure.unrecognized);
    expect(controller.state.toString(), isNot(contains('秘密原文')));
  });

  test('TTS completion is required before another listen can start', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    synthesis.holdNextSpeak();

    final speaking = controller.announce('请选择棋子');
    await Future<void>.delayed(Duration.zero);

    expect(recognition.stopCalls, 1);
    expect(controller.state.phase, VoiceInteractionPhase.speaking);
    await controller.listenOnce();
    expect(recognition.listenCalls, 1);

    synthesis.completeSpeak();
    await speaking;
    expect(controller.state.phase, VoiceInteractionPhase.ready);

    await controller.listenOnce();
    expect(recognition.listenCalls, 2);
  });

  test('announce invalidates a final result while recognition is stopping',
      () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    recognition.holdNextStop();
    synthesis.holdNextSpeak();

    final speaking = controller.announce('请选择棋子');
    expect(controller.state.phase, VoiceInteractionPhase.speaking);
    recognition.emitFinal('A1');
    recognition.completeStop();
    await Future<void>.delayed(Duration.zero);

    expect(intents, isEmpty);
    expect(controller.state.phase, VoiceInteractionPhase.speaking);
    synthesis.completeSpeak();
    await speaking;
  });

  test('an interrupted delayed recognition start is stopped again', () async {
    await controller.enableAfterDisclosure();
    recognition.holdNextListenStart();

    final listening = controller.listenOnce();
    await Future<void>.delayed(Duration.zero);
    await controller.interrupt();
    recognition.completeListenStart();
    await listening;

    expect(controller.state.phase, VoiceInteractionPhase.interrupted);
    expect(recognition.stopCalls, 2);
    expect(intents, isEmpty);
  });

  test('recognition failure stops the microphone', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    recognition.emitFailure(VoicePortFailure.recognitionFailed);
    await Future<void>.delayed(Duration.zero);

    expect(recognition.stopCalls, 1);
    expect(controller.state.phase, VoiceInteractionPhase.failed);
    expect(
      controller.state.failure,
      VoicePortFailure.recognitionFailed,
    );
  });

  test('failed interruption cannot resume into ready', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    recognition.throwOnStop = true;

    await controller.interrupt();
    controller.resume();

    expect(controller.state.phase, VoiceInteractionPhase.failed);
    expect(controller.state.failure, VoicePortFailure.interrupted);
  });

  test('late recognition callbacks are ignored after disposal', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    await controller.dispose();

    recognition.emitFinal('A1');
    await Future<void>.delayed(Duration.zero);

    expect(intents, isEmpty);
    expect(controller.state.phase, VoiceInteractionPhase.disposed);
  });

  test('dispose stops and disposes both ports exactly once', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    await controller.dispose();
    await controller.dispose();

    expect(recognition.stopCalls, 1);
    expect(synthesis.stopCalls, 1);
    expect(recognition.disposeCalls, 1);
    expect(synthesis.disposeCalls, 1);
  });

  test('interruption stops both ports and can return to ready', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    await controller.interrupt();

    expect(controller.state.phase, VoiceInteractionPhase.interrupted);
    expect(recognition.stopCalls, 1);
    expect(synthesis.stopCalls, 1);

    controller.resume();
    expect(controller.state.phase, VoiceInteractionPhase.ready);
  });
}

class _FakePermissionPort implements MicrophonePermissionPort {
  VoicePermissionStatus current = VoicePermissionStatus.notDetermined;
  VoicePermissionStatus requestResult = VoicePermissionStatus.granted;
  int requestCalls = 0;

  @override
  Future<VoicePermissionStatus> check() async => current;

  @override
  Future<VoicePermissionStatus> request() async {
    requestCalls += 1;
    current = requestResult;
    return current;
  }
}

class _FakeRecognitionPort implements VoiceRecognitionPort {
  bool initializeResult = true;
  bool throwOnStop = false;
  int initializeCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  void Function(VoiceRecognitionSample sample)? _onSample;
  void Function(VoicePortFailure failure)? _onFailure;
  Completer<void>? _listenCompleter;
  Completer<void>? _stopCompleter;

  @override
  Future<bool> initialize() async {
    initializeCalls += 1;
    return initializeResult;
  }

  @override
  Future<void> listenOnce({
    required void Function(VoiceRecognitionSample sample) onSample,
    required void Function(VoicePortFailure failure) onFailure,
  }) async {
    listenCalls += 1;
    _onSample = onSample;
    _onFailure = onFailure;
    await _listenCompleter?.future;
    _listenCompleter = null;
  }

  void holdNextListenStart() {
    _listenCompleter = Completer<void>();
  }

  void completeListenStart() {
    _listenCompleter?.complete();
  }

  void holdNextStop() {
    _stopCompleter = Completer<void>();
  }

  void completeStop() {
    _stopCompleter?.complete();
  }

  void emitFinal(String text) {
    emit(text, isFinal: true);
  }

  void emit(String text, {required bool isFinal}) {
    _onSample?.call(
      VoiceRecognitionSample(
        text: text,
        confidence: 0.9,
        isFinal: isFinal,
      ),
    );
  }

  void emitFailure(VoicePortFailure failure) {
    _onFailure?.call(failure);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (throwOnStop) {
      throw StateError('platform detail must not escape');
    }
    await _stopCompleter?.future;
    _stopCompleter = null;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _FakeSynthesisPort implements VoiceSynthesisPort {
  bool initializeResult = true;
  int initializeCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  Completer<void>? _speakCompleter;

  @override
  Future<bool> initialize() async {
    initializeCalls += 1;
    return initializeResult;
  }

  void holdNextSpeak() {
    _speakCompleter = Completer<void>();
  }

  void completeSpeak() {
    _speakCompleter?.complete();
  }

  @override
  Future<void> speak(String text) async {
    await _speakCompleter?.future;
    _speakCompleter = null;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}
