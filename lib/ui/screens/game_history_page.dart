import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/game_record.dart';
import '../../models/game_result.dart';
import '../../models/piece_type.dart';
import '../../services/storage_service.dart';
import 'game_replay_page.dart';

class GameHistoryPage extends StatefulWidget {
  const GameHistoryPage({super.key, this.loadHistory});

  final Future<List<GameRecord>> Function()? loadHistory;

  @override
  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage> {
  late Future<List<GameRecord>> _records;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _records = (widget.loadHistory ?? StorageService().loadGameHistory)();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<GameRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? const [];
          if (records.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _RecordCard(record: records[index]),
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final GameRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final title = '${_modeLabel(record, l10n)} · '
        '${_resultLabel(record.result, l10n)}';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GameReplayPage(
              moveHistory: record.moves,
              startingPlayer: record.startingPlayer,
              gameTitle: title,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(_resultIcon(record.result), color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.historySummary(
                        record.moves.length,
                        record.moves.fold<int>(
                          0,
                          (sum, move) => sum + move.captureCount,
                        ),
                        _formatTime(record.completedAt, l10n),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  String _modeLabel(GameRecord record, AppLocalizations l10n) {
    return switch (record.mode) {
      'pve' => record.difficulty == null
          ? l10n.modePve
          : l10n.modePveWithDifficulty(
              _difficultyLabel(record.difficulty!, l10n),
            ),
      'lan' => l10n.modeLan,
      _ => l10n.modePvp,
    };
  }

  String _difficultyLabel(String value, AppLocalizations l10n) =>
      switch (value) {
        'easy' => l10n.difficultyEasy,
        'hard' => l10n.difficultyHard,
        _ => l10n.difficultyMedium,
      };

  String _resultLabel(GameResult result, AppLocalizations l10n) {
    if (result.status == GameStatus.draw) return l10n.draw;
    final winner = result.winner;
    if (winner == null) return l10n.resultFinished;
    return l10n.resultSideWins(
      winner == PieceType.black ? l10n.blackSide : l10n.whiteSide,
    );
  }

  IconData _resultIcon(GameResult result) => result.status == GameStatus.draw
      ? Icons.balance_rounded
      : Icons.emoji_events_outlined;

  String _formatTime(DateTime value, AppLocalizations l10n) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return l10n.dateMonthDayTime(
      local.month,
      local.day,
      '${two(local.hour)}:${two(local.minute)}',
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.historyEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(l10n.historyEmptyDescription),
          ],
        ),
      ),
    );
  }
}
