import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _greetingFormatAr = DateFormat('EEEE، d MMMM', 'ar');
  static final DateFormat _greetingFormatEn = DateFormat('EEEE, d MMMM');
  static final DateFormat _shortDateFormatAr = DateFormat('d MMMM yyyy', 'ar');
  static final DateFormat _shortDateFormatEn = DateFormat('d MMM yyyy');

  static String formatGreetingDate(DateTime date, {String locale = 'ar'}) {
    try {
      if (locale == 'ar') return _greetingFormatAr.format(date);
      return DateFormat('EEEE، d MMMM', locale).format(date);
    } catch (_) {
      return _greetingFormatEn.format(date);
    }
  }

  static String formatShortDate(DateTime date, {String locale = 'ar'}) {
    try {
      if (locale == 'ar') return _shortDateFormatAr.format(date);
      return DateFormat('d MMMM yyyy', locale).format(date);
    } catch (_) {
      return _shortDateFormatEn.format(date);
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
