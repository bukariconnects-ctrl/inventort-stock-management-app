/// الثوابت العامة لنظام إدارة مخازن مياه رواء
class AppConstants {
  AppConstants._();

  // معلومات التطبيق الأساسية
  static const String appName = 'مياه رواء - إدارة المخازن';
  static const String appNameEnglish = 'Rawaa WMS';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'نظام إدارة المخازن وحركات المخزون لمصنع مياه رواء';

  // الصنف الأساسي المعتمد
  static const String defaultItemName = 'كرتون مياه رواء';
  static const String defaultItemSpecification = '20 قنينة × 750 مل';
  static const String defaultItemUnit = 'كرتون';
  static const int defaultLowStockThreshold =
      100; // حد التنبيه الافتراضي لكل مخزن (100 كرتون)

  // أنواع الحركات والسندات المعتمدة
  static const String transactionTypeReceipt =
      'receipt'; // سند استلام من المصنع
  static const String transactionTypeIssue = 'issue'; // سند صرف لموزع
  static const String transactionTypeDamage = 'damage'; // سند إتلاف وهدر
  static const String transactionTypeStocktake = 'stocktake'; // تسوية جرد دوري

  // المسميات العربية لأنواع السندات
  static const Map<String, String> transactionTypeNames = {
    transactionTypeReceipt: 'سند استلام إنتاج',
    transactionTypeIssue: 'سند صرف موزع',
    transactionTypeDamage: 'سند إتلاف وهدر',
    transactionTypeStocktake: 'تسوية جرد دوري',
  };

  // بادئات أرقام السندات
  static const String prefixReceipt = 'REC-';
  static const String prefixIssue = 'ISS-';
  static const String prefixDamage = 'DAM-';
  static const String prefixStocktake = 'STK-';
}
