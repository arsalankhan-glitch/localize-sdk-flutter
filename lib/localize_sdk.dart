library localize_sdk;

import 'package:flutter/foundation.dart';

import 'src/config.dart';
import 'src/loader.dart';
import 'src/localize_sdk_impl.dart';

export 'src/config.dart';
export 'src/loader.dart';
export 'src/localize_store.dart';
export 'src/plural.dart';

/// Public API for the Localize Flutter SDK.
///
/// Usage:
/// ```dart
/// void main() async {
///   await LocalizeSDK.configure(
///     apiKey: 'pk_xxx',
///     onKeysUpdated: () => setState(() {}),
///     fallbackLocale: 'en',
///   );
///   runApp(MyApp());
/// }
///
/// // In widget:
/// Text(LocalizeSDK.getString('welcome_message'));
/// Text(LocalizeSDK.getString('greeting', args: ['John']));
/// Text(LocalizeSDK.getPlural('items_count', 5));
/// ```
class LocalizeSDK {
  static LocalizeSDKImpl? _instance;

  /// Configure the SDK. Call once at app startup.
  static Future<void> configure({
    required String apiKey,
    String platform = 'flutter',
    String? baseUrl,
    VoidCallback? onKeysUpdated,
    String? fallbackLocale,
    String? Function(String locale, String key, {int? count})? bundleFallback,
    int timeoutSeconds = 10,
    LocalBundleLoader? localLoader,
    bool enableLogging = true,
  }) async {
    final config = LocalizeConfig(
      apiKey: apiKey,
      platform: platform,
      baseUrl: baseUrl ?? 'https://localize-api.adres.ae',
      onKeysUpdated: onKeysUpdated,
      fallbackLocale: fallbackLocale,
      bundleFallback: bundleFallback,
      timeoutSeconds: timeoutSeconds,
      enableLogging: enableLogging,
    );

    _instance = LocalizeSDKImpl(
      config: config,
      localLoader: localLoader,
    );
    await _instance!.init();
  }

  /// Set the current locale. Loads from cache in background; onKeysUpdated when done.
  static void setLocale(String value) {
    _instance?.setLocaleTo(value);
  }

  /// Get the current locale.
  static String get locale => _instance?.locale ?? 'en';

  /// Refresh keys from API. Runs in background. Invokes onKeysUpdated when done.
  static void refresh() {
    _instance?.refresh();
  }

  /// Get a simple string.
  static String getString(String key, {List<Object>? args}) {
    return _instance?.getString(key, args: args) ?? key;
  }

  /// Get a plural string.
  static String getPlural(String key, int count) {
    return _instance?.getPlural(key, count) ?? key;
  }

  /// Check if SDK is configured.
  static bool get isConfigured => _instance != null;

  /// Reset instance. For testing only; allows tests to verify unconfigured behavior.
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }
}
