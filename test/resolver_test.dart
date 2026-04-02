import 'package:flutter_localize_sdk/src/localize_store.dart';
import 'package:flutter_localize_sdk/src/resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizeResolver', () {
    test('prefers apiOrCache when non-empty', () {
      const api = LocalizeStore(
        simple: {'en': {'key': 'from_api'}},
        plural: {},
      );
      const local = LocalizeStore(
        simple: {'en': {'key': 'from_local'}},
        plural: {},
      );

      final result = LocalizeResolver.resolve(apiOrCache: api, local: local);
      expect(result.simple['en']!['key'], 'from_api');
    });

    test('falls back to local when apiOrCache is null', () {
      const local = LocalizeStore(
        simple: {'en': {'key': 'from_local'}},
        plural: {},
      );

      final result = LocalizeResolver.resolve(apiOrCache: null, local: local);
      expect(result.simple['en']!['key'], 'from_local');
    });

    test('falls back to local when apiOrCache is empty', () {
      const api = LocalizeStore();
      const local = LocalizeStore(
        simple: {'en': {'key': 'from_local'}},
        plural: {},
      );

      final result = LocalizeResolver.resolve(apiOrCache: api, local: local);
      expect(result.simple['en']!['key'], 'from_local');
    });

    test('returns empty store when both are null/empty', () {
      final result = LocalizeResolver.resolve(
        apiOrCache: null,
        local: null,
      );
      expect(result.isEmpty, true);
    });
  });
}
