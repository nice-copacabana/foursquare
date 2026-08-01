import 'package:flutter/material.dart';

import '../../bloc/game_event.dart';
import '../../services/resource_warmup_service.dart';
import '../../services/storage_service.dart';
import '../../theme/theme_pack.dart';
import '../../theme/theme_pack_registry.dart';
import '../layouts/adaptive_breakpoints.dart';
import '../widgets/game_icon.dart';
import 'game_page.dart';
import 'lan/lan_lobby_page.dart';
import 'rules_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';

/// Phase-one home: offline play, LAN play and local utilities.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.hasSavedGame,
    this.enableResourceWarmup = true,
  });

  final Future<bool> Function()? hasSavedGame;
  final bool enableResourceWarmup;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storageService = StorageService();
  final ResourceWarmupService _resourceWarmupService = ResourceWarmupService();
  final ThemePack _themePack = ThemePackRegistry.phaseOne().defaultPack;

  bool _hasSavedGame = false;
  bool _saveStateLoaded = false;

  @override
  void initState() {
    super.initState();
    _refreshSavedGame();
    if (widget.enableResourceWarmup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _warmupResources());
    }
  }

  Future<void> _refreshSavedGame() async {
    final hasSave =
        await (widget.hasSavedGame ?? _storageService.hasSavedGame)();
    if (!mounted) return;
    setState(() {
      _hasSavedGame = hasSave;
      _saveStateLoaded = true;
    });
  }

  Future<void> _warmupResources() async {
    final settings = await _storageService.loadSettings();
    if (!mounted || !settings.resourceWarmupEnabled) return;
    await _resourceWarmupService.warmup(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _themePack.colors;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.65, -0.85),
            radius: 1.5,
            colors: [colors.paperRaised, colors.paperBase],
          ),
        ),
        child: CustomPaint(
          painter: _PaperGrainPainter(colors.divider),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = AdaptiveBreakpoints.contentMaxWidth(
                  constraints.maxWidth,
                );
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: _themePack.spacing.large,
                      vertical: _themePack.spacing.extraLarge,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        children: [
                          _buildHeader(),
                          SizedBox(height: _themePack.spacing.extraLarge),
                          _buildPrimaryActions(constraints.maxWidth),
                          SizedBox(height: _themePack.spacing.large),
                          _buildUtilities(),
                          SizedBox(height: _themePack.spacing.large),
                          Text(
                            '现代东方棋艺 · 开发版本 0.1.0',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = _themePack.colors;
    return Semantics(
      header: true,
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: colors.paperRaised,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.bronze, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colors.inkPrimary.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: GameIcon(
              size: 62,
              gridColor: colors.jade,
              showPieces: true,
            ),
          ),
          const SizedBox(height: 20),
          Text('四子棋', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          Text(
            '移 · 围 · 取 · 胜',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.cinnabar,
                  letterSpacing: 6,
                ),
          ),
          const SizedBox(height: 12),
          Container(width: 44, height: 2, color: colors.bronze),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(double width) {
    final actions = <Widget>[
      if (_saveStateLoaded && _hasSavedGame)
        _ModeCard(
          key: const Key('continue_game_button'),
          themePack: _themePack,
          icon: Icons.play_arrow_rounded,
          title: '继续游戏',
          subtitle: '从上次落子继续',
          emphasized: true,
          onTap: () => _openGame(const GamePage(resumeSavedGame: true)),
        ),
      _ModeCard(
        themePack: _themePack,
        icon: Icons.people_outline_rounded,
        title: '双人对战',
        subtitle: '同屏轮流落子',
        onTap: () => _openGame(const GamePage(mode: GameMode.pvp)),
      ),
      _ModeCard(
        themePack: _themePack,
        icon: Icons.smart_toy_outlined,
        title: '人机对战',
        subtitle: '简单 · 中等 · 困难',
        onTap: _showDifficultyDialog,
      ),
      _ModeCard(
        themePack: _themePack,
        icon: Icons.wifi_tethering_rounded,
        title: '局域网对战',
        subtitle: '同一网络面对面对弈',
        onTap: () => _openPage(const LanLobbyPage()),
      ),
    ];

    if (AdaptiveBreakpoints.homeColumnCount(width) == 1) {
      return Column(
        children: actions
            .expand((action) => [action, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions,
    );
  }

  Widget _buildUtilities() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _UtilityButton(
          icon: Icons.insights_outlined,
          label: '战绩',
          onPressed: () => _openPage(const StatisticsPage()),
        ),
        _UtilityButton(
          icon: Icons.menu_book_outlined,
          label: '规则',
          onPressed: () => _openPage(const RulesPage()),
        ),
        _UtilityButton(
          icon: Icons.tune_rounded,
          label: '设置',
          onPressed: () => _openPage(const SettingsPage()),
        ),
      ],
    );
  }

  Future<void> _openGame(GamePage page) async {
    await _openPage(page);
    await _refreshSavedGame();
  }

  Future<void> _openPage(Widget page) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _showDifficultyDialog() async {
    final difficulty = await showDialog<String>(
      context: context,
      builder: (context) => const AlertDialog(
        title: const Text('选择棋力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DifficultyTile(value: 'easy', title: '简单', subtitle: '熟悉规则与走法'),
            _DifficultyTile(value: 'medium', title: '中等', subtitle: '平衡思考与速度'),
            _DifficultyTile(value: 'hard', title: '困难', subtitle: '更深入地计算局面'),
          ],
        ),
      ),
    );
    if (!mounted || difficulty == null) return;
    await _openGame(
      GamePage(mode: GameMode.pve, aiDifficulty: difficulty),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.themePack,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final ThemePack themePack;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = themePack.colors;
    return Semantics(
      button: true,
      label: '$title，$subtitle',
      child: Material(
        color: emphasized ? colors.jade : colors.paperRaised,
        borderRadius: BorderRadius.circular(themePack.shapes.panelRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(themePack.shapes.panelRadius),
          child: Container(
            constraints: BoxConstraints(
              minHeight: themePack.spacing.minimumTapTarget + 28,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(themePack.shapes.panelRadius),
              border: Border.all(
                color: emphasized ? colors.jade : colors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: emphasized
                        ? colors.paperRaised.withValues(alpha: 0.14)
                        : colors.paperBase,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: emphasized ? colors.paperRaised : colors.jade,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: emphasized
                                      ? colors.paperRaised
                                      : colors.inkPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: emphasized
                                  ? colors.paperRaised.withValues(alpha: 0.78)
                                  : colors.inkMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: emphasized ? colors.paperRaised : colors.bronze,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final String value;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 0.6;
    for (double y = 28; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 5), paint);
    }
  }

  @override
  bool shouldRepaint(_PaperGrainPainter oldDelegate) =>
      oldDelegate.color != color;
}
