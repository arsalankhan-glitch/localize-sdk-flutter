import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localize_sdk/flutter_localize_sdk.dart';

/// Integration-style test: SDK works when used in a Flutter widget tree.
/// Verifies the SDK can be configured and used like in a real app.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizeSDK.configure(
      apiKey: 'pk_integration_test',
      enableLogging: false,
      localLoader: () async =>
          parseLocalBundleJson('''
        {"languages":{"en":{"simple":{"welcome":"Welcome!","greeting":"Hello, %s!"},"plural":{"items_count":{"one":"1 item","other":"%d items"}}}}}
      ''') ??
          const LocalizeStore(),
    );
  });

  tearDownAll(() {
    LocalizeSDK.resetForTesting();
  });

  testWidgets('SDK displays localized strings in widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text(LocalizeSDK.getString('welcome')),
              Text(LocalizeSDK.getString('greeting', args: ['World'])),
              Text(LocalizeSDK.getPlural('items_count', 1)),
              Text(LocalizeSDK.getPlural('items_count', 5)),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Hello, World!'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('5 items'), findsOneWidget);
  });

  testWidgets('setLocale changes displayed text', (tester) async {
    LocalizeSDK.setLocale('en');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(LocalizeSDK.getString('welcome')),
        ),
      ),
    );
    expect(find.text('Welcome!'), findsOneWidget);

    LocalizeSDK.setLocale('ar');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(LocalizeSDK.getString('welcome')),
        ),
      ),
    );
    expect(LocalizeSDK.locale, 'ar');
  });
}
