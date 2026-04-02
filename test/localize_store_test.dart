import 'package:flutter_localize_sdk/src/localize_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizeStore', () {
    test('isEmpty when both empty', () {
      expect(const LocalizeStore().isEmpty, true);
    });

    test('isEmpty false when simple has data', () {
      const store = LocalizeStore(
        simple: {'en': {'k': 'v'}},
        plural: {},
      );
      expect(store.isEmpty, false);
    });

    test('isEmpty false when plural has data', () {
      const store = LocalizeStore(
        simple: {},
        plural: {'en': {'k': {'one': '1'}}},
      );
      expect(store.isEmpty, false);
    });

    test('deepCopy preserves data', () {
      const store = LocalizeStore(
        simple: {'en': {'a': '1'}},
        plural: {'en': {'p': {'one': '1', 'other': 'n'}}},
      );
      final copy = store.deepCopy();

      expect(copy.simple['en']!['a'], '1');
      expect(copy.plural['en']!['p']!['one'], '1');
      expect(identical(copy.simple, store.simple), false);
    });

    test('copyWith replaces specified fields', () {
      const store = LocalizeStore(
        simple: {'en': {'k': 'v'}},
        plural: {},
      );
      final updated = store.copyWith(
        simple: {'en': {'k': 'new'}},
      );

      expect(updated.simple['en']!['k'], 'new');
      expect(updated.plural, store.plural);
    });
  });
}
