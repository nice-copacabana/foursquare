import 'dart:async';

import 'package:flutter/material.dart';

import '../../../ai/voice_game_intent.dart';
import '../../../l10n/app_localizations.dart';
import '../../../meditation/meditation_intent_handler.dart';
import '../../../meditation/meditation_session.dart';
import '../../../meditation/meditation_session_runtime.dart';
import '../../../services/voice/voice_interaction_controller.dart';
import '../../../services/voice/voice_ports.dart';
import '../../../theme/theme_pack.dart';
import '../../../theme/theme_pack_registry.dart';

/// A screen-light, voice-first adapter over the meditation authority runtime.
///
/// The page intentionally owns no board or game state of its own. It displays
/// committed runtime snapshots and only sends typed intents back to the
/// authority boundary.
class MeditationPage extends StatefulWidget {
  const MeditationPage({
    super.key,
    required this.runtime,
    required this.permission,
    required this.recognition,
    required this.synthesis,
    this.now = DateTime.now,
    this.ownsRuntime = true,
  });

  final MeditationSessionRuntime runtime;
  final MicrophonePermissionPort permission;
  final VoiceRecognitionPort recognition;
  final VoiceSynthesisPort synthesis;
  final DateTime Function() now;
  final bool ownsRuntime;

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage>
    with WidgetsBindingObserver {
  late final ThemePack _themePack = ThemePackRegistry.phaseOne().defaultPack;
  late final VoiceInteractionController _voice;
  late MeditationSession _session = widget.runtime.session;
  late VoiceInteractionState _voiceState;
  StreamSubscription<MeditationSession>? _sessionSubscription;
  StreamSubscription<VoiceInteractionState>? _voiceSubscription;
  Timer? _displayTicker;
  Future<void> _lifecycleTail = Future<void>.value();
  String _prompt = '';
  bool _exitConfirmationRequested = false;
  bool _busy = false;
  bool _pausedByLifecycle = false;
  bool _terminalPromptRefreshInFlight = false;
  int? _terminalPromptRefreshRevision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voice = VoiceInteractionController(
      permission: widget.permission,
      recognition: widget.recognition,
      synthesis: widget.synthesis,
      interpret: VoiceGameIntentParser.parse,
      onIntent: _handleVoiceIntent,
    );
    _voiceState = _voice.state;
    if (_session.phase == MeditationSessionPhase.opening) {
      _prompt = widget.runtime.openingPrompt().text;
    }
    _sessionSubscription = widget.runtime.sessions.listen(_onSessionCommitted);
    _voiceSubscription = _voice.states.listen(_onVoiceStateChanged);
    _displayTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session.turnClock != null) {
        setState(() {});
      }
    });
    if (_session.phase != MeditationSessionPhase.opening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_settleRestoredSession());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _queueLifecycle(_resumeAfterLifecycle);
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _queueLifecycle(_pauseForLifecycle);
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayTicker?.cancel();
    unawaited(_sessionSubscription?.cancel());
    unawaited(_voiceSubscription?.cancel());
    unawaited(_voice.dispose());
    if (widget.ownsRuntime) widget.runtime.dispose();
    super.dispose();
  }

  Future<VoiceInteractionReply?> _handleVoiceIntent(
    VoiceGameIntent intent,
  ) async {
    final response = await widget.runtime.handle(intent);
    _applyResponse(response);
    return VoiceInteractionReply(response.prompt.text);
  }

  void _onSessionCommitted(MeditationSession session) {
    if (!mounted) return;
    setState(() {
      _session = session;
      if (session.phase == MeditationSessionPhase.completed) {
        _prompt = AppLocalizations.of(context)!.meditationFinished;
      }
    });
    if (session.phase == MeditationSessionPhase.completed) {
      _pausedByLifecycle = false;
      unawaited(_voice.interrupt());
      if (_terminalPromptRefreshRevision != session.revision) {
        _terminalPromptRefreshRevision = session.revision;
        unawaited(_refreshTerminalPrompt());
      }
    }
  }

  Future<void> _refreshTerminalPrompt() async {
    if (_terminalPromptRefreshInFlight) return;
    _terminalPromptRefreshInFlight = true;
    try {
      final response = await widget.runtime.start();
      if (mounted &&
          widget.runtime.session.phase == MeditationSessionPhase.completed) {
        _applyResponse(response);
      }
    } catch (_) {
      // Disposal or a failed archive retry must not surface stale UI work.
    } finally {
      _terminalPromptRefreshInFlight = false;
    }
  }

  void _onVoiceStateChanged(VoiceInteractionState state) {
    if (!mounted) return;
    setState(() => _voiceState = state);
  }

  Future<void> _settleRestoredSession() async {
    try {
      final response = await widget.runtime.start();
      _applyResponse(response);
    } catch (_) {
      if (mounted) {
        setState(() {
          _prompt = AppLocalizations.of(context)!.meditationVoiceFailed;
        });
      }
    }
  }

  void _queueLifecycle(Future<void> Function() action) {
    _lifecycleTail = _lifecycleTail.then((_) => action()).catchError((_) {});
  }

  Future<void> _pauseForLifecycle() async {
    await _voice.interrupt();
    if (_session.phase != MeditationSessionPhase.humanTurn &&
        _session.phase != MeditationSessionPhase.aiTurn) {
      return;
    }
    final response = await widget.runtime.handle(
      const VoiceActionIntent(VoiceGameAction.pause),
    );
    _pausedByLifecycle =
        response.action?.session.phase == MeditationSessionPhase.paused;
    _applyResponse(response);
  }

  Future<void> _resumeAfterLifecycle() async {
    _voice.resume();
    if (!_pausedByLifecycle ||
        _session.phase != MeditationSessionPhase.paused) {
      return;
    }
    _pausedByLifecycle = false;
    final response = await widget.runtime.handle(
      const VoiceActionIntent(VoiceGameAction.resume),
    );
    _applyResponse(response);
  }

  Future<void> _enableVoice() async {
    await _runBusy(_voice.enableAfterDisclosure);
  }

  Future<void> _beginGame() async {
    await _runBusy(() async {
      final opening = widget.runtime.openingPrompt().text;
      final announced = await _voice.announce(opening);
      if (!announced || !mounted) return;
      final response = await widget.runtime.start();
      _applyResponse(response);
      await _voice.announce(response.prompt.text);
    });
  }

  Future<void> _submitAction(VoiceGameAction action) async {
    await _runBusy(() async {
      final response = await widget.runtime.handle(VoiceActionIntent(action));
      _applyResponse(response);
      if (_voice.state.phase == VoiceInteractionPhase.ready) {
        await _voice.announce(response.prompt.text);
      }
    });
  }

  Future<void> _runBusy(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        setState(() {
          _prompt = AppLocalizations.of(context)!.meditationVoiceFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyResponse(MeditationTurnResponse response) {
    if (!mounted) return;
    setState(() {
      _session = widget.runtime.session;
      _prompt = response.prompt.text;
      _exitConfirmationRequested = response.exitConfirmationRequested;
    });
    if (_session.phase == MeditationSessionPhase.completed) {
      _pausedByLifecycle = false;
    }
  }

  int _remainingSeconds() {
    final clock = _session.turnClock;
    if (clock == null) return 0;
    return (clock.remainingAt(widget.now()).inMilliseconds / 1000).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _themePack.colors;
    final textDirection = Directionality.of(context);
    final prompt = _prompt.isEmpty ? l10n.meditationVoicePreparing : _prompt;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: colors.paperBase,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperTexturePainter(colors),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PageHeader(
                          colors: colors,
                          eyebrow: l10n.meditationEyebrow,
                          title: l10n.meditationTitle,
                          backLabel: l10n.meditationLeave,
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: _MeditationSeal(
                            colors: colors,
                            active: _voiceState.phase ==
                                    VoiceInteractionPhase.listening ||
                                _voiceState.phase ==
                                    VoiceInteractionPhase.speaking,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _MetricChip(
                              colors: colors,
                              icon: Icons.route_outlined,
                              label: l10n.meditationMoves(
                                _session.moveHistory.length,
                              ),
                            ),
                            if (_session.turnClock != null)
                              _MetricChip(
                                key: const Key('meditation-remaining'),
                                colors: colors,
                                icon: _session.phase ==
                                        MeditationSessionPhase.paused
                                    ? Icons.pause_rounded
                                    : Icons.timelapse_rounded,
                                label: l10n.meditationRemaining(
                                  _remainingSeconds(),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _PromptPanel(
                          colors: colors,
                          label: l10n.meditationPromptLabel,
                          prompt: prompt,
                          voiceStatus: _voiceStatus(l10n),
                          textDirection: textDirection,
                        ),
                        const SizedBox(height: 16),
                        if (_voiceState.phase == VoiceInteractionPhase.disabled)
                          _DisclosurePanel(
                            colors: colors,
                            title: l10n.meditationDisclosureTitle,
                            body: l10n.meditationDisclosureBody,
                            footnote:
                                '${l10n.meditationChineseOnly}\n${l10n.meditationPrivacyNote}',
                            buttonLabel: l10n.meditationEnable,
                            busy: _busy,
                            onEnable: _enableVoice,
                          )
                        else
                          _buildPrimaryAction(l10n, colors),
                        const SizedBox(height: 14),
                        _buildSecondaryActions(l10n, colors),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(
    AppLocalizations l10n,
    AppColorTokens colors,
  ) {
    if (_exitConfirmationRequested) {
      return _ExitConfirmation(
        colors: colors,
        confirmLabel: l10n.meditationConfirmExit,
        cancelLabel: l10n.meditationCancelExit,
        busy: _busy,
        onConfirm: () => _submitAction(VoiceGameAction.confirmExit),
        onCancel: () => _submitAction(VoiceGameAction.cancelExit),
      );
    }
    if (_session.phase == MeditationSessionPhase.completed) {
      return _PrimaryButton(
        key: const Key('meditation-leave'),
        colors: colors,
        icon: Icons.arrow_back_rounded,
        label: l10n.meditationLeave,
        onPressed: _busy ? null : () => Navigator.maybePop(context),
      );
    }
    if (_session.phase == MeditationSessionPhase.opening) {
      return _PrimaryButton(
        key: const Key('meditation-begin'),
        colors: colors,
        icon: Icons.volume_up_outlined,
        label: l10n.meditationBegin,
        onPressed: _voiceState.phase == VoiceInteractionPhase.ready && !_busy
            ? _beginGame
            : null,
      );
    }
    if (_voiceState.phase == VoiceInteractionPhase.awaitingReplay) {
      return _PrimaryButton(
        key: const Key('meditation-replay'),
        colors: colors,
        icon: Icons.replay_rounded,
        label: l10n.meditationRepeat,
        onPressed: _busy ? null : _voice.replayPendingReply,
      );
    }
    return _PrimaryButton(
      key: const Key('meditation-listen'),
      colors: colors,
      icon: _voiceState.phase == VoiceInteractionPhase.listening
          ? Icons.graphic_eq_rounded
          : Icons.mic_none_rounded,
      label: l10n.meditationListen,
      onPressed: _voiceState.canListen && !_busy ? _voice.listenOnce : null,
    );
  }

  Widget _buildSecondaryActions(
    AppLocalizations l10n,
    AppColorTokens colors,
  ) {
    if (_session.phase == MeditationSessionPhase.opening ||
        _session.phase == MeditationSessionPhase.completed) {
      return const SizedBox.shrink();
    }
    final paused = _session.phase == MeditationSessionPhase.paused;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuietButton(
          key: const Key('meditation-pause-resume'),
          colors: colors,
          icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: paused ? l10n.meditationResume : l10n.meditationPause,
          onPressed: _busy
              ? null
              : () => _submitAction(
                    paused ? VoiceGameAction.resume : VoiceGameAction.pause,
                  ),
        ),
        _QuietButton(
          key: const Key('meditation-repeat'),
          colors: colors,
          icon: Icons.replay_rounded,
          label: l10n.meditationRepeat,
          onPressed: _busy ? null : () => _submitAction(VoiceGameAction.repeat),
        ),
        _QuietButton(
          key: const Key('meditation-exit'),
          colors: colors,
          icon: Icons.outlined_flag_rounded,
          label: l10n.meditationExit,
          danger: true,
          onPressed: _busy ? null : () => _submitAction(VoiceGameAction.exit),
        ),
      ],
    );
  }

  String _voiceStatus(AppLocalizations l10n) {
    if (_voiceState.failure == VoicePortFailure.unrecognized) {
      return l10n.meditationVoiceUnrecognized;
    }
    if (_voiceState.failure == VoicePortFailure.recognitionFailed) {
      return l10n.meditationVoiceFailed;
    }
    return switch (_voiceState.phase) {
      VoiceInteractionPhase.disabled => l10n.meditationVoiceDisabled,
      VoiceInteractionPhase.requestingPermission ||
      VoiceInteractionPhase.initializing =>
        l10n.meditationVoicePreparing,
      VoiceInteractionPhase.ready => l10n.meditationVoiceReady,
      VoiceInteractionPhase.listening => l10n.meditationVoiceListening,
      VoiceInteractionPhase.processing => l10n.meditationVoiceProcessing,
      VoiceInteractionPhase.speaking => l10n.meditationVoiceSpeaking,
      VoiceInteractionPhase.awaitingReplay => l10n.meditationVoiceReplay,
      VoiceInteractionPhase.permissionDenied ||
      VoiceInteractionPhase.permissionPermanentlyDenied ||
      VoiceInteractionPhase.restricted =>
        l10n.meditationVoicePermissionDenied,
      VoiceInteractionPhase.unavailable => l10n.meditationVoiceUnavailable,
      VoiceInteractionPhase.interrupted => l10n.meditationVoiceInterrupted,
      VoiceInteractionPhase.failed ||
      VoiceInteractionPhase.disposed =>
        l10n.meditationVoiceFailed,
    };
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.colors,
    required this.eyebrow,
    required this.title,
    required this.backLabel,
  });

  final AppColorTokens colors;
  final String eyebrow;
  final String title;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const Key('meditation-back'),
          tooltip: backLabel,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: colors.inkPrimary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.cinnabar,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.inkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeditationSeal extends StatelessWidget {
  const _MeditationSeal({required this.colors, required this.active});

  final AppColorTokens colors;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: 154,
        height: 154,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.paperRaised.withValues(alpha: 0.78),
          boxShadow: [
            BoxShadow(
              color: colors.inkPrimary.withValues(alpha: active ? 0.16 : 0.08),
              blurRadius: active ? 28 : 18,
              spreadRadius: active ? 4 : 0,
            ),
          ],
        ),
        child: CustomPaint(painter: _SealPainter(colors, active)),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    super.key,
    required this.colors,
    required this.icon,
    required this.label,
  });

  final AppColorTokens colors;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.paperRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.jade),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.inkMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptPanel extends StatelessWidget {
  const _PromptPanel({
    required this.colors,
    required this.label,
    required this.prompt,
    required this.voiceStatus,
    required this.textDirection,
  });

  final AppColorTokens colors;
  final String label;
  final String prompt;
  final String voiceStatus;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$label: $prompt',
      child: Container(
        key: const Key('meditation-prompt'),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: colors.paperRaised.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.divider),
          boxShadow: [
            BoxShadow(
              color: colors.inkPrimary.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final markerLabel = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.cinnabar,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colors.inkMuted,
                                  letterSpacing: 1.2,
                                ),
                      ),
                    ),
                  ],
                );
                final status = Text(
                  voiceStatus,
                  textAlign: constraints.maxWidth < 300
                      ? TextAlign.start
                      : TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.jade,
                        fontWeight: FontWeight.w700,
                      ),
                );
                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      markerLabel,
                      const SizedBox(height: 6),
                      status,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: markerLabel),
                    const SizedBox(width: 12),
                    Flexible(child: status),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              prompt,
              textDirection: textDirection,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.inkPrimary,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclosurePanel extends StatelessWidget {
  const _DisclosurePanel({
    required this.colors,
    required this.title,
    required this.body,
    required this.footnote,
    required this.buttonLabel,
    required this.busy,
    required this.onEnable,
  });

  final AppColorTokens colors;
  final String title;
  final String body;
  final String footnote;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('meditation-disclosure'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.jade.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.jade.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.inkPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.inkMuted,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            footnote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            key: const Key('meditation-enable'),
            colors: colors,
            icon: Icons.hearing_rounded,
            label: buttonLabel,
            onPressed: busy ? null : onEnable,
          ),
        ],
      ),
    );
  }
}

