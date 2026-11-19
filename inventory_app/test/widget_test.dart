import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/core/constants/app_constants.dart';
import 'package:inventory_app/features/home/main_screen.dart';
import 'package:inventory_app/features/home/screens/dashboard_screen.dart';
import 'package:inventory_app/features/inventory/models/warehouse_stock_model.dart';
import 'package:inventory_app/features/transactions/models/stock_transaction_model.dart';
import 'package:inventory_app/features/transactions/providers/transaction_provider.dart';
import 'package:inventory_app/features/transactions/screens/operations_screen.dart';
import 'package:inventory_app/features/transactions/screens/voucher_details_screen.dart';
import 'package:inventory_app/features/warehouses/providers/warehouse_provider.dart';
import 'package:inventory_app/features/warehouses/screens/warehouses_screen.dart';
import 'package:inventory_app/main.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStockData = [
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
    WarehouseStockModel(
      id: 2,
      warehouseId: 2,
      warehouseName: 'مخزن التوزيع الخارجي',
      warehouseCode: 'WH-02',
      minAlertThreshold: 200,
      itemId: 1,
      itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
      quantity: 150, // رصيد منخفض أقل من 200 لتجربة شريط التنبيه
    ),
  ];

  group('اختبارات واجهات وسندات المرحلة 4 (Operations & Vouchers UI)', () {
    testWidgets('1. التحقق من شاشة البداية وعناصرها الأساسية', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SplashScreen(autoNavigate: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
      expect(find.text(AppConstants.defaultItemName), findsOneWidget);
      expect(find.text('الدخول إلى لوحة التحكم الرئيسية'), findsOneWidget);
    });

    testWidgets('2. التحقق من لوحة التحكم الرئيسية (DashboardScreen)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = WarehouseProvider();
      provider.setWarehousesForTesting(testStockData);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WarehouseProvider>.value(
            value: provider,
            child: const Directionality(
              textDirection: TextDirection.rtl,
              child: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // التحقق من ترويسة اللوحة والبطاقة العريضة
      expect(find.text('إجمالي المخزون الكلي'), findsOneWidget);
      expect(find.text('أرصدة المخازن الحالية'), findsOneWidget);
      expect(find.text('العمليات السريعة'), findsOneWidget);

      // التحقق من أزرار العمليات السريعة
      expect(find.text('سند استلام'), findsOneWidget);
      expect(find.text('سند صرف'), findsOneWidget);
      expect(find.text('سند إتلاف'), findsOneWidget);

      // التحقق من ظهور المخازن
      expect(find.text('المخزن الرئيسي (المصنع)'), findsOneWidget);
      expect(find.text('مخزن التوزيع الخارجي'), findsOneWidget);
      expect(find.text('WH-01'), findsOneWidget);
      expect(find.text('WH-02'), findsOneWidget);

      // التحقق من شريط التنبيه لأن WH-02 رصيده 150 أقل من 200
      expect(
        find.text('تنبيه: انخفاض المخزون في بعض المستودعات!'),
        findsOneWidget,
      );
    });

    testWidgets('3. التحقق من شاشة إدارة المخازن (WarehousesScreen)', (
      tester,
    ) async {
      final provider = WarehouseProvider();
      provider.setWarehousesForTesting(testStockData);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WarehouseProvider>.value(
            value: provider,
            child: const Directionality(
              textDirection: TextDirection.rtl,
              child: WarehousesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('إدارة المستودعات والمخازن'), findsOneWidget);
      expect(find.text('إضافة مخزن جديد'), findsOneWidget);
      expect(find.text('المخزن الرئيسي (المصنع)'), findsOneWidget);
      expect(find.text('WH-01'), findsOneWidget);
    });

    testWidgets('4. التحقق من شاشة التنقل الرئيسية (MainScreen)', (
      tester,
    ) async {
      final provider = WarehouseProvider();
      provider.setWarehousesForTesting(testStockData);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<WarehouseProvider>.value(value: provider),
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => TransactionProvider(),
              ),
            ],
            child: const Directionality(
              textDirection: TextDirection.rtl,
              child: MainScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('المخازن'), findsOneWidget);
      expect(find.text('العمليات'), findsOneWidget);
      expect(find.text('التقارير والسجل'), findsOneWidget);
    });

    testWidgets('5. التحقق من شاشة تبويب العمليات (OperationsScreen)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OperationsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('سندات وعمليات المخزون'), findsOneWidget);
      expect(find.text('سند استلام إنتاج من المصنع'), findsOneWidget);
      expect(find.text('سند صرف لموزع / مندوب'), findsOneWidget);
      expect(find.text('سند إتلاف وهدر مخزني'), findsOneWidget);
      expect(find.text('زيادة رصيد (+)'), findsOneWidget);
      expect(find.text('خصم رصيد (-)'), findsOneWidget);
      expect(find.text('خصم تالف (-)'), findsOneWidget);
    });

    testWidgets('6. التحقق من شاشة عرض تفاصيل السند (VoucherDetailsScreen)', (
      tester,
    ) async {
      final sampleTx = StockTransactionModel(
        id: 1,
        voucherNumber: 'ISS-202611-0001',
        type: 'issue',
        warehouseId: 1,
        warehouseName: 'المخزن الرئيسي (المصنع)',
        warehouseCode: 'WH-01',
        itemId: 1,
        itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
        quantity: 150,
        relatedPerson: 'المندوب فهد',
        referenceNumber: 'ORD-9921',
        notes: 'دفعة الصباح الأولى',
        createdAt: DateTime(2026, 11, 15, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: VoucherDetailsScreen(transaction: sampleTx),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('سند صرف لموزع / مندوب'), findsWidgets);
      expect(find.text('ISS-202611-0001'), findsOneWidget);
      expect(find.text('المندوب فهد'), findsOneWidget);
      expect(find.text('ORD-9921'), findsOneWidget);
      expect(
        find.text('معتمد ومسجل محلياً في قاعدة البيانات ✅'),
        findsOneWidget,
      );
      expect(find.text('معاينة وطباعة السند كملف PDF'), findsOneWidget);
    });
  });
}
