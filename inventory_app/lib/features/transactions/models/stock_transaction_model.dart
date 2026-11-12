/// نموذج سند حركة المخزون (استلام، صرف، إتلاف)
class StockTransactionModel {
  final int? id;
  final String voucherNumber;
  final String type; // receipt, issue, damage
  final int warehouseId;
  final int itemId;
  final int quantity;
  final String relatedPerson; // اسم المسلم للمصنع أو المندوب أو المسؤول
  final String? referenceNumber; // رقم أمر الصرف أو رقم الشحنة
  final String? notes;
  final String? damageReason; // سبب الإتلاف (كسر، تسريب، تغليف تالف...)
  final DateTime createdAt;

  // حقول مساعدة عند الاستعلامات المشتركة
  final String? warehouseName;
  final String? warehouseCode;
  final String? itemName;
  final String? itemUnit;

  StockTransactionModel({
    this.id,
    required this.voucherNumber,
    required this.type,
    required this.warehouseId,
    required this.itemId,
    required this.quantity,
    required this.relatedPerson,
    this.referenceNumber,
    this.notes,
    this.damageReason,
    DateTime? createdAt,
    this.warehouseName,
    this.warehouseCode,
    this.itemName,
    this.itemUnit,
  }) : createdAt = createdAt ?? DateTime.now();

  /// اسم نوع الحركة بالعربية
  String get typeNameArabic {
    switch (type) {
      case 'receipt':
        return 'سند استلام إنتاج';
      case 'issue':
        return 'سند صرف موزع';
      case 'damage':
        return 'سند إتلاف وهدر';
      default:
        return 'سند مخزني';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'voucher_number': voucherNumber,
      'type': type,
      'warehouse_id': warehouseId,
      'item_id': itemId,
      'quantity': quantity,
      'related_person': relatedPerson,
      'reference_number': referenceNumber,
      'notes': notes,
      'damage_reason': damageReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockTransactionModel.fromMap(Map<String, dynamic> map) {
    return StockTransactionModel(
      id: map['id'] as int?,
      voucherNumber: map['voucher_number'] as String,
      type: map['type'] as String,
      warehouseId: (map['warehouse_id'] as num).toInt(),
      itemId: (map['item_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
      relatedPerson: map['related_person'] as String? ?? '',
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      damageReason: map['damage_reason'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      warehouseName: map['warehouse_name'] as String?,
      warehouseCode: map['warehouse_code'] as String?,
      itemName: map['item_name'] as String?,
      itemUnit: map['item_unit'] as String?,
    );
  }

  StockTransactionModel copyWith({
    int? id,
    String? voucherNumber,
    String? type,
    int? warehouseId,
    int? itemId,
    int? quantity,
    String? relatedPerson,
    String? referenceNumber,
    String? notes,
    String? damageReason,
    DateTime? createdAt,
    String? warehouseName,
    String? warehouseCode,
    String? itemName,
    String? itemUnit,
  }) {
    return StockTransactionModel(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      type: type ?? this.type,
      warehouseId: warehouseId ?? this.warehouseId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      relatedPerson: relatedPerson ?? this.relatedPerson,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      damageReason: damageReason ?? this.damageReason,
      createdAt: createdAt ?? this.createdAt,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      itemName: itemName ?? this.itemName,
      itemUnit: itemUnit ?? this.itemUnit,
    );
  }
}
