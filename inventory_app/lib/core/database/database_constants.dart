/// ثوابت وهيكل قاعدة بيانات SQLite المحلية لنظام مياه رواء
class DatabaseConstants {
  DatabaseConstants._();

  static const String databaseName = 'rawaa_wms.db';
  static const int databaseVersion = 1;

  // أسماء الجداول
  static const String tableWarehouses = 'warehouses';
  static const String tableItems = 'items';
  static const String tableInventory = 'warehouse_inventory';
  static const String tableTransactions = 'transactions';
  static const String tableStocktakes = 'stocktakes';

  // حقول جدول المخازن (warehouses)
  static const String colWarehouseId = 'id';
  static const String colWarehouseName = 'name';
  static const String colWarehouseLocation = 'location';
  static const String colWarehouseCapacity = 'capacity_boxes';
  static const String colWarehouseIsActive = 'is_active';
  static const String colWarehouseCreatedAt = 'created_at';

  // حقول جدول الأصناف (items)
  static const String colItemId = 'id';
  static const String colItemName = 'name';
  static const String colItemSpecification = 'specification';
  static const String colItemUnit = 'unit';
  static const String colItemDefaultMinThreshold = 'default_min_threshold';

  // حقول جدول أرصدة المخازن (warehouse_inventory)
  static const String colInvId = 'id';
  static const String colInvWarehouseId = 'warehouse_id';
  static const String colInvItemId = 'item_id';
  static const String colInvCurrentStock = 'current_stock';
  static const String colInvMinThreshold = 'min_threshold';
  static const String colInvUpdatedAt = 'updated_at';

  // حقول جدول الحركات والسندات (transactions)
  static const String colTxId = 'id';
  static const String colTxNumber = 'transaction_number';
  static const String colTxType = 'type'; // receipt, issue, damage, stocktake
  static const String colTxWarehouseId = 'warehouse_id';
  static const String colTxItemId = 'item_id';
  static const String colTxQuantity = 'quantity';
  static const String colTxPartyName =
      'party_name'; // اسم الموزع / المندوب / الوجبة
  static const String colTxReference =
      'reference_note'; // ملاحظات / رقم سيارة / سبب إتلاف
  static const String colTxDate = 'transaction_date';
  static const String colTxCreatedAt = 'created_at';

  // حقول جدول الجرد والتسوية (stocktakes)
  static const String colStId = 'id';
  static const String colStNumber = 'stocktake_number';
  static const String colStWarehouseId = 'warehouse_id';
  static const String colStItemId = 'item_id';
  static const String colStBookQuantity = 'book_quantity';
  static const String colStActualQuantity = 'actual_quantity';
  static const String colStDifference = 'difference';
  static const String colStReason = 'reconciliation_reason';
  static const String colStDate = 'stocktake_date';
}
