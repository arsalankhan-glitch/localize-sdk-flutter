import 'package:flutter_localize_sdk/flutter_localize_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    LocalizeSDK.resetForTesting();
  });

  group('LocalizeSDK (static API)', () {
    setUp(() => LocalizeSDK.resetForTesting());

    test('getString returns key when not configured', () {
      // Arrange: SDK not configured (fresh run)
      // Act
      final result = LocalizeSDK.getString('any_key');

      // Assert: returns key as fallback when no instance
      expect(result, 'any_key');
    });

    test('getPlural returns key when not configured', () {
      expect(LocalizeSDK.getPlural('items', 5), 'items');
    });

    test('locale defaults to en when not configured', () {
      expect(LocalizeSDK.locale, 'en');
    });

    test('isConfigured is false when not configured', () {
      expect(LocalizeSDK.isConfigured, false);
    });

    test('configure then getString returns value from store', () async {
      // Arrange: configure with fake loader that returns known store
      const testStore = LocalizeStore(
        simple: {'en': {'welcome': 'Hello World'}},
        plural: {},
      );

      await LocalizeSDK.configure(
        apiKey: 'pk_test',
        localLoader: () async => testStore,
        enableLogging: false,
      );

      // Act
      final result = LocalizeSDK.getString('welcome');

      // Assert
      expect(result, 'Hello World');
      expect(LocalizeSDK.isConfigured, true);
    });

    test('setLocale changes lookup locale', () async {
      const store = LocalizeStore(
        simple: {
          'en': {'k': 'English'},
          'ar': {'k': 'Arabic'},
        },
        plural: {},
      );

      await LocalizeSDK.configure(
        apiKey: 'pk',
        localLoader: () async => store,
        enableLogging: false,
      );

      LocalizeSDK.setLocale('en');
      expect(LocalizeSDK.getString('k'), 'English');

      LocalizeSDK.setLocale('ar');
      expect(LocalizeSDK.getString('k'), 'Arabic');
    });

    test('refresh does not throw when configured', () async {
      await LocalizeSDK.configure(
        apiKey: 'pk',
        localLoader: () async => const LocalizeStore(),
        enableLogging: false,
      );
      expect(() => LocalizeSDK.refresh(), returnsNormally);
    });
  });
}
