/// نموذج بيانات المستودع / المخزن
class WarehouseModel {
  final int? id;
  final String name;
  final String? location;
  final String code;
  final int minAlertThreshold;
  final DateTime createdAt;

  WarehouseModel({
    this.id,
    required this.name,
    this.location,
    required this.code,
    this.minAlertThreshold = 100,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'location': location,
      'code': code,
      'min_alert_threshold': minAlertThreshold,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String?,
      code: map['code'] as String,
      minAlertThreshold: (map['min_alert_threshold'] as num?)?.toInt() ?? 100,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  WarehouseModel copyWith({
    int? id,
    String? name,
    String? location,
    String? code,
    int? minAlertThreshold,
    DateTime? createdAt,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      code: code ?? this.code,
      minAlertThreshold: minAlertThreshold ?? this.minAlertThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
