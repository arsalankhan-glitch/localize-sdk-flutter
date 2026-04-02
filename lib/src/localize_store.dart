/// In-memory storage structure for O(1) lookup.
/// simple: Map<Locale, Map<Key, String>>
/// plural: Map<Locale, Map<Key, Map<PluralForm, String>>>
class LocalizeStore {
  final Map<String, Map<String, String>> simple;
  final Map<String, Map<String, Map<String, String>>> plural;

  const LocalizeStore({
    this.simple = const {},
    this.plural = const {},
  });

  LocalizeStore copyWith({
    Map<String, Map<String, String>>? simple,
    Map<String, Map<String, Map<String, String>>>? plural,
  }) {
    return LocalizeStore(
      simple: simple ?? this.simple,
      plural: plural ?? this.plural,
    );
  }

  /// Deep copy for immutability when replacing store
  LocalizeStore deepCopy() {
    final newSimple = <String, Map<String, String>>{};
    for (final entry in simple.entries) {
      newSimple[entry.key] = Map<String, String>.from(entry.value);
    }
    final newPlural = <String, Map<String, Map<String, String>>>{};
    for (final entry in plural.entries) {
      newPlural[entry.key] = {};
      for (final inner in entry.value.entries) {
        newPlural[entry.key]![inner.key] = Map<String, String>.from(inner.value);
      }
    }
    return LocalizeStore(simple: newSimple, plural: newPlural);
  }

  bool get isEmpty => simple.isEmpty && plural.isEmpty;
}
