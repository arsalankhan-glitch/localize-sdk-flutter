# Localize Flutter SDK

[![Version](https://img.shields.io/github/v/tag/arsalankhan-glitch/localize-sdk-flutter?sort=semver&label=version)](https://github.com/arsalankhan-glitch/localize-sdk-flutter/tags) [![License](https://img.shields.io/github/license/arsalankhan-glitch/localize-sdk-flutter)](LICENSE) [![Flutter](https://img.shields.io/badge/Flutter-compatible-02569B.svg)](https://flutter.dev) ![Dart 3.0+](https://img.shields.io/badge/Dart-3.0%2B-0175C2.svg)

## 👋 Introduction

Localize lets your team manage your app's text and translations in one place and update them without shipping a new release. The SDK downloads the latest translations at runtime, caches them on the device, and falls back to the strings bundled in your app when it's offline.

This is the Dart SDK for Flutter apps.

Also available for [iOS](https://github.com/arsalankhan-glitch/localize-sdk-ios) · [Android](https://github.com/arsalankhan-glitch/localize-sdk-android) · [React Native](https://github.com/arsalankhan-glitch/localize-sdk-react-native).

To get started, sign up [here](https://localiq.yaxbi.com/signup).

## 📱 Example app

See [`example/`](example/). The platform folders aren't committed, so run `flutter create .` in `example/` once, then `flutter run --dart-define=LOCALIZE_EXAMPLE_API_KEY=pk_xxx`.

## 📋 Requirements

- Dart 3.0+
- Flutter 3.10 or later

## 🎉 Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_localize_sdk:
    git:
      url: https://github.com/arsalankhan-glitch/localize-sdk-flutter
      ref: 0.1.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Setup

Call `configure` in `main` before `runApp`:

```dart
import 'package:flutter_localize_sdk/flutter_localize_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalizeSDK.configure(
    apiKey: 'pk_xxx',
    fallbackLocale: 'en',
    onKeysUpdated: () { /* trigger setState */ },
  );

  runApp(const MyApp());
}
```

## 💡 Usage

```dart
// Simple string
final label = LocalizeSDK.getString('welcome_message');

// Interpolated string
final greeting = LocalizeSDK.getString('greeting', args: ['John']);

// Plural
final count = LocalizeSDK.getPlural('items_count', 5);

// Switch locale
LocalizeSDK.setLocale('ar');

// Refresh from API
LocalizeSDK.refresh();
```

## ⚙️ Configuration options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apiKey` | `String` | — | Project API key (required) |
| `fallbackLocale` | `String?` | `null` | Locale to use when key is missing |
| `bundleFallback` | `Function?` | `null` | Custom bundle fallback resolver |
| `timeoutSeconds` | `int` | `10` | Network request timeout |
| `enableLogging` | `bool` | `true` | Print debug logs |
| `onKeysUpdated` | `VoidCallback?` | `null` | Called after each successful refresh |

## 🔍 How it works

1. On `configure`, the SDK fetches all translations from the API (every locale) and caches them on disk.
2. If the fetch fails, the SDK uses the cached translations for the current locale.
3. If the API is unreachable, it falls back to the bundle you return from `localLoader`.
4. Call `refresh()` at any time to pull the latest translations in the background.
5. Call `setLocale("ar")` to switch locale. The SDK reads that locale from the cache, with no network request.

## 📄 License

[MIT](LICENSE)
