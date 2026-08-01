import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/audio_settings.dart';

void main() {
  test('voice output is disabled by default', () {
    expect(AudioSettings.defaultSettings.voiceEnabled, isFalse);
  });

  test('legacy audio settings without a voice preference stay disabled', () {
    final settings = AudioSettings.fromMap(const {
      'soundEnabled': true,
      'musicEnabled': true,
    });

    expect(settings.voiceEnabled, isFalse);
  });
}
