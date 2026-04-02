import 'package:flutter/scheduler.dart';
import 'package:synchronized/synchronized.dart';

import 'cache.dart';
import 'config.dart';
import 'fetcher.dart';
import 'loader.dart';
import 'localize_store.dart';
import 'plural.dart';
import 'resolver.dart';

/// Internal SDK implementation. Use [LocalizeSDK] for the public API.
class LocalizeSDKImpl {
  final LocalizeConfig config;
  final LocalizeFetcher _fetcher;
  final LocalizeCache _cache;
  final LocalBundleLoader _localLoader;
  final Lock _refreshLock = Lock();
  bool _fetchInProgress = false;

  LocalizeStore _store = const LocalizeStore();
  bool _initialized = false;

  LocalizeSDKImpl({
    required this.config,
    LocalizeFetcher? fetcher,
    LocalizeCache? cache,
    LocalBundleLoader? localLoader,
  })  : _fetcher = fetcher ?? LocalizeFetcher(config),
        _cache = cache ?? LocalizeCache(config),
        _localLoader = localLoader ?? defaultLocalLoader;

  /// Current locale for lookups.
  String locale = 'en';

  /// Initialize: fetch from API first; fall back to cache when offline.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final fetched = await _fetcher.fetch();
    if (fetched != null) {
      await _cache.save(fetched);
      _store = _extractLocale(fetched, locale);
      _scheduleOnKeysUpdated();
      return;
    }

    final cached = await _cache.load(locale);
    final local = await _localLoader();
    _store = LocalizeResolver.resolve(apiOrCache: cached, local: local);
  }

  LocalizeStore _extractLocale(LocalizeStore full, String targetLocale) {
    final simple = <String, Map<String, String>>{};
    final plural = <String, Map<String, Map<String, String>>>{};
    if (full.simple[targetLocale] != null) {
      simple[targetLocale] = full.simple[targetLocale]!;
    }
    if (full.plural[targetLocale] != null) {
      plural[targetLocale] = full.plural[targetLocale]!;
    }
    if (config.fallbackLocale != null && config.fallbackLocale != targetLocale) {
      if (full.simple[config.fallbackLocale!] != null) {
        simple[config.fallbackLocale!] = full.simple[config.fallbackLocale!]!;
      }
      if (full.plural[config.fallbackLocale!] != null) {
        plural[config.fallbackLocale!] = full.plural[config.fallbackLocale!]!;
      }
    }
    return LocalizeStore(simple: simple, plural: plural);
  }

  /// Set locale. Loads from cache in background; onKeysUpdated when done.
  Future<void> setLocaleTo(String newLocale) async {
    locale = newLocale;
    final loaded = await _cache.load(newLocale);
    if (loaded != null) {
      var store = loaded;
      if (config.fallbackLocale != null && config.fallbackLocale != newLocale) {
        final fallbackLoaded = await _cache.load(config.fallbackLocale!);
        if (fallbackLoaded != null) {
          final simple = Map<String, Map<String, String>>.from(store.simple)
            ..addAll(fallbackLoaded.simple);
          final plural = Map<String, Map<String, Map<String, String>>>.from(store.plural)
            ..addAll(fallbackLoaded.plural);
          store = LocalizeStore(simple: simple, plural: plural);
        }
      }
      _store = store;
    } else {
      // Cache has no data for new locale; merge from local bundle (e.g. API returned only one locale)
      final local = await _localLoader();
      if (local != null && !local.isEmpty) {
        final newSimple = Map<String, Map<String, String>>.from(_store.simple);
        final newPlural = Map<String, Map<String, Map<String, String>>>.from(_store.plural);
        if (local.simple[newLocale] != null) newSimple[newLocale] = local.simple[newLocale]!;
        if (local.plural[newLocale] != null) newPlural[newLocale] = local.plural[newLocale]!;
        _store = LocalizeStore(simple: newSimple, plural: newPlural);
      }
    }
    _scheduleOnKeysUpdated();
  }

  /// Refresh from API. Runs in background. Invokes onKeysUpdated when done.
  /// Debounces: concurrent calls are skipped while a fetch is in progress.
  Future<void> refresh() async {
    bool shouldRun = false;
    await _refreshLock.synchronized(() async {
      if (_fetchInProgress) return;
      _fetchInProgress = true;
      shouldRun = true;
    });
    if (!shouldRun) return;

    try {
      final fetched = await _fetcher.fetch();

      if (fetched != null) {
        await _cache.save(fetched);
        _store = _extractLocale(fetched, locale);
      }
    } finally {
      await _refreshLock.synchronized(() async {
        _fetchInProgress = false;
      });
      _scheduleOnKeysUpdated();
    }
  }

  void _scheduleOnKeysUpdated() {
    if (config.onKeysUpdated == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      config.onKeysUpdated!();
    });
  }

  /// Get simple string. O(1) lookup.
  String getString(String key, {List<Object>? args}) {
    String? value = _store.simple[locale]?[key];

    if (value == null && config.fallbackLocale != null) {
      value = _store.simple[config.fallbackLocale!]?[key];
    }

    if (value == null) {
      value = config.bundleFallback?.call(locale, key);
      if (value == null && config.fallbackLocale != null) {
        value = config.bundleFallback?.call(config.fallbackLocale!, key);
      }
    }

    if (value == null) return key;

    return (args != null && args.isNotEmpty)
        ? _interpolate(value, args)
        : value;
  }

  /// Get plural string. O(1) lookup.
  String getPlural(String key, int count) {
    final form = selectPluralForm(locale, count);

    Map<String, String>? pluralMap = _store.plural[locale]?[key];
    if (pluralMap == null && config.fallbackLocale != null) {
      pluralMap = _store.plural[config.fallbackLocale!]?[key];
    }

    if (pluralMap != null) {
      String? value =
          pluralMap[form] ?? pluralMap['other'] ?? pluralMap.values.firstOrNull;
      if (value != null) return _interpolate(value, [count]);
    }

    var value = config.bundleFallback?.call(locale, key, count: count);
    if (value == null && config.fallbackLocale != null) {
      value = config.bundleFallback?.call(config.fallbackLocale!, key, count: count);
    }
    return value ?? key;
  }

  /// Interpolate %s, %d, %@ placeholders with args.
  String _interpolate(String template, List<Object> args) {
    String result = template;
    int argIndex = 0;

    result = result.replaceAllMapped(
      RegExp(r'%[sd@]'),
      (match) {
        if (argIndex >= args.length) return match.group(0)!;
        final arg = args[argIndex++];
        return arg.toString();
      },
    );

    return result;
  }
}
