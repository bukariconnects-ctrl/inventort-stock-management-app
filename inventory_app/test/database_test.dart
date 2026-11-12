import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/core/database/database_exceptions.dart';
import 'package:inventory_app/core/database/database_helper.dart';
import 'package:inventory_app/features/stocktake/models/stocktake_model.dart';
import 'package:inventory_app/features/transactions/models/stock_transaction_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // إعداد بيئة FFI لاختبار SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper();
    // إعادة تعيين قاعدة بيانات تجريبية في الذاكرة
    await dbHelper.resetForTesting(testPath: inMemoryDatabasePath);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('اختبارات طبقة قاعدة البيانات SQLite ونظام مياه رواء - المرحلة 2', () {
    test('1. التحقق من حقن البيانات الافتراضية (Initial Seed Data)', () async {
      // التحقق من الصنف الافتراضي
      final item = await dbHelper.getDefaultItem();
      expect(item, isNotNull);
      expect(item!.name, contains('مياه رواء'));
      expect(item.bottlesPerPackage, 20);
      expect(item.bottleVolume, '75 مل');

      // التحقق من المخزنين الافتراضيين
      final warehouses = await dbHelper.getAllWarehouses();
      expect(warehouses.length, 2);
      expect(warehouses[0].code, 'WH-01');
      expect(warehouses[0].minAlertThreshold, 500);
      expect(warehouses[1].code, 'WH-02');
      expect(warehouses[1].minAlertThreshold, 200);

      // التحقق من أن الرصيد الابتدائي صفر لكلا المخزنين
      final stockWh1 = await dbHelper.getWarehouseStockQuantity(
        warehouses[0].id!,
        item.id!,
      );
      final stockWh2 = await dbHelper.getWarehouseStockQuantity(
        warehouses[1].id!,
        item.id!,
      );
      expect(stockWh1, 0);
      expect(stockWh2, 0);
    });

    test(
      '2. التحقق من سند الاستلام الذري (Atomic Receipt Transaction)',
      () async {
        final item = (await dbHelper.getDefaultItem())!;
        final warehouses = await dbHelper.getAllWarehouses();
        final wh1 = warehouses.first;

        final receiptTx = StockTransactionModel(
          voucherNumber: 'REC-202611-0001',
          type: 'receipt',
          warehouseId: wh1.id!,
          itemId: item.id!,
          quantity: 500,
          relatedPerson: 'مهندس خط الإنتاج - خط 1',
          referenceNumber: 'BATCH-20261113-A',
          notes: 'دفعة الصباح الأولى',
        );

        final txId = await dbHelper.insertReceiptTransaction(receiptTx);
        expect(txId, greaterThan(0));

        // التحقق من زيادة الرصيد إلى 500 كرتون
        final updatedStock = await dbHelper.getWarehouseStockQuantity(
          wh1.id!,
          item.id!,
        );
        expect(updatedStock, 500);

        // التحقق من تسجيل السند في الأرشيف
        final transactions = await dbHelper.getTransactions(
          warehouseId: wh1.id!,
        );
        expect(transactions.length, 1);
        expect(transactions.first.voucherNumber, 'REC-202611-0001');
        expect(transactions.first.type, 'receipt');
        expect(transactions.first.quantity, 500);
      },
    );

    test('3. التحقق من سند الصرف الذري (Atomic Issue Transaction)', () async {
      final item = (await dbHelper.getDefaultItem())!;
      final warehouses = await dbHelper.getAllWarehouses();
      final wh1 = warehouses.first;

      // إيداع مبدئي 500 كرتون
      await dbHelper.insertReceiptTransaction(
        StockTransactionModel(
          voucherNumber: 'REC-202611-0001',
          type: 'receipt',
          warehouseId: wh1.id!,
          itemId: item.id!,
          quantity: 500,
          relatedPerson: 'المصنع',
        ),
      );

      // صرف 180 كرتون لمندوب
      final issueTx = StockTransactionModel(
        voucherNumber: 'ISS-202611-0001',
        type: 'issue',
        warehouseId: wh1.id!,
        itemId: item.id!,
        quantity: 180,
        relatedPerson: 'المندوب أحمد - سيارة رقم 42',
        referenceNumber: 'ORDER-991',
        notes: 'توزيع خط شمال المدينة',
      );

      final txId = await dbHelper.insertIssueTransaction(issueTx);
      expect(txId, greaterThan(0));

      // التحقق من خصم الرصيد: 500 - 180 = 320 كرتون
      final remainingStock = await dbHelper.getWarehouseStockQuantity(
        wh1.id!,
        item.id!,
      );
      expect(remainingStock, 320);
    });

    test(
      '4. التحقق من منع الأرصدة السالبة وإلقاء InsufficientStockException',
      () async {
        final item = (await dbHelper.getDefaultItem())!;
        final warehouses = await dbHelper.getAllWarehouses();
        final wh1 = warehouses.first;

        // الرصيد الحالي هو 0
        final initialStock = await dbHelper.getWarehouseStockQuantity(
          wh1.id!,
          item.id!,
        );
        expect(initialStock, 0);

        // محاولة صرف 50 كرتون ورصيد المخزن 0
        final invalidIssueTx = StockTransactionModel(
          voucherNumber: 'ISS-202611-0002',
          type: 'issue',
          warehouseId: wh1.id!,
          itemId: item.id!,
          quantity: 50,
          relatedPerson: 'الموزع خالد',
        );

        expect(
          () async => await dbHelper.insertIssueTransaction(invalidIssueTx),
          throwsA(isA<InsufficientStockException>()),
        );

        // التأكد من بقاء الرصيد صفر وعدم تسجيل أي حركة خاطئة
        final stockAfterFail = await dbHelper.getWarehouseStockQuantity(
          wh1.id!,
          item.id!,
        );
        expect(stockAfterFail, 0);

        final transactions = await dbHelper.getTransactions(
          warehouseId: wh1.id!,
        );
        expect(transactions.isEmpty, isTrue);
      },
    );

    test(
      '5. التحقق من سند الإتلاف والهدر (Atomic Damage Transaction)',
      () async {
        final item = (await dbHelper.getDefaultItem())!;
        final warehouses = await dbHelper.getAllWarehouses();
        final wh1 = warehouses.first;

        // إيداع 100 كرتون
        await dbHelper.insertReceiptTransaction(
          StockTransactionModel(
            voucherNumber: 'REC-202611-0001',
            type: 'receipt',
            warehouseId: wh1.id!,
            itemId: item.id!,
            quantity: 100,
            relatedPerson: 'المصنع',
          ),
        );

        // تسجيل إتلاف 5 كراتين مع ذكر السبب
        final damageTx = StockTransactionModel(
          voucherNumber: 'DAM-202611-0001',
          type: 'damage',
          warehouseId: wh1.id!,
          itemId: item.id!,
          quantity: 5,
          relatedPerson: 'أمين المخزن',
          damageReason: 'كسر وتسريب عبوات أثناء النقل بالرافعة الشوكية',
        );

        final txId = await dbHelper.insertDamageTransaction(damageTx);
        expect(txId, greaterThan(0));

        // التحقق من خصم الكمية: 100 - 5 = 95
        final remainingStock = await dbHelper.getWarehouseStockQuantity(
          wh1.id!,
          item.id!,
        );
        expect(remainingStock, 95);
      },
    );

    test(
      '6. التحقق من تسوية الجرد المخزني (Stocktake Reconciliation)',
      () async {
        final item = (await dbHelper.getDefaultItem())!;
        final warehouses = await dbHelper.getAllWarehouses();
        final wh1 = warehouses.first;

        // الرصيد الدفتري المسجل حالياً = 100
        await dbHelper.insertReceiptTransaction(
          StockTransactionModel(
            voucherNumber: 'REC-202611-0001',
            type: 'receipt',
            warehouseId: wh1.id!,
            itemId: item.id!,
            quantity: 100,
            relatedPerson: 'المصنع',
          ),
        );

        // نتيجة الجرد الفعلي: تم عد 115 كرتون (فائض +15 كرتون)
        final stocktake = StocktakeModel(
          code: 'STK-202611-0001',
          warehouseId: wh1.id!,
          itemId: item.id!,
          systemQuantity: 100,
          actualQuantity: 115,
          notes: 'تسوية جرد نهاية الأسبوع - بضاعة مرحلة غير مقيدة',
        );

        final stocktakeId = await dbHelper.executeStocktakeReconciliation(
          stocktake,
        );
        expect(stocktakeId, greaterThan(0));

        // التحقق من أن الرصيد أصبح مساوياً تماماً للكمية الفعلية (115)
        final reconciledStock = await dbHelper.getWarehouseStockQuantity(
          wh1.id!,
          item.id!,
        );
        expect(reconciledStock, 115);

        // التحقق من حفظ الجلسة والفارق
        final stocktakes = await dbHelper.getStocktakes(warehouseId: wh1.id!);
        expect(stocktakes.length, 1);
        expect(stocktakes.first.difference, 15);
        expect(stocktakes.first.hasSurplus, isTrue);
      },
    );

    test(
      '7. التحقق من توليد أرقام السندات التلقائية والتسلسل الشهري',
      () async {
        final nextRec = await dbHelper.generateNextVoucherNumber('receipt');
        final nextIss = await dbHelper.generateNextVoucherNumber('issue');
        final nextDam = await dbHelper.generateNextVoucherNumber('damage');
        final nextStk = await dbHelper.generateNextVoucherNumber('stocktake');

        expect(nextRec, matches(r'^REC-\d{6}-0001$'));
        expect(nextIss, matches(r'^ISS-\d{6}-0001$'));
        expect(nextDam, matches(r'^DAM-\d{6}-0001$'));
        expect(nextStk, matches(r'^STK-\d{6}-0001$'));
      },
    );

    test(
      '8. التحقق من استعلام المخازن وحالة تنبيه انخفاض الرصيد (Low Stock Alert)',
      () async {
        final stocks = await dbHelper.getAllWarehousesWithStock();
        expect(stocks.length, 2);

        // بما أن الرصيد 0 وهو أقل من حد التنبيه (500 و 200)، يجب أن تكون حالة التنبيه نشطة
        expect(stocks[0].isLowStock, isTrue);
        expect(stocks[0].isOutOfStock, isTrue);
        expect(stocks[0].warehouseCode, 'WH-01');
        expect(stocks[0].itemName, contains('مياه رواء'));
      },
    );
  });
}
