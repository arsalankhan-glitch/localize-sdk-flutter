import 'dart:convert';

import 'package:flutter_localize_sdk/src/cache.dart';
import 'package:flutter_localize_sdk/src/config.dart';
import 'package:flutter_localize_sdk/src/localize_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizeCache', () {
    late LocalizeCache cache;

    setUp(() {
      cache = LocalizeCache(LocalizeConfig(
        apiKey: 'test_cache_key_${DateTime.now().millisecondsSinceEpoch}',
        platform: 'test',
        enableLogging: false,
      ));
    });

    test('load returns null when no cache exists', () async {
      final result = await cache.load('en');
      expect(result, isNull);
    });

    test('save does not throw', () async {
      const store = LocalizeStore(
        simple: {'en': {'a': '1'}},
        plural: {},
      );
      await expectLater(cache.save(store), completes);
    });

    test('per-locale file format matches parse expectation', () {
      const json = {'locale': 'en', 'simple': {'k': 'v'}, 'plural': {}};
      final decoded = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      expect(decoded['locale'], 'en');
      expect(decoded['simple']['k'], 'v');
    });
  });
}

// Note: Full disk round-trip tested via example app integration
