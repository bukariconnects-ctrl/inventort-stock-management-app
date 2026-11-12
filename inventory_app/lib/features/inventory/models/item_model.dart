/// نموذج بيانات الصنف المخزني (كرتون مياه رواء)
class ItemModel {
  final int? id;
  final String name;
  final String unit;
  final int bottlesPerPackage;
  final String bottleVolume;
  final DateTime createdAt;

  ItemModel({
    this.id,
    required this.name,
    this.unit = 'كرتون',
    this.bottlesPerPackage = 20,
    this.bottleVolume = '75 مل',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'unit': unit,
      'bottles_per_package': bottlesPerPackage,
      'bottle_volume': bottleVolume,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String? ?? 'كرتون',
      bottlesPerPackage: (map['bottles_per_package'] as num?)?.toInt() ?? 20,
      bottleVolume: map['bottle_volume'] as String? ?? '75 مل',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ItemModel copyWith({
    int? id,
    String? name,
    String? unit,
    int? bottlesPerPackage,
    String? bottleVolume,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      bottlesPerPackage: bottlesPerPackage ?? this.bottlesPerPackage,
      bottleVolume: bottleVolume ?? this.bottleVolume,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
