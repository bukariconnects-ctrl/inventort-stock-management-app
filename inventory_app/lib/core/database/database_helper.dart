import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/inventory/models/item_model.dart';
import '../../features/inventory/models/warehouse_stock_model.dart';
import '../../features/stocktake/models/stocktake_model.dart';
import '../../features/transactions/models/stock_transaction_model.dart';
import '../../features/warehouses/models/warehouse_model.dart';
import 'database_constants.dart';
import 'database_exceptions.dart';

/// الفئة المسؤولة عن إدارة قاعدة بيانات SQLite والعمليات الذرية لنظام مياه رواء
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// الحصول على كائن قاعدة البيانات مع التهيئة التلقائية
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة وفتح ملف قاعدة البيانات
  Future<Database> _initDatabase({String? customPath}) async {
    final dbPath =
        customPath ??
        join(await getDatabasesPath(), DatabaseConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: DatabaseConstants.databaseVersion,
      onConfigure: (db) async {
        // تفعيل القيود المرجعية لسلامة العلاقات بين الجداول
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );
  }

  /// بناء الجداول والفهارس وحقن البيانات الافتراضية
  Future<void> _onCreate(Database db, int version) async {
    // 1. جدول المخازن (warehouses)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableWarehouses} (
        ${DatabaseConstants.colWarehouseId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colWarehouseName} TEXT NOT NULL,
        ${DatabaseConstants.colWarehouseLocation} TEXT,
        ${DatabaseConstants.colWarehouseCode} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.colWarehouseMinAlertThreshold} INTEGER NOT NULL DEFAULT 100,
        ${DatabaseConstants.colWarehouseCreatedAt} TEXT NOT NULL
      );
    ''');

    // 2. جدول الأصناف (items)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableItems} (
        ${DatabaseConstants.colItemId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colItemName} TEXT NOT NULL,
        ${DatabaseConstants.colItemUnit} TEXT NOT NULL DEFAULT 'كرتون',
        ${DatabaseConstants.colItemBottlesPerPackage} INTEGER NOT NULL DEFAULT 20,
        ${DatabaseConstants.colItemBottleVolume} TEXT NOT NULL DEFAULT '75 مل',
        ${DatabaseConstants.colItemCreatedAt} TEXT NOT NULL
      );
    ''');

    // 3. جدول أرصدة المخازن (warehouse_stocks)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableWarehouseStocks} (
        ${DatabaseConstants.colStockId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colStockWarehouseId} INTEGER NOT NULL,
        ${DatabaseConstants.colStockItemId} INTEGER NOT NULL,
        ${DatabaseConstants.colStockQuantity} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colStockLastUpdated} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConstants.colStockWarehouseId}) 
          REFERENCES ${DatabaseConstants.tableWarehouses} (${DatabaseConstants.colWarehouseId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.colStockItemId}) 
          REFERENCES ${DatabaseConstants.tableItems} (${DatabaseConstants.colItemId}) 
          ON DELETE CASCADE,
        UNIQUE (${DatabaseConstants.colStockWarehouseId}, ${DatabaseConstants.colStockItemId})
      );
    ''');

    // 4. جدول حركات وسندات المخزون (transactions)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableTransactions} (
        ${DatabaseConstants.colTxId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colTxVoucherNumber} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.colTxType} TEXT NOT NULL,
        ${DatabaseConstants.colTxWarehouseId} INTEGER NOT NULL,
        ${DatabaseConstants.colTxItemId} INTEGER NOT NULL,
        ${DatabaseConstants.colTxQuantity} INTEGER NOT NULL,
        ${DatabaseConstants.colTxRelatedPerson} TEXT NOT NULL,
        ${DatabaseConstants.colTxReferenceNumber} TEXT,
        ${DatabaseConstants.colTxNotes} TEXT,
        ${DatabaseConstants.colTxDamageReason} TEXT,
        ${DatabaseConstants.colTxCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConstants.colTxWarehouseId}) 
          REFERENCES ${DatabaseConstants.tableWarehouses} (${DatabaseConstants.colWarehouseId}) 
          ON DELETE RESTRICT,
        FOREIGN KEY (${DatabaseConstants.colTxItemId}) 
          REFERENCES ${DatabaseConstants.tableItems} (${DatabaseConstants.colItemId}) 
          ON DELETE RESTRICT
      );
    ''');

    // 5. جدول الجرد والتسوية (stocktakes)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableStocktakes} (
        ${DatabaseConstants.colStId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colStCode} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.colStWarehouseId} INTEGER NOT NULL,
        ${DatabaseConstants.colStItemId} INTEGER NOT NULL,
        ${DatabaseConstants.colStSystemQuantity} INTEGER NOT NULL,
        ${DatabaseConstants.colStActualQuantity} INTEGER NOT NULL,
        ${DatabaseConstants.colStDifference} INTEGER NOT NULL,
        ${DatabaseConstants.colStNotes} TEXT,
        ${DatabaseConstants.colStCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConstants.colStWarehouseId}) 
          REFERENCES ${DatabaseConstants.tableWarehouses} (${DatabaseConstants.colWarehouseId}) 
          ON DELETE RESTRICT,
        FOREIGN KEY (${DatabaseConstants.colStItemId}) 
          REFERENCES ${DatabaseConstants.tableItems} (${DatabaseConstants.colItemId}) 
          ON DELETE RESTRICT
      );
    ''');

    // إنشاء الفهارس لتحسين سرعة الاستعلامات والفلترة
    await db.execute(
      'CREATE INDEX idx_transactions_warehouse ON ${DatabaseConstants.tableTransactions} (${DatabaseConstants.colTxWarehouseId});',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_type ON ${DatabaseConstants.tableTransactions} (${DatabaseConstants.colTxType});',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_created_at ON ${DatabaseConstants.tableTransactions} (${DatabaseConstants.colTxCreatedAt});',
    );
    await db.execute(
      'CREATE INDEX idx_stocks_warehouse ON ${DatabaseConstants.tableWarehouseStocks} (${DatabaseConstants.colStockWarehouseId});',
    );
    await db.execute(
      'CREATE INDEX idx_stocktakes_warehouse ON ${DatabaseConstants.tableStocktakes} (${DatabaseConstants.colStWarehouseId});',
    );

    // حقن البيانات الافتراضية الأولية (Seed Data)
    await _seedInitialData(db);
  }

  /// حقن الصنف الافتراضي والمخازن الافتراضية
  Future<void> _seedInitialData(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();

    // 1. إدراج الصنف الافتراضي
    final defaultItem = ItemModel(
      name: 'كرتون مياه رواء - 20 علبة × 75 مل',
      unit: 'كرتون',
      bottlesPerPackage: 20,
      bottleVolume: '75 مل',
    );
    final itemId = await db.insert(
      DatabaseConstants.tableItems,
      defaultItem.toMap(),
    );

    // 2. إدراج المخزنين الافتراضيين
    final wh1 = WarehouseModel(
      name: 'المخزن الرئيسي (المصنع)',
      location: 'عنبر الإنتاج - البوابة أ',
      code: 'WH-01',
      minAlertThreshold: 500,
    );
    final wh2 = WarehouseModel(
      name: 'مخزن التوزيع الخارجي',
      location: 'منطقة الشحن والتوزيع',
      code: 'WH-02',
      minAlertThreshold: 200,
    );

    final wh1Id = await db.insert(
      DatabaseConstants.tableWarehouses,
      wh1.toMap(),
    );
    final wh2Id = await db.insert(
      DatabaseConstants.tableWarehouses,
      wh2.toMap(),
    );

    // 3. تهيئة سجلات الأرصدة للمخازن برصيد ابتدائي (0)
    await db.insert(DatabaseConstants.tableWarehouseStocks, {
      DatabaseConstants.colStockWarehouseId: wh1Id,
      DatabaseConstants.colStockItemId: itemId,
      DatabaseConstants.colStockQuantity: 0,
      DatabaseConstants.colStockLastUpdated: now,
    });

    await db.insert(DatabaseConstants.tableWarehouseStocks, {
      DatabaseConstants.colStockWarehouseId: wh2Id,
      DatabaseConstants.colStockItemId: itemId,
      DatabaseConstants.colStockQuantity: 0,
      DatabaseConstants.colStockLastUpdated: now,
    });
  }

  // =========================================================================
  // العمليات الذرية (Atomic Business Transactions)
  // =========================================================================

  /// 1. تنفيذ سند استلام إنتاج (Receipt Transaction):
  /// - حفظ سند الاستلام في جدول transactions.
  /// - زيادة رصيد المخزن المحدد للصنف في warehouse_stocks كمعاملة ذرية واحدة.
  Future<int> insertReceiptTransaction(StockTransactionModel tx) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // حفظ السند
      final txMap = tx.toMap();
      txMap[DatabaseConstants.colTxType] = 'receipt';
      final txId = await txn.insert(DatabaseConstants.tableTransactions, txMap);

      // زيادة رصيد المخزن (أو إدراجه إن لم يكن موجوداً)
      final existingStocks = await txn.query(
        DatabaseConstants.tableWarehouseStocks,
        where:
            '${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?',
        whereArgs: [tx.warehouseId, tx.itemId],
      );

      if (existingStocks.isEmpty) {
        await txn.insert(DatabaseConstants.tableWarehouseStocks, {
          DatabaseConstants.colStockWarehouseId: tx.warehouseId,
          DatabaseConstants.colStockItemId: tx.itemId,
          DatabaseConstants.colStockQuantity: tx.quantity,
          DatabaseConstants.colStockLastUpdated: now,
        });
      } else {
        await txn.rawUpdate(
          '''
          UPDATE ${DatabaseConstants.tableWarehouseStocks}
          SET ${DatabaseConstants.colStockQuantity} = ${DatabaseConstants.colStockQuantity} + ?,
              ${DatabaseConstants.colStockLastUpdated} = ?
          WHERE ${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?
        ''',
          [tx.quantity, now, tx.warehouseId, tx.itemId],
        );
      }

      return txId;
    });
  }

  /// 2. تنفيذ سند صرف للموزع (Issue Transaction):
  /// - التحقق من توفر الرصيد الكافي في المخزن.
  /// - إلقاء استثناء InsufficientStockException في حال عدم الكفاية.
  /// - خصم الكمية من warehouse_stocks وحفظ السند ذرياً.
  Future<int> insertIssueTransaction(StockTransactionModel tx) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // فحص الرصيد المتوفر حالياً
      final stockRows = await txn.query(
        DatabaseConstants.tableWarehouseStocks,
        columns: [DatabaseConstants.colStockQuantity],
        where:
            '${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?',
        whereArgs: [tx.warehouseId, tx.itemId],
      );

      final currentStock = stockRows.isNotEmpty
          ? (stockRows.first[DatabaseConstants.colStockQuantity] as num).toInt()
          : 0;

      if (currentStock < tx.quantity) {
        throw InsufficientStockException(
          'الرصيد المتاح لا يكفي لعملية الصرف',
          currentStock,
          tx.quantity,
        );
      }

      // خصم الكمية من رصيد المخزن
      await txn.rawUpdate(
        '''
        UPDATE ${DatabaseConstants.tableWarehouseStocks}
        SET ${DatabaseConstants.colStockQuantity} = ${DatabaseConstants.colStockQuantity} - ?,
            ${DatabaseConstants.colStockLastUpdated} = ?
        WHERE ${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?
      ''',
        [tx.quantity, now, tx.warehouseId, tx.itemId],
      );

      // حفظ السند
      final txMap = tx.toMap();
      txMap[DatabaseConstants.colTxType] = 'issue';
      final txId = await txn.insert(DatabaseConstants.tableTransactions, txMap);

      return txId;
    });
  }

  /// 3. تنفيذ سند إتلاف وهدر (Damage Transaction):
  /// - التحقق من توفر الكمية التالفة في الرصيد لمنع الأرصدة السالبة.
  /// - خصم الكمية وحفظ سند الإتلاف مع توثيق سبب الإتلاف.
  Future<int> insertDamageTransaction(StockTransactionModel tx) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // فحص الرصيد المتوفر
      final stockRows = await txn.query(
        DatabaseConstants.tableWarehouseStocks,
        columns: [DatabaseConstants.colStockQuantity],
        where:
            '${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?',
        whereArgs: [tx.warehouseId, tx.itemId],
      );

      final currentStock = stockRows.isNotEmpty
          ? (stockRows.first[DatabaseConstants.colStockQuantity] as num).toInt()
          : 0;

      if (currentStock < tx.quantity) {
        throw InsufficientStockException(
          'رصيد المخزن لا يكفي لتسجيل إتلاف بهذه الكمية',
          currentStock,
          tx.quantity,
        );
      }

      // خصم الكمية التالفة
      await txn.rawUpdate(
        '''
        UPDATE ${DatabaseConstants.tableWarehouseStocks}
        SET ${DatabaseConstants.colStockQuantity} = ${DatabaseConstants.colStockQuantity} - ?,
            ${DatabaseConstants.colStockLastUpdated} = ?
        WHERE ${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?
      ''',
        [tx.quantity, now, tx.warehouseId, tx.itemId],
      );

      // حفظ سند الإتلاف
      final txMap = tx.toMap();
      txMap[DatabaseConstants.colTxType] = 'damage';
      final txId = await txn.insert(DatabaseConstants.tableTransactions, txMap);

      return txId;
    });
  }

  /// 4. تنفيذ تسوية الجرد المخزني (Stocktake Reconciliation):
  /// - حفظ جلسة الجرد والفارق المسجل في جدول stocktakes.
  /// - ضبط رصيد المخزن في warehouse_stocks ليطابق الكمية الفعلية (actualQuantity) مباشرة.
  Future<int> executeStocktakeReconciliation(StocktakeModel stocktake) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // حفظ سجل الجرد والتسوية
      final stocktakeId = await txn.insert(
        DatabaseConstants.tableStocktakes,
        stocktake.toMap(),
      );

      // تحديث رصيد المخزن ليطابق الرصيد الفعلي بعد الجرد
      final updatedRows = await txn.rawUpdate(
        '''
        UPDATE ${DatabaseConstants.tableWarehouseStocks}
        SET ${DatabaseConstants.colStockQuantity} = ?,
            ${DatabaseConstants.colStockLastUpdated} = ?
        WHERE ${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?
      ''',
        [
          stocktake.actualQuantity,
          now,
          stocktake.warehouseId,
          stocktake.itemId,
        ],
      );

      // إذا لم يكن السجل موجوداً يتم إنشاؤه
      if (updatedRows == 0) {
        await txn.insert(DatabaseConstants.tableWarehouseStocks, {
          DatabaseConstants.colStockWarehouseId: stocktake.warehouseId,
          DatabaseConstants.colStockItemId: stocktake.itemId,
          DatabaseConstants.colStockQuantity: stocktake.actualQuantity,
          DatabaseConstants.colStockLastUpdated: now,
        });
      }

      return stocktakeId;
    });
  }

  // =========================================================================
  // دوال الاستعلام والفلترة المساعدة (Queries)
  // =========================================================================

  /// جلب كافة المخازن مع أرصدتها الحالية وحالة التنبيه
  Future<List<WarehouseStockModel>> getAllWarehousesWithStock() async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT 
        s.${DatabaseConstants.colStockId},
        w.${DatabaseConstants.colWarehouseId} AS warehouse_id,
        w.${DatabaseConstants.colWarehouseName} AS warehouse_name,
        w.${DatabaseConstants.colWarehouseCode} AS warehouse_code,
        w.${DatabaseConstants.colWarehouseMinAlertThreshold} AS min_alert_threshold,
        i.${DatabaseConstants.colItemId} AS item_id,
        i.${DatabaseConstants.colItemName} AS item_name,
        i.${DatabaseConstants.colItemUnit} AS item_unit,
        COALESCE(s.${DatabaseConstants.colStockQuantity}, 0) AS quantity,
        COALESCE(s.${DatabaseConstants.colStockLastUpdated}, w.${DatabaseConstants.colWarehouseCreatedAt}) AS last_updated
      FROM ${DatabaseConstants.tableWarehouses} w
      CROSS JOIN ${DatabaseConstants.tableItems} i
      LEFT JOIN ${DatabaseConstants.tableWarehouseStocks} s 
        ON w.${DatabaseConstants.colWarehouseId} = s.${DatabaseConstants.colStockWarehouseId} 
        AND i.${DatabaseConstants.colItemId} = s.${DatabaseConstants.colStockItemId}
      ORDER BY w.${DatabaseConstants.colWarehouseId} ASC
    ''');

    return results.map((map) => WarehouseStockModel.fromMap(map)).toList();
  }

  /// جلب قائمة المخازن فقط
  Future<List<WarehouseModel>> getAllWarehouses() async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.tableWarehouses,
      orderBy: '${DatabaseConstants.colWarehouseId} ASC',
    );
    return results.map((map) => WarehouseModel.fromMap(map)).toList();
  }

  /// جلب مخزن بواسطة معرّفه
  Future<WarehouseModel?> getWarehouseById(int id) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.tableWarehouses,
      where: '${DatabaseConstants.colWarehouseId} = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return WarehouseModel.fromMap(results.first);
  }

  /// إضافة مخزن جديد مع تهيئة رصيده الافتراضي للصنف
  Future<int> insertWarehouse(WarehouseModel warehouse) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      final warehouseId = await txn.insert(
        DatabaseConstants.tableWarehouses,
        warehouse.toMap(),
      );

      // تهيئة الرصيد للصنف الأساسي
      final items = await txn.query(DatabaseConstants.tableItems, limit: 1);
      if (items.isNotEmpty) {
        final itemId = (items.first[DatabaseConstants.colItemId] as num)
            .toInt();
        await txn.insert(DatabaseConstants.tableWarehouseStocks, {
          DatabaseConstants.colStockWarehouseId: warehouseId,
          DatabaseConstants.colStockItemId: itemId,
          DatabaseConstants.colStockQuantity: 0,
          DatabaseConstants.colStockLastUpdated: DateTime.now()
              .toIso8601String(),
        });
      }

      return warehouseId;
    });
  }

  /// تحديث بيانات مخزن
  Future<int> updateWarehouse(WarehouseModel warehouse) async {
    final db = await database;
    return await db.update(
      DatabaseConstants.tableWarehouses,
      warehouse.toMap(),
      where: '${DatabaseConstants.colWarehouseId} = ?',
      whereArgs: [warehouse.id],
    );
  }

  /// جلب بيانات الصنف الأساسي (كرتون مياه رواء)
  Future<ItemModel?> getDefaultItem() async {
    final db = await database;
    final results = await db.query(DatabaseConstants.tableItems, limit: 1);
    if (results.isEmpty) return null;
    return ItemModel.fromMap(results.first);
  }

  /// جلب رصيد صنف معين في مخزن محدد
  Future<int> getWarehouseStockQuantity(int warehouseId, int itemId) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.tableWarehouseStocks,
      columns: [DatabaseConstants.colStockQuantity],
      where:
          '${DatabaseConstants.colStockWarehouseId} = ? AND ${DatabaseConstants.colStockItemId} = ?',
      whereArgs: [warehouseId, itemId],
    );
    if (results.isEmpty) return 0;
    return (results.first[DatabaseConstants.colStockQuantity] as num).toInt();
  }

  /// جلب سجل الحركات مع الفلترة
  Future<List<StockTransactionModel>> getTransactions({
    int? warehouseId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (warehouseId != null) {
      whereClauses.add('t.${DatabaseConstants.colTxWarehouseId} = ?');
      whereArgs.add(warehouseId);
    }

    if (type != null && type.isNotEmpty) {
      whereClauses.add('t.${DatabaseConstants.colTxType} = ?');
      whereArgs.add(type);
    }

    if (startDate != null) {
      whereClauses.add('t.${DatabaseConstants.colTxCreatedAt} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('t.${DatabaseConstants.colTxCreatedAt} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final sql =
        '''
      SELECT 
        t.*,
        w.${DatabaseConstants.colWarehouseName} AS warehouse_name,
        w.${DatabaseConstants.colWarehouseCode} AS warehouse_code,
        i.${DatabaseConstants.colItemName} AS item_name,
        i.${DatabaseConstants.colItemUnit} AS item_unit
      FROM ${DatabaseConstants.tableTransactions} t
      JOIN ${DatabaseConstants.tableWarehouses} w 
        ON t.${DatabaseConstants.colTxWarehouseId} = w.${DatabaseConstants.colWarehouseId}
      JOIN ${DatabaseConstants.tableItems} i 
        ON t.${DatabaseConstants.colTxItemId} = i.${DatabaseConstants.colItemId}
      $whereString
      ORDER BY t.${DatabaseConstants.colTxId} DESC
      $limitClause $offsetClause
    ''';

    final results = await db.rawQuery(sql, whereArgs);
    return results.map((map) => StockTransactionModel.fromMap(map)).toList();
  }

  /// جلب سجلات الجرد والتسوية
  Future<List<StocktakeModel>> getStocktakes({
    int? warehouseId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (warehouseId != null) {
      whereClauses.add('s.${DatabaseConstants.colStWarehouseId} = ?');
      whereArgs.add(warehouseId);
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final sql =
        '''
      SELECT 
        s.*,
        w.${DatabaseConstants.colWarehouseName} AS warehouse_name,
        w.${DatabaseConstants.colWarehouseCode} AS warehouse_code,
        i.${DatabaseConstants.colItemName} AS item_name,
        i.${DatabaseConstants.colItemUnit} AS item_unit
      FROM ${DatabaseConstants.tableStocktakes} s
      JOIN ${DatabaseConstants.tableWarehouses} w 
        ON s.${DatabaseConstants.colStWarehouseId} = w.${DatabaseConstants.colWarehouseId}
      JOIN ${DatabaseConstants.tableItems} i 
        ON s.${DatabaseConstants.colStItemId} = i.${DatabaseConstants.colItemId}
      $whereString
      ORDER BY s.${DatabaseConstants.colStId} DESC
      $limitClause $offsetClause
    ''';

    final results = await db.rawQuery(sql, whereArgs);
    return results.map((map) => StocktakeModel.fromMap(map)).toList();
  }

  /// توليد رقم السند التلقائي التالي بناءً على نوعه والشهر الحالي
  /// مثال: REC-202411-0001 أو ISS-202411-0001
  Future<String> generateNextVoucherNumber(String type) async {
    final db = await database;

    String prefix;
    switch (type.toLowerCase()) {
      case 'receipt':
        prefix = 'REC';
        break;
      case 'issue':
        prefix = 'ISS';
        break;
      case 'damage':
        prefix = 'DAM';
        break;
      case 'stocktake':
        prefix = 'STK';
        break;
      default:
        prefix = 'VOU';
    }

    final now = DateTime.now();
    final yearMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final pattern = '$prefix-$yearMonth-%';

    if (prefix == 'STK') {
      final results = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${DatabaseConstants.tableStocktakes}
        WHERE ${DatabaseConstants.colStCode} LIKE ?
      ''',
        [pattern],
      );
      final count = (results.first['count'] as num?)?.toInt() ?? 0;
      final sequence = (count + 1).toString().padLeft(4, '0');
      return '$prefix-$yearMonth-$sequence';
    } else {
      final results = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${DatabaseConstants.tableTransactions}
        WHERE ${DatabaseConstants.colTxVoucherNumber} LIKE ?
      ''',
        [pattern],
      );
      final count = (results.first['count'] as num?)?.toInt() ?? 0;
      final sequence = (count + 1).toString().padLeft(4, '0');
      return '$prefix-$yearMonth-$sequence';
    }
  }

  /// الحصول على المسار الفعلي لملف قاعدة البيانات
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), DatabaseConstants.databaseName);
  }

  /// تنفيذ فحص ومعالجة سجل الكتابة المسبقة (WAL Checkpoint) لضمان اتساق البيانات على القرص
  Future<void> checkpoint() async {
    if (_database != null && _database!.isOpen) {
      try {
        await _database!.rawQuery('PRAGMA wal_checkpoint(FULL);');
      } catch (_) {
        // تجاهل في حال عدم تفعيل نمط WAL
      }
    }
  }

  /// الحصول على إجمالي عدد السندات المخزنية الصادرة
  Future<int> getTotalTransactionsCount() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableTransactions}',
    );
    return (res.first['count'] as num?)?.toInt() ?? 0;
  }

  /// الحصول على إجمالي عدد المخازن المفعلة
  Future<int> getTotalWarehousesCount() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableWarehouses}',
    );
    return (res.first['count'] as num?)?.toInt() ?? 0;
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// إعادة تعيين قاعدة البيانات للاختبارات
  Future<void> resetForTesting({String? testPath}) async {
    await close();
    if (testPath != null) {
      await deleteDatabase(testPath);
      _database = await _initDatabase(customPath: testPath);
    } else {
      final path = join(
        await getDatabasesPath(),
        DatabaseConstants.databaseName,
      );
      await deleteDatabase(path);
      _database = await _initDatabase();
    }
  }
}
