class BikeModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerUpiId;
  final String bikeType;
  final String bikeName;
  final String bikeNumber;
  final double pricePerHour;
  final String location;
  final String? description;
  final String paymentMethod;
  final bool isAvailable;
  final DateTime createdAt;

  BikeModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerUpiId,
    required this.bikeType,
    required this.bikeName,
    required this.bikeNumber,
    required this.pricePerHour,
    required this.location,
    this.description,
    this.paymentMethod = 'Both',
    required this.isAvailable,
    required this.createdAt,
  });

  factory BikeModel.fromJson(Map<String, dynamic> json) {
    return BikeModel(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      ownerName: json['owner_name'] ?? 'Owner',
      ownerUpiId: json['owner_upi_id'] ?? '',
      bikeType: json['bike_type'] ?? 'bicycle',
      bikeName: json['bike_name'] ?? 'Bike',
      bikeNumber: json['bike_number'] ?? 'N/A',
      pricePerHour: (json['price_per_hour'] as num?)?.toDouble() ?? 20.0,
      location: json['location'] ?? 'Campus',
      description: json['description'],
      paymentMethod: json['payment_method'] ?? 'Both',
      isAvailable: json['is_available'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_upi_id': ownerUpiId,
      'bike_type': bikeType,
      'bike_name': bikeName,
      'bike_number': bikeNumber,
      'price_per_hour': pricePerHour,
      'location': location,
      'description': description,
      'payment_method': paymentMethod,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BikeModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerUpiId,
    String? bikeType,
    String? bikeName,
    String? bikeNumber,
    double? pricePerHour,
    String? location,
    String? description,
    String? paymentMethod,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return BikeModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerUpiId: ownerUpiId ?? this.ownerUpiId,
      bikeType: bikeType ?? this.bikeType,
      bikeName: bikeName ?? this.bikeName,
      bikeNumber: bikeNumber ?? this.bikeNumber,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      location: location ?? this.location,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
