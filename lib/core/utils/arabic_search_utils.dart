class ArabicSearchUtils {
  ArabicSearchUtils._();

  static final RegExp _tashkeelRegex = RegExp(
    r'[\u064B-\u0652\u0670\u0640]',
  );
  static final RegExp _nonDigitsRegex = RegExp(r'\D');

  /// Normalizes Arabic text for flexible matching:
  /// - Strips diacritics / tashkeel and tatweel
  /// - Normalizes Alef variants (أ, إ, آ, ٱ) -> ا
  /// - Normalizes Alef Maksura (ى) -> ي
  /// - Normalizes Taa Marbuta (ة) -> ه
  /// - Converts Eastern Arabic numerals to standard Western numerals
  static String normalize(String text) {
    if (text.isEmpty) return '';

    var result = text;

    // Convert Arabic-Indic digits to Latin
    const easternDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(easternDigits[i], '$i');
    }

    // Strip tashkeel
    result = result.replaceAll(_tashkeelRegex, '');

    // Unify Alef
    result = result
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا');

    // Unify Alef Maksura
    result = result.replaceAll('ى', 'ي');

    // Unify Taa Marbuta
    result = result.replaceAll('ة', 'ه');

    return result.trim().toLowerCase();
  }

  /// Normalizes a phone number to only digits and converts Arabic-Indic digits to Western.
  static String normalizePhone(String phone) {
    if (phone.isEmpty) return '';

    var result = phone;
    const easternDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(easternDigits[i], '$i');
    }

    // Keep only digits
    result = result.replaceAll(_nonDigitsRegex, '');

    // If starts with +20 or 0020, convert to local 11 digits (01...)
    if (result.startsWith('20') && result.length == 12) {
      result = '0${result.substring(2)}';
    } else if (result.startsWith('20') && result.length == 13) {
      result = result.substring(2);
    }

    return result;
  }
}
