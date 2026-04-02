import 'package:flutter/material.dart';
import 'package:flutter_localize_sdk/flutter_localize_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalizeSDK.configure(
    apiKey: 'pk_example', // Replace with real API key for live test
    fallbackLocale: 'en',
    enableLogging: true,
    localLoader: () async {
      // Bundled fallback when API unavailable
      return parseLocalBundleJson('''
        {
          "languages": {
            "en": {
              "simple": {
                "welcome": "Welcome (bundled)",
                "greeting": "Hello, %s!"
              },
              "plural": {
                "items_count": {"one": "1 item", "other": "%d items"}
              }
            }
          }
        }
      ''') ?? const LocalizeStore();
    },
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localize SDK Example',
      theme: ThemeData(useMaterial3: true),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  @override
  void initState() {
    super.initState();
    LocalizeSDK.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizeSDK.getString('welcome')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              LocalizeSDK.refresh();
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizeSDK.getString('greeting', args: ['User']),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(LocalizeSDK.getPlural('items_count', 1)),
            Text(LocalizeSDK.getPlural('items_count', 5)),
            const SizedBox(height: 24),
            Text('Locale: ${LocalizeSDK.locale}'),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: () {
                    LocalizeSDK.setLocale('en');
                    setState(() {});
                  },
                  child: const Text('EN'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    LocalizeSDK.setLocale('ar');
                    setState(() {});
                  },
                  child: const Text('AR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
