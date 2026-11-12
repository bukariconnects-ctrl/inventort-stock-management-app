/// نموذج بيانات الصنف المخزني (كرتون مياه رواء)
class ItemModel {
  final int? id;
  final String name;
  final String specification;
  final String unit;
  final int defaultMinThreshold;
  final DateTime createdAt;

  ItemModel({
    this.id,
    required this.name,
    required this.specification,
    this.unit = 'كرتون',
    this.defaultMinThreshold = 100,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'specification': specification,
      'unit': unit,
      'default_min_threshold': defaultMinThreshold,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      specification: map['specification'] as String? ?? '20 قنينة × 750 مل',
      unit: map['unit'] as String? ?? 'كرتون',
      defaultMinThreshold:
          (map['default_min_threshold'] as num?)?.toInt() ?? 100,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ItemModel copyWith({
    int? id,
    String? name,
    String? specification,
    String? unit,
    int? defaultMinThreshold,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specification: specification ?? this.specification,
      unit: unit ?? this.unit,
      defaultMinThreshold: defaultMinThreshold ?? this.defaultMinThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
