import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'localize_store.dart';

/// Disk cache for localization data.
/// Path: {getApplicationSupportDirectory()}/localize_{hash}_{platform}_{locale}.json
class LocalizeCache {
  final LocalizeConfig config;
  final String _cachePrefix;

  LocalizeCache(this.config)
      : _cachePrefix =
            'localize_${_hashPrefix(config.apiKey)}_${config.platform}';

  static String _hashPrefix(String apiKey) {
    final bytes = utf8.encode(apiKey);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  Future<File> _getCacheFile(String locale) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, '${_cachePrefix}_$locale.json'));
  }

  Future<File> _getLegacyCacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, '$_cachePrefix.json'));
  }

  /// Load locale from disk. Returns null if file doesn't exist or is corrupted.
  Future<LocalizeStore?> load(String locale) async {
    try {
      final file = await _getCacheFile(locale);
      if (!await file.exists()) return _tryMigrateFromLegacy(locale);

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;
      return _parseLocaleFile(json, locale);
    } catch (_) {
      return null;
    }
  }

  Future<LocalizeStore?> _tryMigrateFromLegacy(String locale) async {
    try {
      final legacyFile = await _getLegacyCacheFile();
      if (!await legacyFile.exists()) return null;

      final content = await legacyFile.readAsString();
      if (content.isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;
      final full = _parseLegacyStore(json);
      if (full == null) return null;

      await save(full);
      await legacyFile.delete();

      final simple = full.simple[locale] != null ? {locale: full.simple[locale]!} : <String, Map<String, String>>{};
      final plural = full.plural[locale] != null ? {locale: full.plural[locale]!} : <String, Map<String, Map<String, String>>>{};
      return LocalizeStore(simple: simple, plural: plural);
    } catch (_) {
      return null;
    }
  }

  LocalizeStore? _parseLocaleFile(Map<String, dynamic> json, String locale) {
    try {
      final simpleRaw = json['simple'] as Map<String, dynamic>? ?? {};
      final pluralRaw = json['plural'] as Map<String, dynamic>? ?? {};
      final simple = <String, String>{};
      for (final e in simpleRaw.entries) {
        if (e.value is String) simple[e.key] = e.value;
      }
      final plural = <String, Map<String, String>>{};
      for (final keyEntry in pluralRaw.entries) {
        final forms = keyEntry.value;
        if (forms is Map) {
          final formMap = <String, String>{};
          for (final formEntry in (forms as Map<String, dynamic>).entries) {
            if (formEntry.value is String) {
              formMap[formEntry.key] = formEntry.value;
            }
          }
          plural[keyEntry.key] = formMap;
        }
      }
      return LocalizeStore(
        simple: {locale: simple},
        plural: {locale: plural},
      );
    } catch (_) {
      return null;
    }
  }

  LocalizeStore? _parseLegacyStore(Map<String, dynamic> json) {
    try {
      final languages = json['languages'] as Map<String, dynamic>? ?? {};
      final simple = <String, Map<String, String>>{};
      final plural = <String, Map<String, Map<String, String>>>{};

      for (final langEntry in languages.entries) {
        final langData = langEntry.value as Map<String, dynamic>? ?? {};
        final simpleRaw = langData['simple'] as Map<String, dynamic>? ?? {};
        final pluralRaw = langData['plural'] as Map<String, dynamic>? ?? {};

        simple[langEntry.key] = {};
        for (final e in simpleRaw.entries) {
          if (e.value is String) {
            simple[langEntry.key]![e.key] = e.value;
          }
        }

        plural[langEntry.key] = {};
        for (final keyEntry in pluralRaw.entries) {
          final forms = keyEntry.value;
          if (forms is Map) {
            final formMap = <String, String>{};
            for (final formEntry in (forms as Map<String, dynamic>).entries) {
              if (formEntry.value is String) {
                formMap[formEntry.key] = formEntry.value;
              }
            }
            plural[langEntry.key]![keyEntry.key] = formMap;
          }
        }
      }

      return LocalizeStore(simple: simple, plural: plural);
    } catch (_) {
      return null;
    }
  }

  /// Save store to disk (one file per locale).
  Future<void> save(LocalizeStore store) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final allLocales = <String>{...store.simple.keys, ...store.plural.keys};

      for (final locale in allLocales) {
        final json = {
          'locale': locale,
          'simple': store.simple[locale] ?? {},
          'plural': store.plural[locale] ?? {},
        };
        final file = File(p.join(dir.path, '${_cachePrefix}_$locale.json'));
        await file.writeAsString(jsonEncode(json));
      }
    } catch (_) {
      // Silently fail; cache is best-effort
    }
  }
}
