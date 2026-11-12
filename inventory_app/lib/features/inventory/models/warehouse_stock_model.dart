/// نموذج رصيد الصنف داخل مخزن معين (Warehouse Stock)
class WarehouseStockModel {
  final int? id;
  final int warehouseId;
  final int itemId;
  final int quantity;
  final DateTime lastUpdated;

  // حقول اختيارية مساعدة عند إجراء استعلامات الـ JOIN
  final String? warehouseName;
  final String? warehouseCode;
  final int? minAlertThreshold;
  final String? itemName;
  final String? itemUnit;

  WarehouseStockModel({
    this.id,
    required this.warehouseId,
    required this.itemId,
    this.quantity = 0,
    DateTime? lastUpdated,
    this.warehouseName,
    this.warehouseCode,
    this.minAlertThreshold,
    this.itemName,
    this.itemUnit,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// هل المخزون أقل من أو يساوي حد التنبيه؟
  bool get isLowStock =>
      minAlertThreshold != null && quantity <= minAlertThreshold!;

  /// هل المخزون نافد تماماً؟
  bool get isOutOfStock => quantity <= 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'warehouse_id': warehouseId,
      'item_id': itemId,
      'quantity': quantity,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory WarehouseStockModel.fromMap(Map<String, dynamic> map) {
    return WarehouseStockModel(
      id: map['id'] as int?,
      warehouseId: (map['warehouse_id'] as num).toInt(),
      itemId: (map['item_id'] as num).toInt(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'] as String) ?? DateTime.now()
          : DateTime.now(),
      warehouseName: map['warehouse_name'] as String?,
      warehouseCode: map['warehouse_code'] as String?,
      minAlertThreshold: (map['min_alert_threshold'] as num?)?.toInt(),
      itemName: map['item_name'] as String?,
      itemUnit: map['item_unit'] as String?,
    );
  }

  WarehouseStockModel copyWith({
    int? id,
    int? warehouseId,
    int? itemId,
    int? quantity,
    DateTime? lastUpdated,
    String? warehouseName,
    String? warehouseCode,
    int? minAlertThreshold,
    String? itemName,
    String? itemUnit,
  }) {
    return WarehouseStockModel(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      minAlertThreshold: minAlertThreshold ?? this.minAlertThreshold,
      itemName: itemName ?? this.itemName,
      itemUnit: itemUnit ?? this.itemUnit,
    );
  }
}
