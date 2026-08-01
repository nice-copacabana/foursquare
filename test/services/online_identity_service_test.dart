import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/online_identity_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  test('creates one anonymous identity and reuses it across service instances',
      () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    var generated = 0;
    String nextId() => 'device-${++generated}';

    final first = OnlineIdentityService(idGenerator: nextId);
    final second = OnlineIdentityService(idGenerator: nextId);

    expect(await first.getOrCreate(), 'device-1');
    expect(await second.getOrCreate(), 'device-1');
    expect(generated, 1);
  });

  test('reset replaces the local identity', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    var generated = 0;
    final service = OnlineIdentityService(
      idGenerator: () => 'device-${++generated}',
    );

    expect(await service.getOrCreate(), 'device-1');
    expect(await service.reset(), 'device-2');
    expect(await service.getOrCreate(), 'device-2');
  });

  test('replaces a persisted identity that the server cannot accept', () async {
    SharedPreferences.setMockInitialValues(
      const <String, Object>{'online_anonymous_device_id': 'bad value'},
    );
    final service = OnlineIdentityService(
      idGenerator: () => 'device-valid-1',
    );

    expect(await service.getOrCreate(), 'device-valid-1');
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('online_anonymous_device_id'),
      'device-valid-1',
    );
  });

  test('concurrent callers receive the same persisted identity', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    var generated = 0;
    String nextId() => 'device-${++generated}';
    final first = OnlineIdentityService(idGenerator: nextId);
    final second = OnlineIdentityService(idGenerator: nextId);

    final identities = await Future.wait([
      first.getOrCreate(),
      second.getOrCreate(),
      first.getOrCreate(),
    ]);

    expect(identities, everyElement('device-1'));
    expect(generated, 1);
  });

  test('does not return an identity when persistence fails', () async {
    final preferences = MockSharedPreferences();
    when(() => preferences.getString(any())).thenReturn(null);
    when(() => preferences.setString(any(), any()))
        .thenAnswer((_) async => false);
    final service = OnlineIdentityService(
      idGenerator: () => 'device-not-persisted',
      preferencesProvider: () async => preferences,
    );

    expect(
      service.getOrCreate,
      throwsA(isA<OnlineIdentityPersistenceException>()),
    );
  });
}
