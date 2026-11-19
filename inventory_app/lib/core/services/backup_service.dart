import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../utils/date_formatter.dart';

/// نتيجة عملية النسخ الاحتياطي
class BackupResult {
  final bool success;
  final String message;
  final File? file;
  final String? error;

  const BackupResult({
    required this.success,
    required this.message,
    this.file,
    this.error,
  });

  factory BackupResult.success(File file, {String? message}) => BackupResult(
    success: true,
    message: message ?? 'تم إنشاء النسخة الاحتياطية بنجاح ومشاركتها',
    file: file,
  );

  factory BackupResult.failure(String message, {String? error}) =>
      BackupResult(success: false, message: message, error: error);
}

/// نتيجة عملية استعادة النسخة الاحتياطية
class RestoreResult {
  final bool success;
  final String message;
  final bool isCancelled;
  final String? error;

  const RestoreResult({
    required this.success,
    required this.message,
    this.isCancelled = false,
    this.error,
  });

  factory RestoreResult.success({String? message}) => RestoreResult(
    success: true,
    message: message ?? 'تمت استعادة قاعدة البيانات بنجاح من النسخة الاحتياطية',
  );

  factory RestoreResult.cancelled({String? message}) => const RestoreResult(
    success: false,
    isCancelled: true,
    message: 'تم إلغاء عملية اختيار ملف النسخة الاحتياطية',
  );

  factory RestoreResult.error(String message, {String? error}) =>
      RestoreResult(success: false, message: message, error: error);
}

