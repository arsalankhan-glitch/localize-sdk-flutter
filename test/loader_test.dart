import 'package:flutter_localize_sdk/src/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLocalBundleJson', () {
    test('parses valid JSON with simple keys', () {
      const json = '''
      {
        "languages": {
          "en": {
            "simple": {"welcome": "Welcome!", "greeting": "Hi"},
            "plural": {}
          }
        }
      }
      ''';

      final store = parseLocalBundleJson(json);
      expect(store, isNotNull);
      expect(store!.simple['en']!['welcome'], 'Welcome!');
      expect(store.simple['en']!['greeting'], 'Hi');
    });

    test('parses valid JSON with plural keys', () {
      const json = '''
      {
        "languages": {
          "en": {
            "simple": {},
            "plural": {
              "items_count": {
                "one": "1 item",
                "other": "%d items"
              }
            }
          }
        }
      }
      ''';

      final store = parseLocalBundleJson(json);
      expect(store, isNotNull);
      expect(store!.plural['en']!['items_count']!['one'], '1 item');
      expect(store.plural['en']!['items_count']!['other'], '%d items');
    });

    test('returns null for invalid JSON', () {
      final store = parseLocalBundleJson('not json');
      expect(store, isNull);
    });

    test('returns empty store for empty languages', () {
      const json = '{"languages": {}}';
      final store = parseLocalBundleJson(json);
      expect(store, isNotNull);
      expect(store!.isEmpty, true);
    });
  });
}
