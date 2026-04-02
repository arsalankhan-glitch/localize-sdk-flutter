import 'localize_store.dart';

/// Resolution order:
/// 1. API response (stored in cache)
/// 2. Cached API data
/// 3. Local bundled keys
///
/// API data always overwrites cache. Local keys are fallback only when
/// API/cache are unavailable.
class LocalizeResolver {
  /// Resolve which store to use. Prefer apiOrCache over local.
  static LocalizeStore resolve({
    required LocalizeStore? apiOrCache,
    required LocalizeStore? local,
  }) {
    if (apiOrCache != null && !apiOrCache.isEmpty) {
      return apiOrCache;
    }
    if (local != null && !local.isEmpty) {
      return local;
    }
    return apiOrCache ?? local ?? const LocalizeStore();
  }
}
