import 'package:intl/intl.dart';

/// مساعد تنسيق التواريخ والأوقات والأرقام
class DateFormatter {
  DateFormatter._();

  static final DateFormat _arabicDateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _arabicDateTimeFormat = DateFormat(
    'yyyy/MM/dd - hh:mm a',
    'ar',
  );
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'ar');

  /// تنسيق تاريخ بسيط (مثال: 2026/11/13)
  static String formatDate(DateTime dateTime) {
    try {
      return _arabicDateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// تنسيق تاريخ ووقت معاً
  static String formatDateTime(DateTime dateTime) {
    try {
      return _arabicDateTimeFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
    }
  }

  /// تحويل التاريخ إلى نص ISO قياسي لتخزينه في SQLite
  static String toIso(DateTime dateTime) {
    return _isoFormat.format(dateTime);
  }

  /// قراءة تاريخ من نص SQLite ISO
  static DateTime? fromIso(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// تنسيق الأرقام والكميات (مثال: 1,500 كرتون)
  static String formatNumber(num number) {
    try {
      return _numberFormat.format(number);
    } catch (_) {
      return number.toString();
    }
  }
}
