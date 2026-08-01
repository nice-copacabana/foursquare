import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory projectRoot;
  late String projectFile;
  late String infoPlist;
  late String releaseGuard;

  setUpAll(() {
    projectRoot = _findProjectRoot();
    projectFile = _readProjectFile(
      projectRoot,
      const ['ios', 'Runner.xcodeproj', 'project.pbxproj'],
    );
    infoPlist = _readProjectFile(
      projectRoot,
      const ['ios', 'Runner', 'Info.plist'],
    );
    releaseGuard = _readProjectFile(
      projectRoot,
      const ['ios', 'scripts', 'verify_release_configuration.sh'],
    );
  });

  group('iOS Phase 2 platform contract', () {
    test('creates the standard Flutter iOS workspace and project', () {
      expect(
        Directory(
          _projectPath(projectRoot, const ['ios', 'Runner.xcworkspace']),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _projectPath(projectRoot, const ['ios', 'Runner.xcodeproj']),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          _projectPath(
            projectRoot,
            const ['ios', 'Runner', 'GeneratedPluginRegistrant.m'],
          ),
        ).existsSync(),
        isTrue,
      );
    });

    test('supports iOS 13 and keeps the development bundle identifier', () {
      expect(projectFile, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;'));
      expect(
        projectFile,
        isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 12.0;')),
      );
      expect(
        projectFile,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.qoder.foursquare;'),
      );
    });

    test('declares LAN access without Phase 4 microphone permissions', () {
      expect(infoPlist, contains('<key>NSLocalNetworkUsageDescription</key>'));
      expect(infoPlist, contains('<key>NSBonjourServices</key>'));
      expect(infoPlist, contains('<string>_foursquare._tcp</string>'));
      expect(infoPlist, isNot(contains('NSMicrophoneUsageDescription')));
      expect(infoPlist, isNot(contains('NSSpeechRecognitionUsageDescription')));
    });

    test(
        'localizes iOS display name and LAN purpose in Chinese English and Japanese',
        () {
      expect(projectFile, contains('InfoPlist.strings in Resources'));
      expect(projectFile, contains('name = InfoPlist.strings;'));

      for (final locale in const ['zh', 'en', 'ja']) {
        expect(projectFile, contains('$locale.lproj/InfoPlist.strings'));
        final strings = _readProjectFile(
          projectRoot,
          ['ios', 'Runner', '$locale.lproj', 'InfoPlist.strings'],
        );
        expect(strings, contains('CFBundleDisplayName'));
        expect(strings, contains('NSLocalNetworkUsageDescription'));
      }
    });

    test('blocks release builds while the development bundle id remains', () {
      expect(projectFile, contains('verify_release_configuration.sh'));
      expect(releaseGuard, contains('CONFIGURATION'));
      expect(releaseGuard, contains('PRODUCT_BUNDLE_IDENTIFIER'));
      expect(releaseGuard, contains('com.qoder.foursquare'));
      expect(releaseGuard, contains('exit 1'));
    });

    test('registers the LAN discovery and diagnostics plugins', () {
      final registrant = _readProjectFile(
        projectRoot,
        const ['ios', 'Runner', 'GeneratedPluginRegistrant.m'],
      );

      expect(registrant, contains('NsdIosPlugin'));
      expect(registrant, contains('SentryFlutterPlugin'));
    });
  });
}

Directory _findProjectRoot() {
  var directory = Directory.current.absolute;

  while (true) {
    if (File(
      _projectPath(directory, const ['pubspec.yaml']),
    ).existsSync()) {
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
  return File(_projectPath(root, pathSegments)).readAsStringSync();
}

String _projectPath(Directory root, List<String> pathSegments) {
  return <String>[root.path, ...pathSegments].join(Platform.pathSeparator);
}
