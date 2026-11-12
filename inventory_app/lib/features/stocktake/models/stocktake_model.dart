/// نموذج جلسة الجرد والتسوية المخزنية (Stocktake & Reconciliation)
class StocktakeModel {
  final int? id;
  final String code; // كود جلسة الجرد مثل STK-2024-0001
  final int warehouseId;
  final int itemId;
  final int systemQuantity; // الرصيد الدفتري المسجل في النظام
  final int actualQuantity; // الرصيد الفعلي بعد العد اليدوي
  final int difference; // الفارق (actualQuantity - systemQuantity)
  final String? notes; // ملاحظات أو سبب التسوية
  final DateTime createdAt;

  // حقول مساعدة عند الاستعلامات المشتركة
  final String? warehouseName;
  final String? warehouseCode;
  final String? itemName;
  final String? itemUnit;

  StocktakeModel({
    this.id,
    required this.code,
    required this.warehouseId,
    required this.itemId,
    required this.systemQuantity,
    required this.actualQuantity,
    int? difference,
    this.notes,
    DateTime? createdAt,
    this.warehouseName,
    this.warehouseCode,
    this.itemName,
    this.itemUnit,
  }) : difference = difference ?? (actualQuantity - systemQuantity),
       createdAt = createdAt ?? DateTime.now();

  /// هل يوجد عجز في الجرد؟
  bool get hasDeficit => difference < 0;

  /// هل توجد زيادة في الجرد؟
  bool get hasSurplus => difference > 0;

  /// هل الجرد مطابق تماماً؟
  bool get isExactMatch => difference == 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'warehouse_id': warehouseId,
      'item_id': itemId,
      'system_quantity': systemQuantity,
      'actual_quantity': actualQuantity,
      'difference': difference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StocktakeModel.fromMap(Map<String, dynamic> map) {
    return StocktakeModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      warehouseId: (map['warehouse_id'] as num).toInt(),
      itemId: (map['item_id'] as num).toInt(),
      systemQuantity: (map['system_quantity'] as num).toInt(),
      actualQuantity: (map['actual_quantity'] as num).toInt(),
      difference:
          (map['difference'] as num?)?.toInt() ??
          ((map['actual_quantity'] as num).toInt() -
              (map['system_quantity'] as num).toInt()),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      warehouseName: map['warehouse_name'] as String?,
      warehouseCode: map['warehouse_code'] as String?,
      itemName: map['item_name'] as String?,
      itemUnit: map['item_unit'] as String?,
    );
  }

  StocktakeModel copyWith({
    int? id,
    String? code,
    int? warehouseId,
    int? itemId,
    int? systemQuantity,
    int? actualQuantity,
    int? difference,
    String? notes,
    DateTime? createdAt,
    String? warehouseName,
    String? warehouseCode,
    String? itemName,
    String? itemUnit,
  }) {
    return StocktakeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      warehouseId: warehouseId ?? this.warehouseId,
      itemId: itemId ?? this.itemId,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      difference: difference ?? this.difference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      itemName: itemName ?? this.itemName,
      itemUnit: itemUnit ?? this.itemUnit,
    );
  }
}
