import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/features/members/domain/entities/bmi_result.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart';
import 'package:gym_managment_app/features/members/domain/entities/member.dart';

void main() {
  group('BmiCalculator Tests', () {
    test('returns null for missing or invalid inputs', () {
      expect(BmiCalculator.calculate(weightKg: null, heightCm: 180), isNull);
      expect(BmiCalculator.calculate(weightKg: 70, heightCm: null), isNull);
      expect(BmiCalculator.calculate(weightKg: null, heightCm: null), isNull);
      expect(BmiCalculator.calculate(weightKg: 0, heightCm: 180), isNull);
      expect(BmiCalculator.calculate(weightKg: 70, heightCm: 0), isNull);
      expect(BmiCalculator.calculate(weightKg: -10, heightCm: 180), isNull);
      expect(BmiCalculator.calculate(weightKg: 70, heightCm: -180), isNull);
    });

    test('calculates normal BMI and rounds to 1 decimal place', () {
      final result = BmiCalculator.calculate(weightKg: 70, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.value, equals(22.9));
      expect(result.category, equals(BmiCategory.normal));
      expect(result.category.label, equals('وزن طبيعي'));
    });

    test('correctly classifies underweight (< 18.5)', () {
      final result = BmiCalculator.calculate(weightKg: 50, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.value, equals(16.3));
      expect(result.category, equals(BmiCategory.underweight));
      expect(result.category.label, equals('نقص في الوزن'));
    });

    test('exact boundary test: 18.5 is normal', () {
      // 74 / (2.0 * 2.0) = 18.5
      final result = BmiCalculator.calculate(weightKg: 74, heightCm: 200);
      expect(result, isNotNull);
      expect(result!.value, equals(18.5));
      expect(result.category, equals(BmiCategory.normal));
    });

    test('exact boundary test: 24.9 is normal', () {
      // 99.6 / 4 = 24.9
      final result = BmiCalculator.calculate(weightKg: 99.6, heightCm: 200);
      expect(result, isNotNull);
      expect(result!.value, equals(24.9));
      expect(result.category, equals(BmiCategory.normal));
    });

    test('exact boundary test: 25.0 is overweight', () {
      // 100 / 4 = 25.0
      final result = BmiCalculator.calculate(weightKg: 100, heightCm: 200);
      expect(result, isNotNull);
      expect(result!.value, equals(25.0));
      expect(result.category, equals(BmiCategory.overweight));
      expect(result.category.label, equals('وزن زائد'));
    });

    test('exact boundary test: 29.9 is overweight', () {
      // 119.6 / 4 = 29.9
      final result = BmiCalculator.calculate(weightKg: 119.6, heightCm: 200);
      expect(result, isNotNull);
      expect(result!.value, equals(29.9));
      expect(result.category, equals(BmiCategory.overweight));
    });

    test('exact boundary test: 30.0 is obese', () {
      // 120 / 4 = 30.0
      final result = BmiCalculator.calculate(weightKg: 120, heightCm: 200);
      expect(result, isNotNull);
      expect(result!.value, equals(30.0));
      expect(result.category, equals(BmiCategory.obese));
      expect(result.category.label, equals('سمنة'));
    });

    test('rounding checks: rounds up and down to 1 decimal place', () {
      // 65.5 / (1.7 * 1.7) = 22.664... -> 22.7
      final up = BmiCalculator.calculate(weightKg: 65.5, heightCm: 170);
      expect(up?.value, equals(22.7));

      // 65.4 / (1.7 * 1.7) = 22.629... -> 22.6
      final down = BmiCalculator.calculate(weightKg: 65.4, heightCm: 170);
      expect(down?.value, equals(22.6));
    });

    test('Member entity bmi getter computes BMI automatically', () {
      final now = DateTime.now();
      final memberWithStats = Member(
        id: 1,
        name: 'كابتن محمود',
        phone: '01012345678',
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        createdAt: now,
        updatedAt: now,
      );

      expect(memberWithStats.bmi, isNotNull);
      // 80 / (1.8 * 1.8) = 80 / 3.24 = 24.69... -> 24.7
      expect(memberWithStats.bmi!.value, equals(24.7));
      expect(memberWithStats.bmi!.category, equals(BmiCategory.normal));

      final memberWithoutStats = Member(
        id: 2,
        name: 'علي',
        phone: '01099998888',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );
      expect(memberWithoutStats.bmi, isNull);
    });
  });
}
