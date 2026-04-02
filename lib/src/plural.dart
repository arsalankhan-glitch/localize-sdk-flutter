/// Plural form selection based on count.
/// CLDR rules: https://unicode-org.github.io/cldr-staging/charts/43/supplemental/language_plural_rules.html
///
/// Common forms: zero, one, two, few, many, other
/// English: one, other
/// Arabic: zero, one, two, few, many, other
String selectPluralForm(String locale, int count) {
  final lang = locale.split(RegExp(r'[-_]')).first.toLowerCase();

  switch (lang) {
    case 'ar':
      return _arabicPlural(count);
    case 'ru':
    case 'uk':
    case 'pl':
      return _slavicPlural(count);
    case 'fr':
      return _frenchPlural(count);
    case 'de':
    case 'en':
    case 'es':
    case 'it':
    case 'pt':
    case 'nl':
    case 'tr':
    case 'ja':
    case 'ko':
    case 'zh':
      return _defaultPlural(count);
    default:
      return _defaultPlural(count);
  }
}

String _defaultPlural(int count) {
  if (count == 1) return 'one';
  return 'other';
}

String _arabicPlural(int count) {
  if (count == 0) return 'zero';
  if (count == 1) return 'one';
  if (count == 2) return 'two';
  if (count >= 3 && count <= 10) return 'few';
  if (count >= 11 && count <= 99) return 'many';
  return 'other';
}

String _slavicPlural(int count) {
  if (count % 10 == 1 && count % 100 != 11) return 'one';
  if (count % 10 >= 2 &&
      count % 10 <= 4 &&
      (count % 100 < 10 || count % 100 >= 20)) {
    return 'few';
  }
  if (count % 10 == 0 ||
      (count % 10 >= 5 && count % 10 <= 9) ||
      (count % 100 >= 11 && count % 100 <= 19)) {
    return 'many';
  }
  return 'other';
}

String _frenchPlural(int count) {
  if (count == 0 || count == 1) return 'one';
  return 'other';
}
