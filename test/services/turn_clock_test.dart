import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/turn_clock.dart';

void main() {
  test('60秒边界前不超时，到达边界立即超时', () {
    final startedAt = DateTime.utc(2026, 8, 1, 12);
    final clock = TurnClock.started(startedAt);

    expect(
      clock.isExpiredAt(startedAt.add(const Duration(milliseconds: 59999))),
      isFalse,
    );
    expect(
      clock.isExpiredAt(startedAt.add(const Duration(seconds: 60))),
      isTrue,
    );
  });

  test('离线对局退到后台后暂停并从剩余时间恢复', () {
    final startedAt = DateTime.utc(2026, 8, 1, 12);
    final paused = TurnClock.started(startedAt).pause(
      startedAt.add(const Duration(seconds: 10)),
    );

    expect(
      paused.remainingAt(startedAt.add(const Duration(minutes: 5))),
      const Duration(seconds: 50),
    );

    final resumed = paused.resume(
      startedAt.add(const Duration(minutes: 5)),
    );
    expect(
      resumed.remainingAt(
        startedAt.add(const Duration(minutes: 5, seconds: 20)),
      ),
      const Duration(seconds: 30),
    );
  });
}
