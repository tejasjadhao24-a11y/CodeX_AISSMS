class RiderModel {
  final String id;
  final String name;
  final String vehicleType;
  final String vehicleNumber;
  final bool isAvailable;

  RiderModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.vehicleNumber,
    this.isAvailable = false,
  });

  RiderModel copyWith({
    String? id,
    String? name,
    String? vehicleType,
    String? vehicleNumber,
    bool? isAvailable,
  }) {
    return RiderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
