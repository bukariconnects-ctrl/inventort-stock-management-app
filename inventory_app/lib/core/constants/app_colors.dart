import 'package:flutter/material.dart';

/// لوحة ألوان نظام مياه رواء المستوحاة من قطاع مياه الشرب النقية
class AppColors {
  AppColors._();

  // درجات الأزرق المائي الرئيسي (Clean Water & Ocean Palette)
  static const Color primary = Color(0xFF0277BD); // أزرق مائي عميق ونقي
  static const Color primaryDark = Color(0xFF01579B); // كحلي بحري
  static const Color primaryLight = Color(0xFF4FC3F7); // سماوي رائق
  static const Color accentCyan = Color(0xFF00ACC1); // تركواز مائي

  // درجات الخلفيات والأسطح
  static const Color background = Color(
    0xFFF4F7FB,
  ); // رمادي فاتح مائل للزرقة الباردة
  static const Color surface = Color(0xFFFFFFFF); // أبيض نقي
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF1A2634); // رمادي داكن فاحم
  static const Color textSecondary = Color(0xFF64748B); // رمادي متوسط
  static const Color textMuted = Color(0xFF94A3B8); // رمادي باهت
  static const Color textOnPrimary = Color(0xFFFFFFFF); // أبيض على الأساسي

  // ألوان الحالات والعمليات المخزنية (Semantic Status Colors)
  static const Color receiptGreen = Color(
    0xFF10B981,
  ); // استلام (وارد / زيادة رصيد)
  static const Color receiptGreenLight = Color(0xFFD1FAE5);

  static const Color issueBlue = Color(0xFF2563EB); // صرف لموزع (منصرف نظامي)
  static const Color issueBlueLight = Color(0xFFDBEAFE);

  static const Color damageRed = Color(
    0xFFEF4444,
  ); // إتلاف وهدر (خسارة / تنبيه شديد)
  static const Color damageRedLight = Color(0xFFFEE2E2);

  static const Color stocktakePurple = Color(0xFF8B5CF6); // تسوية جرد
  static const Color stocktakePurpleLight = Color(0xFFEDE9FE);

  static const Color warningAmber = Color(0xFFF59E0B); // تنبيه انخفاض المخزون
  static const Color warningAmberLight = Color(0xFFFEF3C7);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}
