import 'dart:convert';
import 'dart:io';

import 'package:flutter_localize_sdk/src/cache.dart';
import 'package:flutter_localize_sdk/src/config.dart';
import 'package:flutter_localize_sdk/src/fetcher.dart';
import 'package:flutter_localize_sdk/src/localize_sdk_impl.dart';
import 'package:flutter_localize_sdk/src/localize_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// End-to-end lifecycle: real fetcher (fake HTTP server) + real on-disk cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late _Server server;
  const config = LocalizeConfig(
    apiKey: 'pk_lifecycle',
    fallbackLocale: 'en',
    enableLogging: false,
  );

  LocalizeSDKImpl newApp() => LocalizeSDKImpl(
        config: config,
        fetcher: LocalizeFetcher(config, client: server.client),
        cache: LocalizeCache(config),
        localLoader: () async => const LocalizeStore(),
      );

  List<String> cacheFiles() => dir
      .listSync()
      .map((f) => f.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  setUp(() {
    dir = Directory.systemTemp.createTempSync('localize_lifecycle_');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    server = _Server({
      'en': {'welcome': 'Welcome', 'only_en': 'English only'},
      'ar': {'welcome': 'أهلا'},
    });
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('1. first launch online: downloads and writes one cache file per locale', () async {
    final app = newApp();
    await app.init();

    expect(server.requests, 1);
    expect(app.getString('welcome'), 'Welcome');
    expect(cacheFiles().length, 2);
    expect(cacheFiles().every((f) => f.contains('_flutter_')), isTrue);
  });

  test('2. relaunch offline: serves from disk cache, incl. locale switch + fallback', () async {
    await newApp().init();
    server.offline = true;

    final app = newApp();
    await app.init();
    expect(app.getString('welcome'), 'Welcome');

    await app.setLocaleTo('ar');
    expect(app.getString('welcome'), 'أهلا');
    expect(app.getString('only_en'), 'English only', reason: 'fallback locale');
  });

  test('3. refresh picks up changed, added and deleted keys and rewrites cache', () async {
    final app = newApp();
    await app.init();

    server.languages = {
      'en': {'welcome': 'Welcome v2', 'new_key': 'New'},
      'ar': {'welcome': 'أهلا v2'},
    };
    await app.refresh();

    expect(server.requests, 2);
    expect(app.getString('welcome'), 'Welcome v2');
    expect(app.getString('new_key'), 'New');
    expect(app.getString('only_en'), 'only_en', reason: 'deleted on server');

    server.offline = true;
    final relaunched = newApp();
    await relaunched.init();
    expect(relaunched.getString('welcome'), 'Welcome v2', reason: 'cache updated');
  });

  test('4. refresh failing (offline / 401 / 500) keeps current values', () async {
    final app = newApp();
    await app.init();

    for (final failure in [() => server.offline = true, () => server.status = 401, () => server.status = 500]) {
      server.offline = false;
      server.status = 200;
      failure();
      await app.refresh();
      expect(app.getString('welcome'), 'Welcome');
    }
  });

  test('5. no automatic re-download: only init() and refresh() hit the network', () async {
    final app = newApp();
    await app.init();
    await app.setLocaleTo('ar');
    app.getString('welcome');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(server.requests, 1);
  });

  test('6. KNOWN BUG §15.2: 200 with no languages wipes in-memory keys', () async {
    final app = newApp();
    await app.init();

    server.languages = {};
    await app.refresh();

    expect(app.getString('welcome'), 'welcome', reason: 'store replaced by empty export');
    expect(cacheFiles().length, 2, reason: 'old files remain on disk');
  });

  test('7. locale removed on server keeps its stale cache file', () async {
    final app = newApp();
    await app.init();

    server.languages = {'en': {'welcome': 'Welcome'}};
    await app.refresh();
    await app.setLocaleTo('ar');

    expect(app.getString('welcome'), 'أهلا', reason: 'served from stale ar file');
  });
}

class _Server {
  Map<String, Map<String, String>> languages;
  bool offline = false;
  int status = 200;
  int requests = 0;

  _Server(this.languages);

  late final http.Client client = MockClient((req) async {
    requests++;
    if (offline) throw const SocketException('offline');
    if (req.headers['X-API-Key'] != 'pk_lifecycle') return http.Response('', 401);
    if (status != 200) return http.Response('', status);
    return http.Response.bytes(
      utf8.encode(jsonEncode({
        'platform': req.url.queryParameters['platform'],
        'languages': {
          for (final e in languages.entries) e.key: {'simple': e.value, 'plural': {}},
        },
      })),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
