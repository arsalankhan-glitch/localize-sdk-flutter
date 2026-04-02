import 'dart:convert';

/// Log entry for a single HTTP request/response.
/// Use [toPrettyString] for formatted output to pass to your logger.
class LocalizeLogEntry {
  final String method;
  final String url;
  final Map<String, String> headers;
  final int? statusCode;
  final String? responseBody;
  final Object? error;

  const LocalizeLogEntry({
    required this.method,
    required this.url,
    required this.headers,
    this.statusCode,
    this.responseBody,
    this.error,
  });

  /// Pretty-formatted string for logging. JSON body is indented.
  String toPrettyString() {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────');
    buffer.writeln('│ Localize SDK');
    buffer.writeln('├─────────────────────────────────────────────────────────');
    buffer.writeln('│ $method $url');
    buffer.writeln('│');
    buffer.writeln('│ Headers:');
    for (final e in headers.entries) {
      buffer.writeln('│   ${e.key}: ${e.value}');
    }
    if (statusCode != null) {
      buffer.writeln('│');
      buffer.writeln('│ Status: $statusCode');
    }
    if (responseBody != null && responseBody!.isNotEmpty) {
      buffer.writeln('│');
      buffer.writeln('│ Response:');
      final pretty = _prettyJson(responseBody!);
      for (final line in pretty.split('\n')) {
        buffer.writeln('│   $line');
      }
    }
    if (error != null) {
      buffer.writeln('│');
      buffer.writeln('│ Error:');
      for (final line in error.toString().split('\n')) {
        buffer.writeln('│   $line');
      }
    }
    buffer.writeln('└─────────────────────────────────────────────────────────');
    return buffer.toString();
  }

  static String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  @override
  String toString() => toPrettyString();
}

/// Configuration for the Localize SDK.
class LocalizeConfig {
  /// Project API key for authenticating with the export endpoint.
  final String apiKey;

  /// Platform identifier (ios, android, web, other, flutter). web/other/flutter return same JSON keys.
  final String platform;

  /// Base URL for the API. Encapsulated in SDK; defaults to production.
  final String baseUrl;

  /// Callback invoked when refresh() completes (success or failure).
  final VoidCallback? onKeysUpdated;

  /// Fallback locale when translation is missing for current locale.
  final String? fallbackLocale;

  /// Optional per-key fallback when key is not in API/cache.
  /// Use for AppLocalizations, ARB, or other bundled strings.
  /// Called with (locale, key) for getString, (locale, key, count) for getPlural.
  final String? Function(String locale, String key, {int? count})? bundleFallback;

  /// Request timeout in seconds. Default 10.
  final int timeoutSeconds;

  /// When true, the SDK prints pretty-formatted request/response to debug console. Default true.
  final bool enableLogging;

  const LocalizeConfig({
    required this.apiKey,
    this.platform = 'flutter',
    this.baseUrl = 'https://localize-dev-api.adres.ae',
    this.onKeysUpdated,
    this.fallbackLocale,
    this.bundleFallback,
    this.timeoutSeconds = 10,
    this.enableLogging = true,
  });
}

typedef VoidCallback = void Function();
