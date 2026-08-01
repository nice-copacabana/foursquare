import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory projectRoot;
  late Map<String, Map<String, dynamic>> arbs;

  setUpAll(() {
    projectRoot = _findProjectRoot();
    arbs = {
      for (final locale in const ['zh', 'en', 'ja'])
        locale: _readArb(projectRoot, locale),
    };
  });

  group('Phase 2 localization catalogs', () {
    test('all locales expose the same ordinary message keys', () {
      final expectedKeys = _messageKeys(arbs['zh']!);

      for (final entry in arbs.entries) {
        expect(
          _messageKeys(entry.value),
          expectedKeys,
          reason: '${entry.key} message keys must match the template catalog',
        );
      }
    });

    test('placeholder metadata and message parameters stay aligned', () {
      final expectedMetadataKeys = _metadataKeys(arbs['zh']!);

      for (final entry in arbs.entries) {
        expect(
          _metadataKeys(entry.value),
          expectedMetadataKeys,
          reason: '${entry.key} metadata keys must match the template catalog',
        );
      }

      for (final messageKey in _messageKeys(arbs['zh']!)) {
        final expectedPlaceholders = _metadataPlaceholders(
          arbs['zh']!,
          messageKey,
        );
        for (final entry in arbs.entries) {
          final placeholders = _metadataPlaceholders(
            entry.value,
            messageKey,
          );
          expect(
            placeholders.keys.toSet(),
            expectedPlaceholders.keys.toSet(),
            reason: '$messageKey placeholder keys differ for ${entry.key}',
          );
          for (final placeholder in placeholders.keys) {
            expect(
              _placeholderType(placeholders[placeholder]),
              _placeholderType(expectedPlaceholders[placeholder]),
              reason: '$messageKey.$placeholder type differs for ${entry.key}',
            );
          }

          expect(
            _messageParameters(entry.value[messageKey]),
            placeholders.keys.toSet(),
            reason:
                '$messageKey parameters must match its ${entry.key} metadata',
          );
        }
      }
    });

    test('authoritative rule sentinels are translated and non-empty', () {
      const sentinelKeys = <String>[
        'rulesBoardLine1',
        'rulesCaptureIntro',
        'ownPiece',
        'enemyPiece',
        'emptyCell',
        'rulesCaptureLine1',
        'rulesBoardLine4',
        'rulesEndingLine4',
        'rulesEndingLine5',
        'rulesUndoLine1',
        'rulesUndoLine2',
        'rulesUndoLine3',
      ];

      for (final entry in arbs.entries) {
        for (final key in sentinelKeys) {
          expect(
            entry.value[key],
            isA<String>().having(
              (value) => value.trim(),
              'trimmed value',
              isNotEmpty,
            ),
            reason: '$key must be translated for ${entry.key}',
          );
        }

        expect(entry.value['rulesBoardLine1'], contains('4×4'));
        expect(entry.value['rulesBoardLine4'], contains('60'));
        expect(entry.value['rulesEndingLine4'], contains('50'));
        expect(entry.value['rulesEndingLine5'], contains('30'));
      }
    });

    test('rules page presents all four exact capture arrangements', () {
      final source = _readProjectFile(
        projectRoot,
        const ['lib', 'ui', 'screens', 'rules_page.dart'],
      ).replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r',(?=[\]\)])'), '');

      for (final arrangement in const [
        '[_PatternCell.own,_PatternCell.own,_PatternCell.enemy,_PatternCell.empty]',
        '[_PatternCell.empty,_PatternCell.own,_PatternCell.own,_PatternCell.enemy]',
        '[_PatternCell.empty,_PatternCell.enemy,_PatternCell.own,_PatternCell.own]',
        '[_PatternCell.enemy,_PatternCell.own,_PatternCell.own,_PatternCell.empty]',
      ]) {
        expect(
          source,
          contains('_PatternRow(pattern:$arrangement)'),
          reason: 'missing exact capture arrangement $arrangement',
        );
      }
    });
  });

  group('Phase 2 production UI localization boundaries', () {
    test('reachable UI never reads a raw GameResult reason', () {
      final rawGameResultReason = RegExp(
        r'\b[A-Za-z_][A-Za-z0-9_]*(?:Result|result)\s*[!?]?\s*\.\s*reason\b',
      );

      for (final path in _reachableProductionUiFiles) {
        final source = _readProjectFile(projectRoot, path);
        expect(
          source,
          isNot(matches(rawGameResultReason)),
          reason: '${path.join('/')} must localize GameEndReason instead of '
              'reading GameResult.reason',
        );
      }
    });

    test('LAN pages do not expose raw errorMessage or exception text', () {
      for (final path in const [
        ['lib', 'ui', 'screens', 'lan', 'lan_lobby_page.dart'],
        ['lib', 'ui', 'screens', 'lan', 'lan_game_page.dart'],
      ]) {
        final source = _readProjectFile(projectRoot, path);
        expect(
          source,
          isNot(matches(RegExp(r'\berrorMessage\b'))),
          reason: '${path.join('/')} must map LAN failures to l10n messages',
        );
        expect(
          source,
          isNot(matches(RegExp(r'\$(?:\{)?e(?:\b|\.)'))),
          reason: '${path.join('/')} must not interpolate raw exceptions',
        );
      }
    });
  });
}

