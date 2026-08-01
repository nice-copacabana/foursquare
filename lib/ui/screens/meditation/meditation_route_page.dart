import 'dart:async';

import 'package:flutter/material.dart';

import '../../../ai/ai_player.dart';
import '../../../l10n/app_localizations.dart';
import '../../../meditation/meditation_runtime_factory.dart';
import '../../../meditation/meditation_session_runtime.dart';
import '../../../models/piece_type.dart';
import '../../../services/storage_service.dart';
import '../../../services/voice/platform_voice_adapters.dart';
import '../../../theme/theme_pack.dart';
import '../../../theme/theme_pack_registry.dart';
import 'meditation_page.dart';

typedef MeditationRuntimeLoader = Future<MeditationSessionRuntime?> Function();
typedef MeditationVoiceAdaptersFactory = PlatformVoiceAdapters Function();

/// Hidden route boundary that owns async runtime loading and production ports.
///
/// It is deliberately absent from app navigation. Constructing this widget is
/// side-effect free; storage is touched after mounting and voice plugins remain
/// lazy until the disclosure action inside [MeditationPage].
class MeditationRoutePage extends StatefulWidget {
  const MeditationRoutePage({
    super.key,
    required this.loadRuntime,
    required this.createVoiceAdapters,
  });

  final MeditationRuntimeLoader loadRuntime;
  final MeditationVoiceAdaptersFactory createVoiceAdapters;

  factory MeditationRoutePage.newGame({
    Key? key,
    required PieceType humanPlayer,
    required PieceType firstPlayer,
    required AIDifficulty difficulty,
    StorageService? storageService,
  }) {
    final runtimeFactory = MeditationRuntimeFactory.production(
      storageService: storageService,
    );
    return MeditationRoutePage(
      key: key,
      loadRuntime: () => runtimeFactory.createNew(
        humanPlayer: humanPlayer,
        firstPlayer: firstPlayer,
        difficulty: difficulty,
      ),
      createVoiceAdapters: PlatformVoiceAdapters.create,
    );
  }

  factory MeditationRoutePage.restore({
    Key? key,
    StorageService? storageService,
  }) {
    final runtimeFactory = MeditationRuntimeFactory.production(
      storageService: storageService,
    );
    return MeditationRoutePage(
      key: key,
      loadRuntime: runtimeFactory.restore,
      createVoiceAdapters: PlatformVoiceAdapters.create,
    );
  }

  @override
  State<MeditationRoutePage> createState() => _MeditationRoutePageState();
}

class _MeditationRoutePageState extends State<MeditationRoutePage> {
  final ThemePack _themePack = ThemePackRegistry.phaseOne().defaultPack;
  MeditationSessionRuntime? _runtime;
  PlatformVoiceAdapters? _adapters;
  int _generation = 0;
  bool _loading = true;
  bool _failed = false;
  bool _empty = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    ++_generation;
    _runtime?.dispose();
    _runtime = null;
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
        _empty = false;
      });
    }

    MeditationSessionRuntime? runtime;
    try {
      runtime = await widget.loadRuntime();
      if (!mounted || generation != _generation) {
        runtime?.dispose();
        return;
      }
      if (runtime == null) {
        setState(() {
          _loading = false;
          _empty = true;
        });
        return;
      }

      final adapters = widget.createVoiceAdapters();
      if (!mounted || generation != _generation) {
        runtime.dispose();
        return;
      }
      setState(() {
        _runtime = runtime;
        _adapters = adapters;
        _loading = false;
      });
    } catch (_) {
      runtime?.dispose();
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = _runtime;
    final adapters = _adapters;
    if (runtime != null && adapters != null) {
      return MeditationPage(
        runtime: runtime,
        permission: adapters.permission,
        recognition: adapters.recognition,
        synthesis: adapters.synthesis,
        ownsRuntime: false,
      );
    }

    final l10n = AppLocalizations.of(context)!;
    if (_failed) {
      return _MeditationRouteStatus(
        key: const Key('meditation-route-error'),
        colors: _themePack.colors,
        icon: Icons.cloud_off_rounded,
        title: l10n.meditationLoadFailedTitle,
        body: l10n.meditationLoadFailedBody,
        backLabel: l10n.meditationLeave,
        actionLabel: l10n.meditationRetry,
        onAction: _load,
      );
    }
    if (_empty) {
      return _MeditationRouteStatus(
        key: const Key('meditation-route-empty'),
        colors: _themePack.colors,
        icon: Icons.self_improvement_rounded,
        title: l10n.meditationNoSaveTitle,
        body: l10n.meditationNoSaveBody,
        backLabel: l10n.meditationLeave,
      );
    }
    return _MeditationRouteStatus(
      key: const Key('meditation-route-loading'),
      colors: _themePack.colors,
      title: l10n.meditationPreparingTitle,
      body: l10n.meditationPreparingBody,
      backLabel: l10n.meditationLeave,
      loading: _loading,
    );
  }
}

class _MeditationRouteStatus extends StatelessWidget {
  const _MeditationRouteStatus({
    super.key,
    required this.colors,
    required this.title,
    required this.body,
    required this.backLabel,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final AppColorTokens colors;
  final String title;
  final String body;
  final String backLabel;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.paperBase,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  tooltip: backLabel,
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: colors.inkPrimary,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                      decoration: BoxDecoration(
                        color: colors.paperRaised,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: colors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: colors.inkPrimary.withValues(alpha: 0.07),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (loading)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                color: colors.jade,
                                strokeWidth: 3,
                              ),
                            )
                          else
                            Icon(icon, size: 46, color: colors.cinnabar),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: colors.inkPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: colors.inkMuted,
                                      height: 1.55,
                                    ),
                          ),
                          if (actionLabel != null && onAction != null) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const Key('meditation-route-retry'),
                                onPressed: onAction,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(actionLabel!),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: colors.jade,
                                  foregroundColor: colors.paperBase,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
