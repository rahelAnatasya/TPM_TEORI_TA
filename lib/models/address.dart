class Address {
  int? id; // SQLite primary key
  String? userEmail; // Associate with user
  String name;
  String fullAddress;
  double latitude;
  double longitude;
  bool isDefault;
  DateTime? createdAt;
  DateTime? updatedAt;

  Address({
    this.id,
    this.userEmail,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      userEmail: json['user_email'],
      name: json['name'] ?? '',
      fullAddress: json['full_address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'name': name,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // SQLite methods
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'],
      userEmail: map['user_email'],
      name: map['name'],
      fullAddress: map['full_address'],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      isDefault: map['is_default'] == 1,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'name': name,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Address copyWith({
    int? id,
    String? userEmail,
    String? name,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
