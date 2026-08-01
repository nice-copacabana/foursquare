import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/theme/packs/modern_eastern_theme_pack.dart';
import 'package:foursquare/theme/theme_pack_registry.dart';

void main() {
  test('phase one exposes only modern eastern and safely falls back to it', () {
    final registry = ThemePackRegistry.phaseOne();

    expect(registry.availablePacks, hasLength(1));
    expect(registry.defaultPack.id, 'modern_eastern');
    expect(registry.resolve('modern_eastern'), same(registry.defaultPack));
    expect(registry.resolve('future_theme'), same(registry.defaultPack));
    expect(registry.resolve(null), same(registry.defaultPack));
  });

  test('registry rejects duplicate IDs and an unregistered default', () {
    expect(
      () => ThemePackRegistry(
        packs: [modernEasternThemePack, modernEasternThemePack],
        defaultPackId: modernEasternThemePack.id,
      ),
      throwsArgumentError,
    );
    expect(
      () => ThemePackRegistry(
        packs: [modernEasternThemePack],
        defaultPackId: 'missing',
      ),
      throwsArgumentError,
    );
  });
}
