import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/utils/arabic_search_utils.dart';
import 'package:gym_managment_app/core/utils/validators.dart';

void main() {
  group('ArabicSearchUtils tests', () {
    test('normalizes tashkeel and tatweel', () {
      const input = 'مُـحَمَّـدْ';
      final output = ArabicSearchUtils.normalize(input);
      expect(output, equals('محمد'));
    });

    test('unifies alef variants (أ, إ, آ, ٱ -> ا)', () {
      expect(ArabicSearchUtils.normalize('أحمد'), equals('احمد'));
      expect(ArabicSearchUtils.normalize('إبراهيم'), equals('ابراهيم'));
      expect(ArabicSearchUtils.normalize('آدم'), equals('ادم'));
    });

    test('unifies alef maksura (ى -> ي) and taa marbuta (ة -> ه)', () {
      expect(ArabicSearchUtils.normalize('منى'), equals('مني'));
      expect(ArabicSearchUtils.normalize('فاطمة'), equals('فاطمه'));
    });

    test('converts Eastern Arabic-Indic digits to Western numerals', () {
      expect(ArabicSearchUtils.normalize('٠١٠١٢٣٤٥٦٧٨'), equals('01012345678'));
      expect(ArabicSearchUtils.normalizePhone('٠١١٢٣٤٥٦٧٨٩'), equals('01123456789'));
    });

    test('normalizes phone with international code +20', () {
      expect(ArabicSearchUtils.normalizePhone('+201012345678'), equals('01012345678'));
      expect(ArabicSearchUtils.normalizePhone('010 1234 5678'), equals('01012345678'));
    });
  });

  group('FormValidators tests', () {
    test('validateName validates minimum length and presence', () {
      expect(FormValidators.validateName(null), isNotNull);
      expect(FormValidators.validateName(''), isNotNull);
      expect(FormValidators.validateName('أ'), isNotNull);
      expect(FormValidators.validateName('علي'), isNull);
    });

    test('validatePhone validates 11-digit Egyptian numbers', () {
      expect(FormValidators.validatePhone(null), isNotNull);
      expect(FormValidators.validatePhone('0101234'), isNotNull);
      expect(FormValidators.validatePhone('0101234567899'), isNotNull);
      expect(FormValidators.validatePhone('01312345678'), isNotNull); // not valid prefix
      expect(FormValidators.validatePhone('01012345678'), isNull);
      expect(FormValidators.validatePhone('01123456789'), isNull);
      expect(FormValidators.validatePhone('01234567890'), isNull);
      expect(FormValidators.validatePhone('01512345678'), isNull);
    });

    test('validateAge, weight, and height bounds', () {
      expect(FormValidators.validateAge('4'), isNotNull);
      expect(FormValidators.validateAge('101'), isNotNull);
      expect(FormValidators.validateAge('25'), isNull);
      expect(FormValidators.validateAge(null), isNull); // Optional

      expect(FormValidators.validateWeight('19'), isNotNull);
      expect(FormValidators.validateWeight('301'), isNotNull);
      expect(FormValidators.validateWeight('75.5'), isNull);

      expect(FormValidators.validateHeight('99'), isNotNull);
      expect(FormValidators.validateHeight('251'), isNotNull);
      expect(FormValidators.validateHeight('178'), isNull);
    });
  });
}
