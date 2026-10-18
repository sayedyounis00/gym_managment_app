import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _defaultCurrencyFormatter = NumberFormat.currency(
    symbol: 'ج.م',
    decimalDigits: 2,
    customPattern: '#,##0.00 \u00a4',
  );

  static final NumberFormat _defaultCompactFormatter = NumberFormat.compact();

  static String format(double amount, {String symbol = 'ج.م', int decimalDigits = 2}) {
    if (symbol == 'ج.م' && decimalDigits == 2) {
      return _defaultCurrencyFormatter.format(amount).trim();
    }
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      customPattern: '#,##0.00 \u00a4',
    );
    return formatter.format(amount).trim();
  }

  static String formatCompact(double amount, {String symbol = 'ج.م'}) {
    final compactNum = _defaultCompactFormatter.format(amount);
    return '$compactNum $symbol'.trim();
  }
}
