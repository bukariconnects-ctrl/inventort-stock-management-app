/// ثوابت وهيكل قاعدة بيانات SQLite المحلية لنظام مياه رواء (Rawaa WMS)
class DatabaseConstants {
  DatabaseConstants._();

  static const String databaseName = 'rawaa_wms.db';
  static const int databaseVersion = 1;

  // أسماء الجداول
  static const String tableWarehouses = 'warehouses';
  static const String tableItems = 'items';
  static const String tableWarehouseStocks = 'warehouse_stocks';
  static const String tableTransactions = 'transactions';
  static const String tableStocktakes = 'stocktakes';

  // حقول جدول المستودعات (warehouses)
  static const String colWarehouseId = 'id';
  static const String colWarehouseName = 'name';
  static const String colWarehouseLocation = 'location';
  static const String colWarehouseCode = 'code';
  static const String colWarehouseMinAlertThreshold = 'min_alert_threshold';
  static const String colWarehouseCreatedAt = 'created_at';

  // حقول جدول الأصناف (items)
  static const String colItemId = 'id';
  static const String colItemName = 'name';
  static const String colItemUnit = 'unit';
  static const String colItemBottlesPerPackage = 'bottles_per_package';
  static const String colItemBottleVolume = 'bottle_volume';
  static const String colItemCreatedAt = 'created_at';

  // حقول جدول أرصدة المخازن (warehouse_stocks)
  static const String colStockId = 'id';
  static const String colStockWarehouseId = 'warehouse_id';
  static const String colStockItemId = 'item_id';
  static const String colStockQuantity = 'quantity';
  static const String colStockLastUpdated = 'last_updated';

  // حقول جدول حركات المخزون والسندات (transactions)
  static const String colTxId = 'id';
  static const String colTxVoucherNumber = 'voucher_number';
  static const String colTxType = 'type'; // receipt, issue, damage
  static const String colTxWarehouseId = 'warehouse_id';
  static const String colTxItemId = 'item_id';
  static const String colTxQuantity = 'quantity';
  static const String colTxRelatedPerson = 'related_person';
  static const String colTxReferenceNumber = 'reference_number';
  static const String colTxNotes = 'notes';
  static const String colTxDamageReason = 'damage_reason';
  static const String colTxCreatedAt = 'created_at';

  // حقول جدول الجرد والتسوية (stocktakes)
  static const String colStId = 'id';
  static const String colStCode = 'code';
  static const String colStWarehouseId = 'warehouse_id';
  static const String colStItemId = 'item_id';
  static const String colStSystemQuantity = 'system_quantity';
  static const String colStActualQuantity = 'actual_quantity';
  static const String colStDifference = 'difference';
  static const String colStNotes = 'notes';
  static const String colStCreatedAt = 'created_at';
}