class _ExitConfirmation extends StatelessWidget {
  const _ExitConfirmation({
    required this.colors,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
  });

  final AppColorTokens colors;
  final String confirmLabel;
  final String cancelLabel;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('meditation-exit-confirmation'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cinnabar.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cinnabar.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cancel = _QuietButton(
            key: const Key('meditation-cancel-exit'),
            colors: colors,
            icon: Icons.arrow_back_rounded,
            label: cancelLabel,
            onPressed: busy ? null : onCancel,
          );
          final confirm = _PrimaryButton(
            key: const Key('meditation-confirm-exit'),
            colors: colors,
            icon: Icons.outlined_flag_rounded,
            label: confirmLabel,
            danger: true,
            onPressed: busy ? null : onConfirm,
          );
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                confirm,
                const SizedBox(height: 10),
                cancel,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: 10),
              Expanded(child: confirm),
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.colors,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final AppColorTokens colors;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final background = danger ? colors.cinnabar : colors.jade;
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: background.withValues(alpha: 0.35),
            foregroundColor: colors.paperBase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({
    super.key,
    required this.colors,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final AppColorTokens colors;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? colors.danger : colors.inkPrimary,
          side: BorderSide(
            color:
                danger ? colors.danger.withValues(alpha: 0.45) : colors.divider,
          ),
          backgroundColor: colors.paperRaised.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter(this.colors, this.active);

  final AppColorTokens colors;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ink = Paint()
      ..color = colors.inkPrimary.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final jade = Paint()
      ..color = colors.jade.withValues(alpha: active ? 0.82 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 3 : 2;
    canvas.drawCircle(center, radius - 10, ink);
    canvas.drawCircle(center, radius - 18, jade);
    canvas.drawLine(
      Offset(center.dx, 36),
      Offset(center.dx, size.height - 36),
      ink,
    );
    canvas.drawLine(
      Offset(36, center.dy),
      Offset(size.width - 36, center.dy),
      ink,
    );
    canvas.drawCircle(
      center,
      active ? 16 : 12,
      Paint()..color = colors.cinnabar.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      active ? 5 : 4,
      Paint()..color = colors.paperBase,
    );
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) {
    return oldDelegate.active != active || oldDelegate.colors != colors;
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter(this.colors);

  final AppColorTokens colors;

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.25, -0.7),
        radius: 1.1,
        colors: [
          colors.paperRaised.withValues(alpha: 0.72),
          colors.paperBase,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    final fiber = Paint()
      ..color = colors.inkPrimary.withValues(alpha: 0.025)
      ..strokeWidth = 0.7;
    for (var index = 0; index < 34; index++) {
      final y = (index * 47.0 + 13) % size.height;
      final start = (index * 31.0) % 80;
      canvas.drawLine(
        Offset(start, y),
        Offset(size.width - ((index * 19.0) % 70), y + 2),
        fiber,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) =>
      oldDelegate.colors != colors;
}
