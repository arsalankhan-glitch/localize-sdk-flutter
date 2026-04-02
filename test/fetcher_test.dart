import 'dart:convert';

import 'package:flutter_localize_sdk/src/config.dart';
import 'package:flutter_localize_sdk/src/fetcher.dart';
import 'package:flutter_localize_sdk/src/localize_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('LocalizeFetcher', () {
    test('returns store on 200 with valid JSON', () async {
      // Arrange
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'pk_test', enableLogging: false),
        client: _FakeClient(
          statusCode: 200,
          body: '''
          {
            "platform": "flutter",
            "languages": {
              "en": {
                "simple": {"welcome": "Hello"},
                "plural": {}
              }
            }
          }
          ''',
        ),
      );

      // Act
      final result = await fetcher.fetch();

      // Assert
      expect(result, isNotNull);
      expect(result!.simple['en']!['welcome'], 'Hello');
    });

    test('returns null on 401', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'bad', enableLogging: false),
        client: _FakeClient(statusCode: 401, body: ''),
      );
      expect(await fetcher.fetch(), isNull);
    });

    test('returns null on 403', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'bad', enableLogging: false),
        client: _FakeClient(statusCode: 403, body: ''),
      );
      expect(await fetcher.fetch(), isNull);
    });

    test('returns null on 404', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'bad', enableLogging: false),
        client: _FakeClient(statusCode: 404, body: ''),
      );
      expect(await fetcher.fetch(), isNull);
    });

    test('returns null on 500', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'pk', enableLogging: false),
        client: _FakeClient(statusCode: 500, body: ''),
      );
      expect(await fetcher.fetch(), isNull);
    });

    test('returns empty store on 200 with empty body', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'pk', enableLogging: false),
        client: _FakeClient(statusCode: 200, body: ''),
      );
      final result = await fetcher.fetch();
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
    });

    test('returns store with plural on valid response', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'pk', enableLogging: false),
        client: _FakeClient(
          statusCode: 200,
          body: '''
          {
            "platform": "flutter",
            "languages": {
              "en": {
                "simple": {},
                "plural": {"items": {"one": "1 item", "other": "%d items"}}
              }
            }
          }
          ''',
        ),
      );
      final result = await fetcher.fetch();
      expect(result, isNotNull);
      expect(result!.plural['en']!['items']!['one'], '1 item');
      expect(result.plural['en']!['items']!['other'], '%d items');
    });

    test('returns null on invalid JSON body', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'pk', enableLogging: false),
        client: _FakeClient(statusCode: 200, body: 'not json'),
      );
      expect(await fetcher.fetch(), isNull);
    });

    test('returns null on network error', () async {
      final fetcher = LocalizeFetcher(
        const LocalizeConfig(apiKey: 'pk', enableLogging: false),
        client: _ThrowingClient(),
      );
      expect(await fetcher.fetch(), isNull);
    });
  });

  group('ExportResponse', () {
    test('fromJson handles missing languages', () {
      final json = {'platform': 'flutter'};
      final resp = ExportResponse.fromJson(json);
      expect(resp.platform, 'flutter');
      expect(resp.languages, isEmpty);
    });

    test('toStore converts to LocalizeStore', () {
      final resp = ExportResponse(
        platform: 'flutter',
        languages: {
          'en': {
            'simple': {'k': 'v'},
            'plural': {'p': {'one': '1', 'other': 'n'}},
          },
        },
      );
      final store = resp.toStore();
      expect(store.simple['en']!['k'], 'v');
      expect(store.plural['en']!['p']!['one'], '1');
    });
  });
}

class _FakeClient extends http.BaseClient {
  final int statusCode;
  final String body;

  _FakeClient({required this.statusCode, required this.body});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream.value(bytes),
      statusCode,
      contentLength: bytes.length,
    );
  }
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw Exception('Network error');
  }
}
