import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'localize_store.dart';

/// API response format from GET /sdk/export
class ExportResponse {
  final String platform;
  final Map<String, Map<String, dynamic>> languages;

  const ExportResponse({
    required this.platform,
    required this.languages,
  });

  factory ExportResponse.fromJson(Map<String, dynamic> json) {
    final languages = <String, Map<String, dynamic>>{};
    final raw = json['languages'] as Map<String, dynamic>? ?? {};
    for (final entry in raw.entries) {
      if (entry.value is Map) {
        languages[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      }
    }
    return ExportResponse(
      platform: json['platform'] as String? ?? 'flutter',
      languages: languages,
    );
  }

  /// Convert to LocalizeStore format
  LocalizeStore toStore() {
    final simple = <String, Map<String, String>>{};
    final plural = <String, Map<String, Map<String, String>>>{};

    for (final langEntry in languages.entries) {
      final langData = langEntry.value;
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
  }
}

/// Fetches localization data from the export endpoint.
class LocalizeFetcher {
  final LocalizeConfig config;
  final http.Client? _client;

  LocalizeFetcher(this.config, {http.Client? client}) : _client = client;

  String get _exportUrl =>
      '${config.baseUrl.replaceAll(RegExp(r'/$'), '')}/sdk/export?platform=${Uri.encodeComponent(config.platform)}';

  Map<String, String> get _headers => {'X-API-Key': config.apiKey};

  /// Headers for logging (API key redacted).
  Map<String, String> get _headersForLog =>
      {'X-API-Key': config.apiKey.isEmpty ? '' : '***'};

  void _log(LocalizeLogEntry entry) {
    if (config.enableLogging) {
      debugPrint(entry.toPrettyString());
    }
  }

  Future<LocalizeStore?> fetch() async {
    final headers = _headers;

    _log(LocalizeLogEntry(
      method: 'GET',
      url: _exportUrl,
      headers: _headersForLog,
    ));

    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            Uri.parse(_exportUrl),
            headers: headers,
          )
          .timeout(Duration(seconds: config.timeoutSeconds));

      _log(LocalizeLogEntry(
        method: 'GET',
        url: _exportUrl,
        headers: _headersForLog,
        statusCode: response.statusCode,
        responseBody: response.body,
      ));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return null;
      }
      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode >= 500) {
        return null;
      }
      if (response.statusCode != 200) {
        return null;
      }

      final body = response.body;
      if (body.isEmpty) {
        return const LocalizeStore().copyWith(
          simple: {},
          plural: {},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final export = ExportResponse.fromJson(json);
      return export.toStore();
    } catch (e, st) {
      _log(LocalizeLogEntry(
        method: 'GET',
        url: _exportUrl,
        headers: _headersForLog,
        error: '$e\n$st',
      ));
      return null;
    } finally {
      if (_client == null) client.close();
    }
  }
}
