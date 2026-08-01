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
      onIntent: (intent) {
        intents.add(intent);
        return null;
      },
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

  test('an async intent reply is spoken before returning to ready', () async {
    await controller.dispose();
    synthesis = _FakeSynthesisPort()..holdNextSpeak();
    controller = VoiceInteractionController(
      permission: permission,
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: (intent) async {
        intents.add(intent);
        return const VoiceInteractionReply('权威处理完成');
      },
    );
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    recognition.emitFinal('A1');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.phase, VoiceInteractionPhase.speaking);

    synthesis.completeSpeak();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
    expect(intents, hasLength(1));
  });

  test('failed reply speech is recoverable without re-executing the intent',
      () async {
    await controller.dispose();
    synthesis = _FakeSynthesisPort()..throwOnNextSpeak = true;
    controller = VoiceInteractionController(
      permission: permission,
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: (intent) {
        intents.add(intent);
        return const VoiceInteractionReply('权威处理完成');
      },
    );
    await controller.enableAfterDisclosure();
    await controller.listenOnce();

    recognition.emitFinal('A1');
    await Future<void>.delayed(Duration.zero);

    expect(intents, hasLength(1));
    expect(controller.state.phase, VoiceInteractionPhase.awaitingReplay);
    expect(controller.state.failure, VoicePortFailure.synthesisFailed);
    expect(controller.hasPendingReply, isTrue);

    await controller.listenOnce();
    expect(recognition.listenCalls, 1);

    expect(await controller.replayPendingReply(), isTrue);

    expect(intents, hasLength(1));
    expect(synthesis.spokenTexts, ['权威处理完成', '权威处理完成']);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
    expect(controller.state.failure, isNull);
    expect(controller.hasPendingReply, isFalse);

    await controller.listenOnce();
    expect(recognition.listenCalls, 2);
  });

  test('processing interruption defers speech and prevents another command',
      () async {
    await controller.dispose();
    final firstReply = Completer<VoiceInteractionReply?>();
    controller = VoiceInteractionController(
      permission: permission,
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: (intent) {
        intents.add(intent);
        return firstReply.future;
      },
    );
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    recognition.emitFinal('A1');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.phase, VoiceInteractionPhase.processing);

    await controller.interrupt();
    controller.resume();
    await controller.listenOnce();
    recognition.emitFinal('A2');
    await Future<void>.delayed(Duration.zero);

    expect(intents, hasLength(1));
    expect(recognition.listenCalls, 1);
    firstReply.complete(const VoiceInteractionReply('已完成'));
    await Future<void>.delayed(Duration.zero);

    expect(synthesis.spokenTexts, isEmpty);
    expect(controller.state.phase, VoiceInteractionPhase.awaitingReplay);
    expect(controller.hasPendingReply, isTrue);
    expect(await controller.replayPendingReply(), isTrue);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
  });

  test('synchronous speaking interruption cannot start synthesis afterwards',
      () async {
    synthesis.holdNextSpeak();
    await controller.enableAfterDisclosure();
    final subscription = controller.states.listen((state) {
      if (state.phase == VoiceInteractionPhase.speaking) {
        unawaited(controller.interrupt());
      }
    });
    addTearDown(subscription.cancel);

    final speaking = controller.announce('可被观察者中断');
    await Future<void>.delayed(Duration.zero);

    expect(synthesis.spokenTexts, ['可被观察者中断']);
    expect(controller.state.phase, VoiceInteractionPhase.awaitingReplay);
    synthesis.completeSpeak();
    expect(await speaking, isFalse);
  });

  test('resume waits until interrupt has stopped every audio port', () async {
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    recognition.holdNextStop();

    final interrupting = controller.interrupt();
    controller.resume();
    await controller.listenOnce();

    expect(controller.state.phase, VoiceInteractionPhase.interrupted);
    expect(recognition.listenCalls, 1);
    recognition.completeStop();
    await interrupting;
    expect(controller.state.phase, VoiceInteractionPhase.ready);

    await controller.listenOnce();
    expect(recognition.listenCalls, 2);
  });

  test('deferred interruption is cleared after an unrecognized command',
      () async {
    await controller.dispose();
    controller = VoiceInteractionController(
      permission: permission,
      recognition: recognition,
      synthesis: synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: (_) => const VoiceInteractionReply('有效回复'),
    );
    await controller.enableAfterDisclosure();
    await controller.listenOnce();
    recognition.holdNextStop();
    recognition.emitFinal('无法解析的内容');
    await Future<void>.delayed(Duration.zero);
    await controller.interrupt();
    recognition.completeStop();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.phase, VoiceInteractionPhase.interrupted);
    controller.resume();
    await controller.listenOnce();
    recognition.emitFinal('A1');
    await Future<void>.delayed(Duration.zero);

    expect(synthesis.spokenTexts, contains('有效回复'));
    expect(controller.state.phase, VoiceInteractionPhase.ready);
  });

  test('failed announcement can be replayed before listening', () async {
    synthesis.throwOnNextSpeak = true;
    await controller.enableAfterDisclosure();

    expect(await controller.announce('开场引导'), isFalse);
    expect(controller.state.phase, VoiceInteractionPhase.awaitingReplay);
    expect(controller.hasPendingReply, isTrue);

    await controller.listenOnce();
    expect(recognition.listenCalls, 0);
    expect(await controller.replayPendingReply(), isTrue);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
    expect(synthesis.spokenTexts, ['开场引导', '开场引导']);
  });

  test('interrupted reply remains replayable instead of unlocking input',
      () async {
    synthesis.holdNextSpeak();
    await controller.enableAfterDisclosure();

    final speaking = controller.announce('权威回复');
    await Future<void>.delayed(Duration.zero);
    await controller.interrupt();

    expect(controller.state.phase, VoiceInteractionPhase.awaitingReplay);
    await controller.listenOnce();
    expect(recognition.listenCalls, 0);

    synthesis.completeSpeak();
    expect(await speaking, isFalse);
    expect(await controller.replayPendingReply(), isTrue);
    expect(controller.state.phase, VoiceInteractionPhase.ready);
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
    expect(controller.state.phase, VoiceInteractionPhase.ready);
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
  bool throwOnNextSpeak = false;
  int initializeCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  Completer<void>? _speakCompleter;
  final List<String> spokenTexts = [];

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
    spokenTexts.add(text);
    if (throwOnNextSpeak) {
      throwOnNextSpeak = false;
      throw StateError('platform detail must not escape');
    }
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
