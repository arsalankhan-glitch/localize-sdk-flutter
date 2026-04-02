import 'package:flutter_localize_sdk/src/plural.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectPluralForm', () {
    group('English (default)', () {
      test('one for count 1', () {
        expect(selectPluralForm('en', 1), 'one');
      });

      test('other for count 0', () {
        expect(selectPluralForm('en', 0), 'other');
      });

      test('other for count 2', () {
        expect(selectPluralForm('en', 2), 'other');
      });

      test('other for count 5', () {
        expect(selectPluralForm('en', 5), 'other');
      });
    });

    group('Arabic', () {
      test('zero for count 0', () {
        expect(selectPluralForm('ar', 0), 'zero');
      });

      test('one for count 1', () {
        expect(selectPluralForm('ar', 1), 'one');
      });

      test('two for count 2', () {
        expect(selectPluralForm('ar', 2), 'two');
      });

      test('few for count 5', () {
        expect(selectPluralForm('ar', 5), 'few');
      });

      test('many for count 15', () {
        expect(selectPluralForm('ar', 15), 'many');
      });

      test('other for count 100', () {
        expect(selectPluralForm('ar', 100), 'other');
      });
    });

    group('locale with region', () {
      test('en-US uses default', () {
        expect(selectPluralForm('en-US', 1), 'one');
        expect(selectPluralForm('en-US', 2), 'other');
      });
    });
  });
}
