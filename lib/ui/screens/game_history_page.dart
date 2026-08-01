import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近对局'),
        actions: [
          IconButton(
            tooltip: '刷新',
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GameReplayPage(
              moveHistory: record.moves,
              startingPlayer: record.startingPlayer,
              gameTitle:
                  '${_modeLabel(record)} · ${_resultLabel(record.result)}',
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
                      '${_modeLabel(record)} · ${_resultLabel(record.result)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.moves.length} 手 · '
                      '${record.moves.fold<int>(0, (sum, move) => sum + move.captureCount)} 次吃子 · '
                      '${_formatTime(record.completedAt)}',
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

  String _modeLabel(GameRecord record) {
    return switch (record.mode) {
      'pve' =>
        '人机${record.difficulty == null ? '' : ' · ${_difficultyLabel(record.difficulty!)}'}',
      'lan' => '局域网',
      _ => '双人',
    };
  }

  String _difficultyLabel(String value) => switch (value) {
        'easy' => '简单',
        'hard' => '困难',
        _ => '中等',
      };

  String _resultLabel(GameResult result) {
    if (result.status == GameStatus.draw) return '和棋';
    final winner = result.winner;
    if (winner == null) return '已结束';
    return '${winner == PieceType.black ? '墨方' : '玉方'}胜';
  }

  IconData _resultIcon(GameResult result) => result.status == GameStatus.draw
      ? Icons.balance_rounded
      : Icons.emoji_events_outlined;

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.month}月${local.day}日 ${two(local.hour)}:${two(local.minute)}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
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
            Text('尚无已完成对局', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('完成一局后，可在这里查看最近 20 局并逐手回放。'),
          ],
        ),
      ),
    );
  }
}
