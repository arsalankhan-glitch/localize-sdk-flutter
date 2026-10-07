import 'package:flutter_localize_sdk/src/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizeLogEntry', () {
    test('toPrettyString includes method and url', () {
      const entry = LocalizeLogEntry(
        method: 'GET',
        url: 'https://api.example.com/export',
        headers: {'X-API-Key': '***'},
      );
      final str = entry.toPrettyString();

      expect(str, contains('GET'));
      expect(str, contains('https://api.example.com/export'));
      expect(str, contains('X-API-Key'));
    });

    test('toPrettyString includes status when present', () {
      const entry = LocalizeLogEntry(
        method: 'GET',
        url: 'https://api.example.com',
        headers: {},
        statusCode: 200,
      );
      expect(entry.toPrettyString(), contains('200'));
    });

    test('toPrettyString includes error when present', () {
      const entry = LocalizeLogEntry(
        method: 'GET',
        url: 'https://api.example.com',
        headers: {},
        error: 'Connection refused',
      );
      expect(entry.toPrettyString(), contains('Connection refused'));
    });

    test('toString equals toPrettyString', () {
      const entry = LocalizeLogEntry(
        method: 'GET',
        url: 'https://api.example.com',
        headers: {},
      );
      expect(entry.toString(), entry.toPrettyString());
    });
  });

  group('LocalizeConfig', () {
    test('defaults are correct', () {
      const config = LocalizeConfig(apiKey: 'pk');

      expect(config.platform, 'flutter');
      expect(config.baseUrl, 'https://localize-api.adres.ae');
      expect(config.timeoutSeconds, 10);
      expect(config.enableLogging, true);
    });

    test('custom values are applied', () {
      const config = LocalizeConfig(
        apiKey: 'pk',
        platform: 'ios',
        baseUrl: 'https://custom.example.com',
        fallbackLocale: 'ar',
        timeoutSeconds: 30,
        enableLogging: false,
      );

      expect(config.platform, 'ios');
      expect(config.baseUrl, 'https://custom.example.com');
      expect(config.fallbackLocale, 'ar');
      expect(config.timeoutSeconds, 30);
      expect(config.enableLogging, false);
    });
  });
}