/// خدمة النسخ الاحتياطي والاستعادة المحلية لقاعدة بيانات SQLite لنظام مياه رواء
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService({DatabaseHelper? dbHelper}) {
    if (dbHelper != null) {
      return BackupService._internal(dbHelper: dbHelper);
    }
    return _instance;
  }

  BackupService._internal({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  /// الترويسة القياسية لقواعد بيانات SQLite 3 (أول 16 بايت: "SQLite format 3\000")
  static const List<int> sqliteHeaderBytes = [
    0x53,
    0x51,
    0x4c,
    0x69,
    0x74,
    0x65,
    0x20,
    0x66,
    0x6f,
    0x72,
    0x6d,
    0x61,
    0x74,
    0x20,
    0x33,
    0x00,
  ];

  static DateTime? _cachedLastBackupTime;
  static String? _cachedLastBackupFileName;

  /// توليد اسم ملف النسخة الاحتياطية بالتنسيق الزمني المطلوب: rawaa_backup_YYYYMMDD_HHMMSS.db
  static String generateBackupFileName([DateTime? time]) {
    final date = time ?? DateTime.now();
    final formatted = DateFormat('yyyyMMdd_HHmmss').format(date);
    return 'rawaa_backup_$formatted.db';
  }

  /// التحقق من مطابقة مصفوفة البايت لترويسة SQLite 3
  static bool isValidSqliteHeader(List<int> bytes) {
    if (bytes.length < 16) return false;
    for (int i = 0; i < 16; i++) {
      if (bytes[i] != sqliteHeaderBytes[i]) return false;
    }
    return true;
  }

  /// التحقق من صحة ملف قاعدة بيانات SQLite بفحص أول 16 بايت
  static Future<bool> isValidSqliteFile(File file) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 16) return false;

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      final header = await raf.read(16);
      return isValidSqliteHeader(header);
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// الحصول على المسار الفعلي لقاعدة بيانات SQLite النشطة
  Future<String> getDatabasePath() async {
    return await _dbHelper.getDatabasePath();
  }

  /// ملف حفظ معلومات النسخة الاحتياطية الأخيرة
  Future<File> _getMetadataFile() async {
    final dbPath = await getDatabasePath();
    final dir = dirname(dbPath);
    return File(join(dir, 'rawaa_backup_meta.json'));
  }

  /// جلب تاريخ وتوقيت آخر نسخة احتياطية ناجحة
  Future<DateTime?> getLastBackupTime() async {
    if (_cachedLastBackupTime != null) {
      return _cachedLastBackupTime;
    }

    try {
      final metaFile = await _getMetadataFile();
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final iso = data['last_backup_time'] as String?;
        if (iso != null) {
          _cachedLastBackupTime = DateTime.tryParse(iso);
          _cachedLastBackupFileName = data['last_backup_file'] as String?;
          return _cachedLastBackupTime;
        }
      }
    } catch (_) {
      // تجاهل أخطاء قراءة البيانات الوصفية
    }
    return null;
  }

  /// حفظ بيانات آخر نسخة احتياطية
  Future<void> saveLastBackupMetadata(DateTime time, String fileName) async {
    _cachedLastBackupTime = time;
    _cachedLastBackupFileName = fileName;
    try {
      final metaFile = await _getMetadataFile();
      final data = {
        'last_backup_time': time.toIso8601String(),
        'last_backup_file': fileName,
      };
      await metaFile.writeAsString(jsonEncode(data));
    } catch (_) {
      // تجاهل أخطاء الحفظ الثانوي
    }
  }

  /// الحصول على نص منسق لتاريخ آخر نسخة احتياطية
  Future<String> getLastBackupTimeFormatted() async {
    final lastTime = await getLastBackupTime();
    if (lastTime == null) {
      return 'لم يتم إنشاء نسخة بعد';
    }
    return DateFormatter.formatDateTime(lastTime);
  }

  /// اسم ملف آخر نسخة احتياطية تم إنشاؤها
  String? get lastBackupFileName => _cachedLastBackupFileName;

  /// إنشاء ملف النسخة الاحتياطية وحفظه محلياً
  Future<File> createBackupFile({
    String? customDestinationDir,
    String? customDbPath,
    DateTime? timestamp,
  }) async {
    // 1. فحص ومعالجة المعاملات المعلقة في قاعدة البيانات لضمان اتساق البيانات
    await _dbHelper.checkpoint();

    // 2. التحقق من وجود ملف قاعدة البيانات الأصلية
    final sourceDbPath = customDbPath ?? await getDatabasePath();
    final sourceFile = File(sourceDbPath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'ملف قاعدة البيانات الأصلي غير موجود',
        sourceDbPath,
      );
    }

    // 3. تحديد مسار الوجهة واسم الملف الزمني
    final backupTime = timestamp ?? DateTime.now();
    final fileName = generateBackupFileName(backupTime);
    final targetDir = customDestinationDir ?? Directory.systemTemp.path;
    final targetDirectory = Directory(targetDir);
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final targetPath = join(targetDir, fileName);

    // 4. نسخ ملف قاعدة البيانات
    final backupFile = await sourceFile.copy(targetPath);

    // 5. تسجيل وقت واسم آخر نسخة احتياطية
    await saveLastBackupMetadata(backupTime, fileName);

    return backupFile;
  }

  /// إنشاء نسخة احتياطية ومشاركتها فوراً عبر SharePlus
  Future<BackupResult> createBackup({
    String? customDestinationDir,
    String? customDbPath,
    bool share = true,
  }) async {
    try {
      final backupFile = await createBackupFile(
        customDestinationDir: customDestinationDir,
        customDbPath: customDbPath,
      );

      if (share) {
        final fileName = basename(backupFile.path);
        await Share.shareXFiles(
          [XFile(backupFile.path)],
          text: 'نسخة احتياطية لقاعدة بيانات مياه رواء: $fileName',
          subject: 'نسخة احتياطية - نظام مياه رواء',
        );
      }

      return BackupResult.success(
        backupFile,
        message: 'تم إنشاء النسخة الاحتياطية بنجاح ومشاركتها',
      );
    } catch (e) {
      return BackupResult.failure(
        'فشل إنشاء النسخة الاحتياطية: $e',
        error: e.toString(),
      );
    }
  }

  /// استرجاع قاعدة البيانات من ملف نسخة احتياطية (.db / .bak)
  Future<RestoreResult> restoreBackup({
    String? manualFilePath,
    FilePickerResult? customPickerResult,
  }) async {
    try {
      String? selectedFilePath = manualFilePath;

      // 1. اختيار الملف في حال لم يتم تمرير مسار مباشر
      if (selectedFilePath == null) {
        final result =
            customPickerResult ??
            await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
              dialogTitle: 'اختر ملف النسخة الاحتياطية لنظام مياه رواء',
            );

        if (result == null || result.files.isEmpty) {
          return RestoreResult.cancelled();
        }

        selectedFilePath = result.files.single.path;
      }

      if (selectedFilePath == null) {
        return RestoreResult.error('لم يتم تحديد مسار الملف المطلوب استعادته');
      }

      final sourceFile = File(selectedFilePath);
      if (!await sourceFile.exists()) {
        return RestoreResult.error('ملف النسخة الاحتياطية المحدد غير موجود');
      }

      // 2. التحقق الصارم من ترويسة SQLite
      final isValid = await isValidSqliteFile(sourceFile);
      if (!isValid) {
        return RestoreResult.error(
          'الملف المختار ليس قاعدة بيانات SQLite صالحة تابعة للنظام',
        );
      }

      // 3. إغلاق اتصال قاعدة البيانات الحالي بأمان
      await _dbHelper.close();

      // 4. استبدال ملف قاعدة بيانات التطبيق rawaa_wms.db بالملف المسترجع
      final currentDbPath = await getDatabasePath();
      final currentDbFile = File(currentDbPath);

      if (!await currentDbFile.parent.exists()) {
        await currentDbFile.parent.create(recursive: true);
      }

      await sourceFile.copy(currentDbPath);

      // 5. إعادة فتح وتهيئة اتصال قاعدة البيانات
      await _dbHelper.database;

      return RestoreResult.success(
        message: 'تمت استعادة قاعدة البيانات بنجاح من النسخة الاحتياطية',
      );
    } catch (e) {
      // محاولة استئناف الاتصال بقاعدة البيانات في حال حدوث خطأ
      try {
        await _dbHelper.database;
      } catch (_) {}

      return RestoreResult.error(
        'فشل في استعادة النسخة الاحتياطية: $e',
        error: e.toString(),
      );
    }
  }

  /// استرجاع قاعدة البيانات من مسار ملف محدد (دالة مساعدة متوافقة)
  Future<bool> restoreBackupFromFile(String filePath) async {
    final result = await restoreBackup(manualFilePath: filePath);
    return result.success;
  }
}
