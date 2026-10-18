import 'arabic_search_utils.dart';

class FormValidators {
  FormValidators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final normalized = ArabicSearchUtils.normalizePhone(value);
    if (normalized.length != 11) {
      return 'رقم الهاتف يجب أن يكون 11 رقماً';
    }
    // Egyptian mobile standard check (010, 011, 012, 015)
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(normalized)) {
      return 'رقم الهاتف غير صالح (يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015)';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final normalized = ArabicSearchUtils.normalizePhone(value);
    final age = int.tryParse(normalized);
    if (age == null || age < 5 || age > 100) {
      return 'العمر يجب أن يكون بين 5 و 100 سنة';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final cleaned = ArabicSearchUtils.normalize(value.trim());
    final weight = double.tryParse(cleaned);
    if (weight == null || weight < 20 || weight > 300) {
      return 'الوزن يجب أن يكون بين 20 و 300 كجم';
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final cleaned = ArabicSearchUtils.normalize(value.trim());
    final height = double.tryParse(cleaned);
    if (height == null || height < 100 || height > 250) {
      return 'الطول يجب أن يكون بين 100 و 250 سم';
    }
    return null;
  }
}