const _reachableProductionUiFiles = <List<String>>[
  ['lib', 'ui', 'screens', 'home_page.dart'],
  ['lib', 'ui', 'screens', 'onboarding_page.dart'],
  ['lib', 'ui', 'screens', 'rules_page.dart'],
  ['lib', 'ui', 'screens', 'interactive_tutorial_page.dart'],
  ['lib', 'ui', 'screens', 'game_page.dart'],
  ['lib', 'ui', 'screens', 'game_history_page.dart'],
  ['lib', 'ui', 'screens', 'game_replay_page.dart'],
  ['lib', 'ui', 'screens', 'statistics_page.dart'],
  ['lib', 'ui', 'screens', 'settings_page.dart'],
  ['lib', 'ui', 'screens', 'lan', 'lan_lobby_page.dart'],
  ['lib', 'ui', 'screens', 'lan', 'lan_game_page.dart'],
  ['lib', 'ui', 'widgets', 'game_info_panel.dart'],
  ['lib', 'ui', 'widgets', 'game_over_dialog.dart'],
];

Directory _findProjectRoot() {
  var directory = Directory.current.absolute;

  while (true) {
    final pubspec = File(
      '${directory.path}${Platform.pathSeparator}pubspec.yaml',
    );
    final l10nDirectory = Directory(
      <String>[
        directory.path,
        'lib',
        'l10n',
      ].join(Platform.pathSeparator),
    );
    if (pubspec.existsSync() && l10nDirectory.existsSync()) {
      return directory;
    }

    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'Could not locate the project root from ${Directory.current.path}.',
      );
    }
    directory = parent;
  }
}

Map<String, dynamic> _readArb(Directory root, String locale) {
  final file = File(
    <String>[
      root.path,
      'lib',
      'l10n',
      'app_$locale.arb',
    ].join(Platform.pathSeparator),
  );
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

String _readProjectFile(Directory root, List<String> pathSegments) {
  final path = <String>[
    root.path,
    ...pathSegments,
  ].join(Platform.pathSeparator);
  return File(path).readAsStringSync();
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

Set<String> _metadataKeys(Map<String, dynamic> arb) => arb.keys
    .where((key) => key.startsWith('@') && !key.startsWith('@@'))
    .toSet();

Map<String, dynamic> _metadataPlaceholders(
  Map<String, dynamic> arb,
  String messageKey,
) {
  final metadata = arb['@$messageKey'];
  if (metadata is! Map<String, dynamic>) {
    return const {};
  }
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map<String, dynamic>) {
    return const {};
  }
  return placeholders;
}

Object? _placeholderType(Object? metadata) {
  if (metadata is Map<String, dynamic>) {
    return metadata['type'];
  }
  return null;
}

Set<String> _messageParameters(Object? message) {
  if (message is! String) {
    return const {};
  }
  return RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)(?=\s*[,}])')
      .allMatches(message)
      .map((match) => match.group(1)!)
      .toSet();
}
