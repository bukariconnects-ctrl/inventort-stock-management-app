/// نموذج بيانات المستودع / المخزن
class WarehouseModel {
  final int? id;
  final String name;
  final String? location;
  final int capacityBoxes;
  final bool isActive;
  final DateTime createdAt;

  WarehouseModel({
    this.id,
    required this.name,
    this.location,
    this.capacityBoxes = 5000,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'location': location,
      'capacity_boxes': capacityBoxes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String?,
      capacityBoxes: (map['capacity_boxes'] as num?)?.toInt() ?? 5000,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  WarehouseModel copyWith({
    int? id,
    String? name,
    String? location,
    int? capacityBoxes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacityBoxes: capacityBoxes ?? this.capacityBoxes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

