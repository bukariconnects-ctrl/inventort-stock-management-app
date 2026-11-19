import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/core/database/database_helper.dart';
import 'package:inventory_app/core/services/backup_service.dart';
import 'package:inventory_app/features/backup/screens/settings_screen.dart';
import 'package:inventory_app/features/home/screens/dashboard_screen.dart';
import 'package:inventory_app/features/inventory/models/warehouse_stock_model.dart';
import 'package:inventory_app/features/reports/providers/reports_provider.dart';
import 'package:inventory_app/features/stocktake/providers/stocktake_provider.dart';
import 'package:inventory_app/features/transactions/providers/transaction_provider.dart';
import 'package:inventory_app/features/warehouses/providers/warehouse_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // إعداد بيئة FFI لاختبار قواعد البيانات محلياً
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper();
    await dbHelper.resetForTesting(testPath: inMemoryDatabasePath);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group(
    'اختبارات خدمة النسخ الاحتياطي والاستعادة - المرحلة 8 (BackupService Unit Tests)',
    () {
      test(
        '1. التحقق من تنسيق اسم ملف النسخة الاحتياطية الزمني (rawaa_backup_YYYYMMDD_HHMMSS.db)',
        () {
          final fixedDate = DateTime(2026, 11, 20, 14, 30, 45);
          final fileName = BackupService.generateBackupFileName(fixedDate);

          expect(fileName, equals('rawaa_backup_20261120_143045.db'));

          // التحقق عبر التعبير النمطي (RegExp)
          final regex = RegExp(r'^rawaa_backup_\d{8}_\d{6}\.db$');
          expect(regex.hasMatch(fileName), isTrue);
          expect(
            regex.hasMatch(BackupService.generateBackupFileName()),
            isTrue,
          );
        },
      );

      test('2. التحقق الصارم من فحص ترويسة ملف SQLite (Header Check)', () {
        // ترويسة SQLite 3 الصالحة ("SQLite format 3\000")
        final validHeader = [
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
          0x01,
          0x02,
        ];
        expect(BackupService.isValidSqliteHeader(validHeader), isTrue);

        // ملف قصير أقل من 16 بايت
        final shortBytes = [0x53, 0x51, 0x4c];
        expect(BackupService.isValidSqliteHeader(shortBytes), isFalse);

        // ملف تالف أو غير صالح (ملف نصي أو صورة)
        final invalidBytes = List<int>.filled(20, 0x41); // "AAAA..."
        expect(BackupService.isValidSqliteHeader(invalidBytes), isFalse);
      });

      test(
        '3. التحقق من فحص ملف SQLite فعلي من القرص (isValidSqliteFile)',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'rawaa_backup_test_',
          );

          try {
            // ملف نصي غير صالح
            final textFile = File(p.join(tempDir.path, 'dummy.txt'));
            await textFile.writeAsString('هذا ملف نصي عادي وليس قاعدة بيانات');
            expect(await BackupService.isValidSqliteFile(textFile), isFalse);

            // ملف بقالب ترويسة SQLite حقيقي
            final mockDbFile = File(p.join(tempDir.path, 'test_mock.db'));
            final bytes = Uint8List.fromList([
              ...BackupService.sqliteHeaderBytes,
              ...List<int>.filled(100, 0),
            ]);
            await mockDbFile.writeAsBytes(bytes);
            expect(await BackupService.isValidSqliteFile(mockDbFile), isTrue);

            // ملف غير موجود
            final nonExistent = File(p.join(tempDir.path, 'none.db'));
            expect(await BackupService.isValidSqliteFile(nonExistent), isFalse);
          } finally {
            await tempDir.delete(recursive: true);
          }
        },
      );

      test(
        '4. اختبار إنشاء نسخة احتياطية وحفظها محلياً (createBackupFile)',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'rawaa_db_test_',
          );
          final dbPath = p.join(tempDir.path, 'source_rawaa.db');

          // إنشاء قاعدة بيانات تجريبية حقيقية
          final db = await openDatabase(
            dbPath,
            version: 1,
            onCreate: (d, v) async {
              await d.execute(
                'CREATE TABLE test_data (id INTEGER PRIMARY KEY, note TEXT);',
              );
              await d.insert('test_data', {'note': 'سجل تجريبي'});
            },
          );
          await db.close();

          final backupService = BackupService();
          final backupDir = p.join(tempDir.path, 'my_backups');

          final backupFile = await backupService.createBackupFile(
            customDbPath: dbPath,
            customDestinationDir: backupDir,
          );

          expect(await backupFile.exists(), isTrue);
          expect(p.basename(backupFile.path), startsWith('rawaa_backup_'));
          expect(p.basename(backupFile.path), endsWith('.db'));

          // التحقق من صحة ملف النسخة ومطابقته لترويسة SQLite
          expect(await BackupService.isValidSqliteFile(backupFile), isTrue);

          // تنظيف الملفات المؤقتة
          await tempDir.delete(recursive: true);
        },
      );

      test(
        '5. اختبار استعادة قاعدة البيانات ورفض الملفات التالفة (restoreBackup)',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'rawaa_restore_test_',
          );

          try {
            final corruptFile = File(p.join(tempDir.path, 'corrupt.db'));
            await corruptFile.writeAsString(
              'ملف معطوب لا يحتوي ترويسة SQLite صالحة',
            );

            final backupService = BackupService();
            final restoreResult = await backupService.restoreBackup(
              manualFilePath: corruptFile.path,
            );

            expect(restoreResult.success, isFalse);
            expect(
              restoreResult.message,
              contains('الملف المختار ليس قاعدة بيانات SQLite صالحة'),
            );
          } finally {
            await tempDir.delete(recursive: true);
          }
        },
      );
    },
  );

  group('اختبارات واجهة الإعدادات والنسخ الاحتياطي (SettingsScreen UI Tests)', () {
    Widget buildSettingsWidget({
      required WarehouseProvider warehouseProvider,
      ReportsProvider? reportsProvider,
      StocktakeProvider? stocktakeProvider,
      TransactionProvider? transactionProvider,
      DatabaseHelper? customDbHelper,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<WarehouseProvider>.value(
            value: warehouseProvider,
          ),
          ChangeNotifierProvider<ReportsProvider?>.value(
            value: reportsProvider,
          ),
          ChangeNotifierProvider<StocktakeProvider?>.value(
            value: stocktakeProvider,
          ),
          ChangeNotifierProvider<TransactionProvider?>.value(
            value: transactionProvider,
          ),
        ],
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SettingsScreen(dbHelper: customDbHelper ?? dbHelper),
          ),
        ),
      );
    }

    testWidgets(
      '1. التحقق من بناء شاشة الإعدادات وعرض البطاقات والمعلومات الأساسية',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final warehouseProvider = WarehouseProvider();
        warehouseProvider.setWarehousesForTesting([
          WarehouseStockModel(
            id: 1,
            warehouseId: 1,
            warehouseName: 'المخزن الرئيسي (المصنع)',
            warehouseCode: 'WH-01',
            minAlertThreshold: 500,
            itemId: 1,
            itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
            quantity: 1200,
          ),
        ]);

        await tester.pumpWidget(
          buildSettingsWidget(warehouseProvider: warehouseProvider),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // التحقق من عنوان الشاشة
        expect(find.text('إعدادات النظام والنسخ الاحتياطي'), findsOneWidget);

        // التحقق من البطاقة 1: إدارة البيانات والنسخ الاحتياطي
        expect(find.text('إدارة البيانات والنسخ الاحتياطي'), findsOneWidget);
        expect(find.byKey(const Key('create_backup_button')), findsOneWidget);
        expect(find.byKey(const Key('restore_backup_button')), findsOneWidget);

        // التحقق من البطاقة 2: معلومات المنشأة والمصنع
        expect(find.text('معلومات المنشأة والمصنع'), findsOneWidget);
        expect(
          find.text('مصنع مياه رواء للمياه النقية المعبأة'),
          findsOneWidget,
        );
        expect(find.text('كرتون مياه رواء (20 عبوة × 75 مل)'), findsOneWidget);
        expect(
          find.text(
            'نظام مستقل بالكامل دون اتصال بالإنترنت (Offline-First SQLite)',
          ),
          findsOneWidget,
        );

        // التحقق من البطاقة 3: معلومات النظام والتطبيق
        expect(find.text('معلومات النظام والتطبيق'), findsOneWidget);
        expect(find.text('v1.0.0 (Production Ready)'), findsOneWidget);
        expect(find.text('SQLite متصلة وجاهزة للعمل محلياً'), findsOneWidget);
      },
    );

    testWidgets(
      '2. التحقق من حوار التحذير المسبق عند الضغط على استعادة البيانات',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final warehouseProvider = WarehouseProvider();
        warehouseProvider.setWarehousesForTesting([]);

        await tester.pumpWidget(
          buildSettingsWidget(warehouseProvider: warehouseProvider),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // الضغط على زر استعادة البيانات
        final restoreBtn = find.byKey(const Key('restore_backup_button'));
        expect(restoreBtn, findsOneWidget);
        await tester.tap(restoreBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // التحقق من ظهور حوار التحذير AlertDialog
        expect(find.text('تأكيد استعادة البيانات'), findsOneWidget);
        expect(
          find.text(
            'تحذير: استعادة نسخة سابقة ستستبدل كافة البيانات الحالية، هل تود المتابعة؟',
          ),
          findsOneWidget,
        );
        expect(find.text('إلغاء'), findsOneWidget);
        expect(find.text('متابعة واستعادة'), findsOneWidget);

        // الضغط على إلغاء لإغلاق الحوار بأمان
        await tester.tap(find.text('إلغاء'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // التحقق من اختفاء الحوار
        expect(find.text('تأكيد استعادة البيانات'), findsNothing);
      },
    );

    testWidgets(
      '3. التحقق من زر ترس الإعدادات في DashboardScreen والانتقال إلى SettingsScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final warehouseProvider = WarehouseProvider();
        warehouseProvider.setWarehousesForTesting([
          WarehouseStockModel(
            id: 1,
            warehouseId: 1,
            warehouseName: 'المخزن الرئيسي (المصنع)',
            warehouseCode: 'WH-01',
            minAlertThreshold: 500,
            itemId: 1,
            itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
            quantity: 1000,
          ),
        ]);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<WarehouseProvider>.value(
                value: warehouseProvider,
              ),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: DashboardScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // العثور على زر الإعدادات
        final settingsButton = find.byKey(
          const Key('dashboard_settings_button'),
        );
        expect(settingsButton, findsOneWidget);

        // الضغط على زر الإعدادات
        await tester.tap(settingsButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // التحقق من الوصول لشاشة الإعدادات
        expect(find.text('إعدادات النظام والنسخ الاحتياطي'), findsOneWidget);
      },
    );
  });
}
