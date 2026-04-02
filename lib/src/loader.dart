import 'dart:convert';

import 'localize_store.dart';

/// Loader for local bundled keys (fallback when API/cache unavailable).
/// Accepts custom loaders so devs can point to their own local files.
typedef LocalBundleLoader = Future<LocalizeStore?> Function();

/// Default loader that returns empty store.
/// Apps should provide a custom loader for their bundled JSON/ARB.
Future<LocalizeStore?> defaultLocalLoader() async => const LocalizeStore();

/// Load from a JSON string (e.g. from assets).
LocalizeStore? parseLocalBundleJson(String jsonString) {
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return _parseStore(json);
  } catch (_) {
    return null;
  }
}

LocalizeStore? _parseStore(Map<String, dynamic> json) {
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
