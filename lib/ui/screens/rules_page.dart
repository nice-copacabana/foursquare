import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme_pack.dart';
import '../../theme/theme_pack_registry.dart';
import 'interactive_tutorial_page.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pack = ThemePackRegistry.phaseOne().defaultPack;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rulesTitle)),
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
            label: Text(l10n.startInteractiveTutorial),
          ),
          const SizedBox(height: 16),
          _RuleSection(
            number: l10n.rulesSectionOne,
            title: l10n.rulesBoardSection,
            children: [
              _RuleLine(text: l10n.rulesBoardLine1),
              _RuleLine(text: l10n.rulesBoardLine2),
              _RuleLine(text: l10n.rulesBoardLine3),
              _RuleLine(text: l10n.rulesBoardLine4),
            ],
          ),
          const SizedBox(height: 12),
          _RuleSection(
            number: l10n.rulesSectionTwo,
            title: l10n.rulesCaptureSection,
            children: [
              Text(l10n.rulesCaptureIntro),
              const SizedBox(height: 12),
              const _PatternRow(
                pattern: [
                  _PatternCell.own,
                  _PatternCell.own,
                  _PatternCell.enemy,
                  _PatternCell.empty,
                ],
              ),
              const _PatternRow(
                pattern: [
                  _PatternCell.empty,
                  _PatternCell.own,
                  _PatternCell.own,
                  _PatternCell.enemy,
                ],
              ),
              const _PatternRow(
                pattern: [
                  _PatternCell.empty,
                  _PatternCell.enemy,
                  _PatternCell.own,
                  _PatternCell.own,
                ],
              ),
              const _PatternRow(
                pattern: [
                  _PatternCell.enemy,
                  _PatternCell.own,
                  _PatternCell.own,
                  _PatternCell.empty,
                ],
              ),
              const SizedBox(height: 12),
              _RuleLine(text: l10n.rulesCaptureLine1),
              _RuleLine(text: l10n.rulesCaptureLine2),
              _RuleLine(text: l10n.rulesCaptureLine3),
              _RuleLine(text: l10n.rulesCaptureLine4),
            ],
          ),
          const SizedBox(height: 12),
          _RuleSection(
            number: l10n.rulesSectionThree,
            title: l10n.rulesEndingSection,
            children: [
              _RuleLine(text: l10n.rulesEndingLine1),
              _RuleLine(text: l10n.rulesEndingLine2),
              _RuleLine(text: l10n.rulesEndingLine3),
              _RuleLine(text: l10n.rulesEndingLine4),
              _RuleLine(text: l10n.rulesEndingLine5),
            ],
          ),
          const SizedBox(height: 12),
          _RuleSection(
            number: l10n.rulesSectionFour,
            title: l10n.rulesUndoSection,
            children: [
              _RuleLine(text: l10n.rulesUndoLine1),
              _RuleLine(text: l10n.rulesUndoLine2),
              _RuleLine(text: l10n.rulesUndoLine3),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.rulesHeroTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.paperRaised,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.rulesHeroDescription,
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

  final List<_PatternCell> pattern;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label(_PatternCell cell) => switch (cell) {
          _PatternCell.own => l10n.ownPiece,
          _PatternCell.enemy => l10n.enemyPiece,
          _PatternCell.empty => l10n.emptyCell,
        };
    return Semantics(
      label: pattern.map(label).join(', '),
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
                      _PatternCell.own =>
                        Theme.of(context).colorScheme.primaryContainer,
                      _PatternCell.enemy =>
                        Theme.of(context).colorScheme.errorContainer,
                      _PatternCell.empty =>
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    },
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(label(cell)),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

enum _PatternCell { own, enemy, empty }
