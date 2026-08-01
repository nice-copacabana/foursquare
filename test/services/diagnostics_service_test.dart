import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/diagnostics_service.dart';

void main() {
  test('无DSN或用户关闭时不初始化外部诊断SDK', () {
    expect(
      DiagnosticsService.shouldInitialize(enabled: true, dsn: ''),
      isFalse,
    );
    expect(
      DiagnosticsService.shouldInitialize(enabled: true, dsn: null),
      isFalse,
    );
    expect(
      DiagnosticsService.shouldInitialize(
        enabled: false,
        dsn: 'https://public@example.invalid/1',
      ),
      isFalse,
    );
  });

  test('仅在用户开启且提供DSN时初始化', () {
    expect(
      DiagnosticsService.shouldInitialize(
        enabled: true,
        dsn: 'https://public@example.invalid/1',
      ),
      isTrue,
    );
  });
}
