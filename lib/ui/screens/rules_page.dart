import 'package:flutter/material.dart';

import '../../theme/theme_pack.dart';
import '../../theme/theme_pack_registry.dart';
import 'interactive_tutorial_page.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pack = ThemePackRegistry.phaseOne().defaultPack;
    return Scaffold(
      appBar: AppBar(title: const Text('对弈规则')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _RuleHero(colors: pack.colors),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const InteractiveTutorialPage(),
              ),
            ),
            icon: const Icon(Icons.touch_app_outlined),
            label: const Text('开始互动教程'),
          ),
          const SizedBox(height: 16),
          const _RuleSection(
            number: '一',
            title: '棋盘与行棋',
            children: [
              _RuleLine(text: '棋盘为 4×4，墨方与玉方各四枚棋子。'),
              _RuleLine(text: '首局随机决定先手；复局双方交替先手。'),
              _RuleLine(text: '每手将一枚己方棋子移到上下左右相邻的空位，不能斜走或越子。'),
              _RuleLine(text: '每回合 60 秒；离线对局进入后台会暂停，局域网对局继续计时。'),
            ],
          ),
          const SizedBox(height: 12),
          const _RuleSection(
            number: '二',
            title: '精确吃子',
            children: [
              Text('只检查本次落子所在的完整四格横线与竖线。以下排列可以吃掉“敌”：'),
              SizedBox(height: 12),
              _PatternRow(pattern: ['己', '己', '敌', '空']),
              _PatternRow(pattern: ['空', '己', '己', '敌']),
              _PatternRow(pattern: ['空', '敌', '己', '己']),
              _PatternRow(pattern: ['敌', '己', '己', '空']),
              SizedBox(height: 12),
              _RuleLine(text: '刚移动的棋子必须属于相邻的两枚己方棋子。'),
              _RuleLine(text: '仅因对手落子而被动形成的排列不触发吃子。'),
              _RuleLine(text: '横向与竖向可同时成立，一手最多吃两枚。'),
              _RuleLine(text: '1100、1110、0110 等非精确排列均不吃子。'),
            ],
          ),
          const SizedBox(height: 12),
          const _RuleSection(
            number: '三',
            title: '胜负与和棋',
            children: [
              _RuleLine(text: '一方棋子只剩一枚或更少时，该方立即判负。'),
              _RuleLine(text: '一方回合开始时没有任何合法移动，该方判负。'),
              _RuleLine(text: '回合倒计时归零，当前行棋方判负。'),
              _RuleLine(text: '连续 50 个单方落子都未吃子时和棋；任意吃子会把计数清零。'),
              _RuleLine(text: '局域网断线有 30 秒重连宽限，超时未恢复则断线方判负。'),
            ],
          ),
          const SizedBox(height: 12),
          const _RuleSection(
            number: '四',
            title: '撤销与记录',
            children: [
              _RuleLine(text: '本地双人每次撤销一手；人机对战按“玩家 + AI”两手成对撤销。'),
              _RuleLine(text: '撤销后可以重做；落下新棋后原重做分支失效。'),
              _RuleLine(text: '局域网对战不提供撤销。完成对局会进入最近 20 局记录，可逐手回放。'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleHero extends StatelessWidget {
  const _RuleHero({required this.colors});

  final AppColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.jade,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '移子成势，精确取子',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.paperRaised,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '所有模式共享同一套规则；界面、AI、回放与局域网均以此为准。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.paperRaised.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.number,
    required this.title,
    required this.children,
  });

  final String number;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  child: Text(number),
                ),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({required this.pattern});

  final List<String> pattern;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: pattern.join('、'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: pattern
              .map(
                (cell) => Container(
                  width: 42,
                  height: 36,
                  margin: const EdgeInsets.only(right: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: switch (cell) {
                      '己' => Theme.of(context).colorScheme.primaryContainer,
                      '敌' => Theme.of(context).colorScheme.errorContainer,
                      _ => Theme.of(context).colorScheme.surfaceContainerLow,
                    },
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(cell),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
