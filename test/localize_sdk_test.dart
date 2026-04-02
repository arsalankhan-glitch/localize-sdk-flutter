import 'package:flutter_localize_sdk/src/cache.dart';
import 'package:flutter_localize_sdk/src/config.dart';
import 'package:flutter_localize_sdk/src/fetcher.dart';
import 'package:flutter_localize_sdk/src/localize_sdk_impl.dart';
import 'package:flutter_localize_sdk/src/localize_store.dart';
import 'package:flutter_test/flutter_test.dart';

typedef VoidCallback = void Function();

void main() {
  group('LocalizeSDKImpl', () {
    late LocalizeSDKImpl sdk;
    late _FakeCache fakeCache;

    const testStore = LocalizeStore(
      simple: {
        'en': {'welcome': 'Welcome!', 'greeting': 'Hello, %s!'},
        'ar': {'welcome': 'مرحبا'},
      },
      plural: {
        'en': {'items_count': {'one': '1 item', 'other': '%d items'}},
      },
    );

    setUp(() async {
      fakeCache = _FakeCache();
      fakeCache.savedStore = testStore; // Simulate cache from previous fetch

      sdk = LocalizeSDKImpl(
        config: const LocalizeConfig(
          apiKey: 'test_key',
          fallbackLocale: 'en',
        ),
        fetcher: _FakeFetcher(testStore),
        cache: fakeCache,
        localLoader: () async => const LocalizeStore(),
      );
      await sdk.init();
    });

    test('getString returns value for current locale', () {
      sdk.locale = 'en';
      expect(sdk.getString('welcome'), 'Welcome!');
    });

    test('getString returns key when missing', () {
      sdk.locale = 'en';
      expect(sdk.getString('missing_key'), 'missing_key');
    });

    test('getString falls back to fallbackLocale when key missing in current', () {
      sdk.locale = 'ar';
      // 'greeting' exists in en but not ar
      expect(sdk.getString('greeting'), 'Hello, %s!');
    });

    test('getString interpolates args', () {
      sdk.locale = 'en';
      expect(sdk.getString('greeting', args: ['John']), 'Hello, John!');
    });

    test('getPlural returns correct form for count 1', () {
      sdk.locale = 'en';
      expect(sdk.getPlural('items_count', 1), '1 item');
    });

    test('getPlural returns other form for count 5', () {
      sdk.locale = 'en';
      expect(sdk.getPlural('items_count', 5), '5 items');
    });

    test('getPlural returns key when plural key missing', () {
      sdk.locale = 'en';
      expect(sdk.getPlural('missing_plural', 1), 'missing_plural');
    });

    test('getString with empty args does not interpolate', () {
      sdk.locale = 'en';
      expect(sdk.getString('greeting', args: []), 'Hello, %s!');
    });

    test('getString with multiple placeholders interpolates in order', () async {
      const multiStore = LocalizeStore(
        simple: {'en': {'fmt': 'A=%s B=%d C=%@'}},
        plural: {},
      );
      final multiCache = _FakeCache();
      multiCache.savedStore = multiStore;
      final multiSdk = LocalizeSDKImpl(
        config: const LocalizeConfig(apiKey: 't', fallbackLocale: 'en'),
        fetcher: _FakeFetcher(multiStore),
        cache: multiCache,
        localLoader: () async => const LocalizeStore(),
      );
      await multiSdk.init();
      multiSdk.locale = 'en';
      expect(
        multiSdk.getString('fmt', args: ['x', 2, 'y']),
        'A=x B=2 C=y',
      );
    });

    test('refresh debounces concurrent calls', () async {
      var fetchCount = 0;
      final slowFetcher = _CountingFetcher(testStore, () => fetchCount++);

      final debounceSdk = LocalizeSDKImpl(
        config: const LocalizeConfig(apiKey: 't'),
        fetcher: slowFetcher,
        cache: fakeCache,
        localLoader: () async => const LocalizeStore(),
      );
      await debounceSdk.init();
      // Init is API-first: 1 fetch. Then 3 refresh() calls: only 1 runs (debounced).
      final fetchCountAfterInit = fetchCount;

      debounceSdk.refresh();
      debounceSdk.refresh();
      debounceSdk.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(fetchCount, fetchCountAfterInit + 1);
    });

    test('init loads from cache when available', () async {
      final cache = _FakeCache();
      cache.savedStore = testStore;

      final sdk2 = LocalizeSDKImpl(
        config: const LocalizeConfig(apiKey: 'test'),
        cache: cache,
        localLoader: () async => const LocalizeStore(),
      );
      await sdk2.init();

      expect(sdk2.getString('welcome'), 'Welcome!');
    });
  });
}

class _FakeFetcher extends LocalizeFetcher {
  final LocalizeStore store;

  _FakeFetcher(this.store) : super(const LocalizeConfig(apiKey: 'test'));

  @override
  Future<LocalizeStore?> fetch() async => store;
}

class _CountingFetcher extends LocalizeFetcher {
  final LocalizeStore store;
  final VoidCallback onFetch;

  _CountingFetcher(this.store, this.onFetch)
      : super(const LocalizeConfig(apiKey: 'test'));

  @override
  Future<LocalizeStore?> fetch() async {
    onFetch();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return store;
  }
}

class _FakeCache extends LocalizeCache {
  LocalizeStore? savedStore;

  _FakeCache() : super(const LocalizeConfig(apiKey: 'test'));

  @override
  Future<LocalizeStore?> load(String locale) async => savedStore;

  @override
  Future<void> save(LocalizeStore store) async {
    savedStore = store.deepCopy();
  }
}
