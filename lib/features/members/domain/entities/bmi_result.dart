import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';

enum BmiCategory {
  underweight,
  normal,
  overweight,
  obese;

  String get label {
    switch (this) {
      case BmiCategory.underweight:
        return 'نقص في الوزن';
      case BmiCategory.normal:
        return 'وزن طبيعي';
      case BmiCategory.overweight:
        return 'وزن زائد';
      case BmiCategory.obese:
        return 'سمنة';
    }
  }

  Color get color {
    switch (this) {
      case BmiCategory.normal:
        return AppColors.success;
      case BmiCategory.underweight:
      case BmiCategory.overweight:
        return AppColors.warning;
      case BmiCategory.obese:
        return AppColors.error;
    }
  }
}

class BmiResult extends Equatable {
  final double value;
  final BmiCategory category;

  const BmiResult({
    required this.value,
    required this.category,
  });

  @override
  List<Object?> get props => [value, category];
}

class BmiCalculator {
  BmiCalculator._();

  static BmiResult? calculate({
    double? weightKg,
    double? heightCm,
  }) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg <= 0 || heightCm <= 0) return null;

    final heightM = heightCm / 100.0;
    final rawBmi = weightKg / (heightM * heightM);

    if (rawBmi.isNaN || rawBmi.isInfinite) return null;

    final rounded = double.parse(rawBmi.toStringAsFixed(1));
    final category = _resolveCategory(rounded);

    return BmiResult(value: rounded, category: category);
  }

  static BmiCategory _resolveCategory(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory.underweight;
    } else if (bmi < 25.0) {
      return BmiCategory.normal;
    } else if (bmi < 30.0) {
      return BmiCategory.overweight;
    } else {
      return BmiCategory.obese;
    }
  }
}
