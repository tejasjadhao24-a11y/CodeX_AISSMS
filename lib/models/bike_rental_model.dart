class BikeRentalModel {
  final String id;
  final String bikeId;
  final String renterId;
  final String renterName;
  final String ownerId;
  final String bikeName;
  final String bikeType;
  final String ownerUpiId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalHours;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  BikeRentalModel({
    required this.id,
    required this.bikeId,
    required this.renterId,
    required this.renterName,
    required this.ownerId,
    required this.bikeName,
    required this.bikeType,
    required this.ownerUpiId,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.totalAmount,
    this.paymentMethod = 'UPI',
    required this.status,
    required this.createdAt,
  });

  factory BikeRentalModel.fromJson(Map<String, dynamic> json) {
    return BikeRentalModel(
      id: json['id'] ?? '',
      bikeId: json['bike_id'] ?? '',
      renterId: json['renter_id'] ?? '',
      renterName: json['renter_name'] ?? 'Student',
      ownerId: json['owner_id'] ?? '',
      bikeName: json['bike_name'] ?? 'Bike',
      bikeType: json['bike_type'] ?? 'bicycle',
      ownerUpiId: json['owner_upi_id'] ?? '',
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time']) ?? DateTime.now() : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) ?? DateTime.now() : DateTime.now(),
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 1.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'UPI',
      status: json['status'] ?? 'requested',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bike_id': bikeId,
      'renter_id': renterId,
      'renter_name': renterName,
      'owner_id': ownerId,
      'bike_name': bikeName,
      'bike_type': bikeType,
      'owner_upi_id': ownerUpiId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_hours': totalHours,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'requested':
        return 'Pending Approval';
      case 'approved':
        return 'Approved - Pay Now';
      case 'payment_pending':
        return 'Awaiting Payment';
      case 'payment_done':
        return 'Payment Received';
      case 'active':
        return 'Active Rental';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
