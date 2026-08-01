import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/local_network_service.dart';
import 'package:nsd/nsd.dart' as nsd;

void main() {
  group('resolveLanServiceUri', () {
    test('prefers a resolved IPv4 address', () {
      final uri = resolveLanServiceUri(
        nsd.Service(
          host: 'room.local',
          port: 4040,
          addresses: [InternetAddress('192.168.1.8')],
        ),
      );

      expect(uri.toString(), 'ws://192.168.1.8:4040');
    });

    test('formats a resolved IPv6 address safely', () {
      final uri = resolveLanServiceUri(
        nsd.Service(
          port: 4040,
          addresses: [InternetAddress('2001:db8::8')],
        ),
      );

      expect(uri.toString(), 'ws://[2001:db8::8]:4040');
    });

    test('rejects an unresolved service', () {
      expect(
        () => resolveLanServiceUri(const nsd.Service(port: 4040)),
        throwsFormatException,
      );
    });
  });
}
