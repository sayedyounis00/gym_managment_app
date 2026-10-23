import 'package:intl/intl.dart';

class AppDateUtils {
  static const Map<int, String> arabicMonths = {
    1: '(1) يناير',
    2: '(2) فبراير',
    3: '(3) مارس',
    4: '(4) أبريل',
    5: '(5) مايو',
    6: '(6) يونيو',
    7: '(7) يوليو',
    8: '(8) أغسطس',
    9: '(9) سبتمبر',
    10: '(10) أكتوبر',
    11: '(11) نوفمبر',
    12: '(12) ديسمبر',
  };

  static String arabicMonthWithNumber(int month) => arabicMonths[month] ?? '$month';

  static final DateFormat _greetingWeekdayAr = DateFormat('EEEE', 'ar');
  static final DateFormat _greetingFormatEn = DateFormat('EEEE, d MMMM');
  static final DateFormat _shortDateFormatEn = DateFormat('d MMM yyyy');

  static String formatGreetingDate(DateTime date, {String locale = 'ar'}) {
    try {
      if (locale == 'ar') {
        final weekday = _greetingWeekdayAr.format(date);
        return '$weekday، ${date.day} ${arabicMonthWithNumber(date.month)}';
      }
      return DateFormat('EEEE، d MMMM', locale).format(date);
    } catch (_) {
      return _greetingFormatEn.format(date);
    }
  }

  static String formatShortDate(DateTime date, {String locale = 'ar'}) {
    try {
      if (locale == 'ar') {
        return '${date.day} ${arabicMonthWithNumber(date.month)} ${date.year}';
      }
      return DateFormat('d MMMM yyyy', locale).format(date);
    } catch (_) {
      return _shortDateFormatEn.format(date);
    }
  }

  static String formatMonthYear(DateTime date, {String locale = 'ar'}) {
    try {
      if (locale == 'ar') {
        return '${arabicMonthWithNumber(date.month)} ${date.year}';
      }
      return DateFormat('MMMM yyyy', locale).format(date);
    } catch (_) {
      return DateFormat('MMM yyyy').format(date);
    }
  }

  static String _formatTime12(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'م' : 'ص';
    final minute = date.minute.toString().padLeft(2, '0');
    final hour = hour12.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static String formatDateTime(DateTime date, {String locale = 'ar'}) {
    try {
      if (locale == 'ar') {
        final time = _formatTime12(date);
        return '${date.day} ${arabicMonthWithNumber(date.month)} ${date.year} - $time';
      }
      return DateFormat('d MMMM yyyy - hh:mm a', locale).format(date);
    } catch (_) {
      final time = _formatTime12(date);
      return '${date.day} ${arabicMonthWithNumber(date.month)} ${date.year} - $time';
    }
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static (DateTime since, DateTime until) rollingMonthWindow(DateTime now) {
    final until = endOfDay(now);
    final since = startOfDay(now.subtract(const Duration(days: 30)));
    return (since, until);
  }

  static int daysRemaining(DateTime target, DateTime from) {
    final targetStart = startOfDay(target);
    final fromStart = startOfDay(from);
    return targetStart.difference(fromStart).inDays;
  }
}
