/// نموذج بيانات رصيد الصنف في مستودع محدد
class WarehouseInventoryModel {
  final int? id;
  final int warehouseId;
  final int itemId;
  final int currentStock;
  final int minThreshold;
  final DateTime updatedAt;

  // حقول اختيارية محملة من الـ Join لتسهيل العرض
  final String? warehouseName;
  final String? warehouseLocation;
  final String? itemName;
  final String? itemSpecification;
  final String? itemUnit;

  WarehouseInventoryModel({
    this.id,
    required this.warehouseId,
    required this.itemId,
    required this.currentStock,
    this.minThreshold = 100,
    DateTime? updatedAt,
    this.warehouseName,
    this.warehouseLocation,
    this.itemName,
    this.itemSpecification,
    this.itemUnit,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// هل المخزون أقل من أو يساوي حد التنبيه؟
  bool get isLowStock => currentStock <= minThreshold;

  /// هل المخزون نفد بالكامل؟
  bool get isOutOfStock => currentStock <= 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'warehouse_id': warehouseId,
      'item_id': itemId,
      'current_stock': currentStock,
      'min_threshold': minThreshold,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WarehouseInventoryModel.fromMap(Map<String, dynamic> map) {
    return WarehouseInventoryModel(
      id: map['id'] as int?,
      warehouseId: (map['warehouse_id'] as num).toInt(),
      itemId: (map['item_id'] as num).toInt(),
      currentStock: (map['current_stock'] as num?)?.toInt() ?? 0,
      minThreshold: (map['min_threshold'] as num?)?.toInt() ?? 100,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      warehouseName: map['warehouse_name'] as String?,
      warehouseLocation: map['warehouse_location'] as String?,
      itemName: map['item_name'] as String?,
      itemSpecification: map['item_specification'] as String?,
      itemUnit: map['item_unit'] as String?,
    );
  }

  WarehouseInventoryModel copyWith({
    int? id,
    int? warehouseId,
    int? itemId,
    int? currentStock,
    int? minThreshold,
    DateTime? updatedAt,
    String? warehouseName,
    String? warehouseLocation,
    String? itemName,
    String? itemSpecification,
    String? itemUnit,
  }) {
    return WarehouseInventoryModel(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      itemId: itemId ?? this.itemId,
      currentStock: currentStock ?? this.currentStock,
      minThreshold: minThreshold ?? this.minThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      itemName: itemName ?? this.itemName,
      itemSpecification: itemSpecification ?? this.itemSpecification,
      itemUnit: itemUnit ?? this.itemUnit,
    );
  }
}

