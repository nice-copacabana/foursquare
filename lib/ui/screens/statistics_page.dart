library;

import 'package:flutter/material.dart';

import '../../models/game_record.dart';
import '../../models/game_result.dart';
import '../../models/piece_type.dart';
import '../../services/storage_service.dart';
import '../layouts/adaptive_breakpoints.dart';
import 'game_history_page.dart';

/// Presents lifetime activity separately from mode-specific recent results.
///
/// [GameStatistics] is a cross-mode aggregate. In particular, local PvP stores
/// every decisive match as a win, so its win/loss fields must not be presented
/// as a player's personal record. Player-perspective results are derived only
/// from the recent [GameRecord] archive, where the mode and local colour are
/// available.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    this.loadStatistics,
    this.loadHistory,
    this.resetStatistics,
  });

  final Future<GameStatistics> Function()? loadStatistics;
  final Future<List<GameRecord>> Function()? loadHistory;
  final Future<bool> Function()? resetStatistics;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  GameStatistics? _statistics;
  List<GameRecord> _records = const [];
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final storage = StorageService();
      final statistics =
          await (widget.loadStatistics ?? storage.loadStatistics)();
      final records = await (widget.loadHistory ?? storage.loadGameHistory)();
      if (!mounted) return;
      setState(() {
        _statistics = statistics;
        _records = GameRecord.retainRecent(records);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameHistoryPage(loadHistory: widget.loadHistory),
      ),
    );
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置统计'),
        content: const Text(
          '将清空累计统计和最近 20 局回放。此操作无法撤销，确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final storage = StorageService();
    final succeeded =
        await (widget.resetStatistics ?? storage.resetStatistics)();
    if (!mounted) return;
    if (succeeded) {
      await _loadData();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(succeeded ? '统计与最近对局已重置' : '重置失败，请稍后重试')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对局统计'),
        actions: [
          IconButton(
            onPressed: _openHistory,
            tooltip: '最近对局与回放',
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            onPressed: _loadData,
            tooltip: '刷新',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _resetData,
            tooltip: '重置统计',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: switch ((_isLoading, _loadError, _statistics)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (false, final error?, _) => _LoadError(
            error: error,
            onRetry: _loadData,
          ),
        (false, _, final statistics?) => _StatisticsContent(
            statistics: statistics,
            records: _records,
            onRefresh: _loadData,
          ),
        _ => _LoadError(
            error: StateError('统计数据不可用'),
            onRetry: _loadData,
          ),
      },
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({
    required this.statistics,
    required this.records,
    required this.onRefresh,
  });

  final GameStatistics statistics;
  final List<GameRecord> records;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final pvp = _ModeSummary.forPvp(records);
    final pve = _ModeSummary.forLocalPlayer(records, 'pve');
    final lan = _ModeSummary.forLocalPlayer(records, 'lan');

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = AdaptiveBreakpoints.contentMaxWidth(
          constraints.maxWidth,
        );
        final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              32,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverviewPanel(statistics: statistics),
                    const SizedBox(height: 20),
                    _SectionHeading(
                      eyebrow: 'RECENT FORM',
                      title: '最近对局',
                      description: records.isEmpty
                          ? '完成一局后，将在这里按模式呈现结果。'
                          : '仅基于设备内保留的最近 ${records.length} 局，不与累计数据混算。',
                    ),
                    const SizedBox(height: 12),
                    _ModeCards(pvp: pvp, pve: pve, lan: lan),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.statistics});

  final GameStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final averageMoves = statistics.totalGames == 0
        ? '—'
        : (statistics.totalMoves / statistics.totalGames).toStringAsFixed(1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_stories_rounded, color: scheme.primary, size: 28),
            const SizedBox(height: 16),
            Text('棋谱总览', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '记录走过的每一步，不把不同对局模式混成一项输赢。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricTile(
                  label: '累计对局',
                  value: '${statistics.totalGames}',
                  icon: Icons.grid_view_rounded,
                ),
                _MetricTile(
                  label: '累计手数',
                  value: '${statistics.totalMoves}',
                  icon: Icons.gesture_rounded,
                ),
                _MetricTile(
                  label: '平均手数',
                  value: averageMoves,
                  icon: Icons.balance_rounded,
                ),
                _MetricTile(
                  label: '累计吃子',
                  value: '${statistics.totalCaptures}',
                  icon: Icons.adjust_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近落子：${_formatDateTime(statistics.lastPlayedAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: scheme.secondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.titleLarge),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ModeCards extends StatelessWidget {
  const _ModeCards({
    required this.pvp,
    required this.pve,
    required this.lan,
  });

  final _ModeSummary pvp;
  final _ModeSummary pve;
  final _ModeSummary lan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _ModeCard(
                title: '本地双人 · 近 20 局',
                icon: Icons.people_alt_rounded,
                summary: pvp,
                labels: const ('墨方胜', '玉方胜'),
                note: '本地双人按双方棋色记录，不计算个人胜率。',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ModeCard(
                title: '人机对弈 · 近 20 局',
                icon: Icons.smart_toy_rounded,
                summary: pve,
                labels: const ('玩家胜', 'AI 胜'),
                note: '按本机玩家执棋颜色计算。',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ModeCard(
                title: '局域网 · 近 20 局',
                icon: Icons.lan_rounded,
                summary: lan,
                labels: const ('本机胜', '本机负'),
                note: '按本机在联机对局中的执棋颜色计算。',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.icon,
    required this.summary,
    required this.labels,
    required this.note,
  });

  final String title;
  final IconData icon;
  final _ModeSummary summary;
  final (String, String) labels;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OutcomeBadge(label: '${labels.$1} ${summary.wins}'),
                _OutcomeBadge(label: '${labels.$2} ${summary.losses}'),
                _OutcomeBadge(label: '和棋 ${summary.draws}'),
                if (summary.unresolved > 0)
                  _OutcomeBadge(label: '未识别 ${summary.unresolved}'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              summary.total == 0 ? '暂无该模式记录。$note' : note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelLarge),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: scheme.primary),
            const SizedBox(height: 14),
            const Text('统计数据暂时无法读取'),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSummary {
  const _ModeSummary({
    required this.total,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.unresolved,
  });

  factory _ModeSummary.forPvp(Iterable<GameRecord> allRecords) {
    var wins = 0;
    var losses = 0;
    var draws = 0;
    var unresolved = 0;
    final records = allRecords.where((record) => record.mode == 'pvp').toList();
    for (final record in records) {
      if (record.result.status == GameStatus.draw) {
        draws++;
      } else if (record.result.winner == PieceType.black) {
        wins++;
      } else if (record.result.winner == PieceType.white) {
        losses++;
      } else {
        unresolved++;
      }
    }
    return _ModeSummary(
      total: records.length,
      wins: wins,
      losses: losses,
      draws: draws,
      unresolved: unresolved,
    );
  }

  factory _ModeSummary.forLocalPlayer(
    Iterable<GameRecord> allRecords,
    String mode,
  ) {
    var wins = 0;
    var losses = 0;
    var draws = 0;
    var unresolved = 0;
    final records = allRecords.where((record) => record.mode == mode).toList();
    for (final record in records) {
      if (record.result.status == GameStatus.draw) {
        draws++;
      } else if (record.humanPlayer == null || record.result.winner == null) {
        unresolved++;
      } else if (record.result.winner == record.humanPlayer) {
        wins++;
      } else {
        losses++;
      }
    }
    return _ModeSummary(
      total: records.length,
      wins: wins,
      losses: losses,
      draws: draws,
      unresolved: unresolved,
    );
  }

  final int total;
  final int wins;
  final int losses;
  final int draws;
  final int unresolved;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '尚无记录';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$month.$day  $hour:$minute';
}
