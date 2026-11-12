import 'dart:io';

/// واجهة خدمة النسخ الاحتياطي والاسترجاع المحلي لقاعدة بيانات التطبيق
abstract class BackupService {
  /// إنشاء نسخة احتياطية محلية لقاعدة بيانات SQLite ومشاركتها أو حفظها
  Future<File?> createBackup();

  /// استرجاع قاعدة البيانات من ملف نسخة احتياطية محلي (.db / .bak)
  Future<bool> restoreBackupFromFile(String filePath);

  /// الحصول على مسار ملف قاعدة البيانات الفعلي
  Future<String> getDatabasePath();
}
