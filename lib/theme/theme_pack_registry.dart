import 'dart:collection';

import 'packs/modern_eastern_theme_pack.dart';
import 'theme_pack.dart';

/// Registry seam for built-in theme packs.
///
/// Stored or unknown IDs deliberately resolve to the default pack so a removed
/// theme can never make the game interface unusable.
class ThemePackRegistry {
  ThemePackRegistry._(this._packs, this.defaultPackId);

  factory ThemePackRegistry({
    required Iterable<ThemePack> packs,
    required String defaultPackId,
  }) {
    final indexed = <String, ThemePack>{};
    for (final pack in packs) {
      if (pack.id.trim().isEmpty) {
        throw ArgumentError.value(
          pack.id,
          'packs',
          'Theme ID cannot be empty.',
        );
      }
      if (indexed.containsKey(pack.id)) {
        throw ArgumentError.value(
          pack.id,
          'packs',
          'Duplicate theme ID.',
        );
      }
      indexed[pack.id] = pack;
    }
    if (!indexed.containsKey(defaultPackId)) {
      throw ArgumentError.value(
        defaultPackId,
        'defaultPackId',
        'Default theme must be registered.',
      );
    }
    return ThemePackRegistry._(Map.unmodifiable(indexed), defaultPackId);
  }

  factory ThemePackRegistry.phaseOne() {
    return ThemePackRegistry(
      packs: [modernEasternThemePack],
      defaultPackId: modernEasternThemePack.id,
    );
  }

  final Map<String, ThemePack> _packs;
  final String defaultPackId;

  ThemePack get defaultPack => _packs[defaultPackId]!;

  List<ThemePack> get availablePacks =>
      UnmodifiableListView(_packs.values.toList(growable: false));

  ThemePack resolve(String? id) => _packs[id] ?? defaultPack;
}
