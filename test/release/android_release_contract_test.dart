import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String buildScript;
  late String manifest;

  setUpAll(() {
    final projectRoot = _findProjectRoot();
    buildScript = _readProjectFile(
      projectRoot,
      const ['android', 'app', 'build.gradle.kts'],
    );
    manifest = _readProjectFile(
      projectRoot,
      const ['android', 'app', 'src', 'main', 'AndroidManifest.xml'],
    );
  });

  group('Android Phase 1 release contract', () {
    test('pins the supported and target API levels', () {
      expect(buildScript, matches(RegExp(r'compileSdk\s*=\s*36\b')));
      expect(buildScript, matches(RegExp(r'minSdk\s*=\s*26\b')));
      expect(buildScript, matches(RegExp(r'targetSdk\s*=\s*36\b')));
    });

    test('never signs a release with the debug signing configuration', () {
      expect(
        buildScript,
        isNot(contains('signingConfigs.getByName("debug")')),
      );
      expect(
        buildScript,
        contains('signingConfig = signingConfigs.getByName("release")'),
      );
    });

    test('fails release builds when production signing inputs are missing', () {
      for (final variable in const [
        'ANDROID_KEYSTORE_PATH',
        'ANDROID_KEYSTORE_PASSWORD',
        'ANDROID_KEY_ALIAS',
        'ANDROID_KEY_PASSWORD',
      ]) {
        expect(buildScript, contains('System.getenv("$variable")'));
      }

      expect(buildScript, contains('if (missingVariables.isNotEmpty())'));
      expect(
        buildScript,
        contains('Release signing is not configured.'),
      );
      expect(buildScript, contains('throw GradleException('));
      expect(
        buildScript,
        contains('tasks.matching { it.name == "preReleaseBuild" }'),
      );
      expect(buildScript, contains('dependsOn(verifyReleaseSigning)'));
    });

    test('blocks release while the development application id remains', () {
      expect(
        buildScript,
        contains('developmentApplicationId = "com.qoder.foursquare"'),
      );
      expect(
        buildScript,
        contains(
          'android.defaultConfig.applicationId == developmentApplicationId',
        ),
      );
      expect(
        buildScript,
        contains('Release applicationId is still the development placeholder:'),
      );
    });

    test('omits recording permissions and retains LAN permissions', () {
      expect(manifest, isNot(contains('android.permission.RECORD_AUDIO')));
      expect(
        manifest,
        isNot(contains('android.permission.MODIFY_AUDIO_SETTINGS')),
      );

      for (final permission in const [
        'android.permission.INTERNET',
        'android.permission.CHANGE_WIFI_MULTICAST_STATE',
      ]) {
        expect(
          RegExp(RegExp.escape(permission)).allMatches(manifest).length,
          1,
          reason: '$permission must be declared exactly once',
        );
      }
      expect(
        manifest,
        isNot(contains('android.permission.ACCESS_FINE_LOCATION')),
      );
      expect(
        manifest,
        isNot(contains('android.permission.ACCESS_WIFI_STATE')),
      );
    });
  });
}

Directory _findProjectRoot() {
  var directory = Directory.current.absolute;

  while (true) {
    final pubspec = File(
      '${directory.path}${Platform.pathSeparator}pubspec.yaml',
    );
    final androidDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}android',
    );
    if (pubspec.existsSync() && androidDirectory.existsSync()) {
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

String _readProjectFile(Directory root, List<String> pathSegments) {
  final path =
      <String>[root.path, ...pathSegments].join(Platform.pathSeparator);
  return File(path).readAsStringSync();
}
