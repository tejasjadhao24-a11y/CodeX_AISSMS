import 'ride_type.dart';

enum RideStatus { pending, accepted, inProgress, completed, cancelled }

class RideModel {
  final String id;
  final String passengerId;
  final String passengerName;
  final String? riderId;
  final String? riderName;
  final String fromLocation;
  final String toLocation;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final RideStatus status;
  final RideType type;
  final int pointsAwarded;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? scheduledTime;
  final double? currentLat;
  final double? currentLng;
  final String? vehicleDetails;
  final String? genderPreference;
  final String? passengerPhone;
  final String? passengerPhoto;
  final String? riderPhone;
  final String? riderPhoto;

  RideModel({
    required this.id,
    required this.passengerId,
    String? passengerName,
    this.riderId,
    this.riderName,
    String? fromLocation,
    String? toLocation,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    RideStatus? status,
    RideType? type,
    int? pointsAwarded,
    DateTime? createdAt,
    this.acceptedAt,
    this.completedAt,
    this.scheduledTime,
    this.currentLat,
    this.currentLng,
    this.vehicleDetails,
    this.genderPreference,
    this.passengerPhone,
    this.passengerPhoto,
    this.riderPhone,
    this.riderPhoto,
  }) : passengerName = passengerName ?? 'Passenger',
       fromLocation = fromLocation ?? 'Unknown',
       toLocation = toLocation ?? 'Unknown',
       fromLat = fromLat ?? 18.4624,
       fromLng = fromLng ?? 73.8670,
       toLat = toLat ?? 18.4700,
       toLng = toLng ?? 73.8750,
       status = status ?? RideStatus.pending,
       type = type ?? RideType.solo,
       pointsAwarded = pointsAwarded ?? 10,
       createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == RideStatus.accepted || status == RideStatus.inProgress;

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      passengerId: (json['passengerId'] ?? json['passenger_id'] ?? '').toString(),
      passengerName: (json['passengerName'] ?? json['passenger_name'] ?? 'Passenger').toString(),
      riderId: json['riderId']?.toString() ?? json['rider_id']?.toString(),
      riderName: json['riderName']?.toString() ?? json['rider_name']?.toString(),
      fromLocation: (json['fromLocation'] ?? json['from_location'] ?? 'Unknown').toString(),
      toLocation: (json['toLocation'] ?? json['to_location'] ?? 'Unknown').toString(),
      fromLat: (json['fromLat'] ?? json['from_lat'] ?? 18.4624).toDouble(),
      fromLng: (json['fromLng'] ?? json['from_lng'] ?? 73.8670).toDouble(),
      toLat: (json['toLat'] ?? json['to_lat'] ?? 18.4700).toDouble(),
      toLng: (json['toLng'] ?? json['to_lng'] ?? 73.8750).toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.name == (json['status'] == 'in_progress' ? 'inProgress' : (json['status'] ?? 'pending').toString()),
        orElse: () => RideStatus.pending,
      ),
      type: RideType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'solo').toString(),
        orElse: () => RideType.solo,
      ),
      pointsAwarded: (json['pointsAwarded'] ?? json['points_awarded'] ?? 10).toInt(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
      acceptedAt: (json['acceptedAt'] ?? json['accepted_at']) != null 
          ? DateTime.tryParse((json['acceptedAt'] ?? json['accepted_at']).toString())
          : null,
      completedAt: (json['completedAt'] ?? json['completed_at']) != null 
          ? DateTime.tryParse((json['completedAt'] ?? json['completed_at']).toString())
          : null,
      scheduledTime: (json['scheduledTime'] ?? json['scheduled_time']) != null 
          ? DateTime.tryParse((json['scheduledTime'] ?? json['scheduled_time']).toString())
          : null,
      currentLat: (json['currentLat'] ?? json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] ?? json['current_lng'] as num?)?.toDouble(),
      vehicleDetails: (json['vehicleDetails'] ?? json['vehicle_details'])?.toString(),
      genderPreference: (json['genderPreference'] ?? json['gender_preference'])?.toString(),
      passengerPhone: (json['passengerPhone'] ?? json['passenger_phone'])?.toString(),
      passengerPhoto: (json['passengerPhoto'] ?? json['passenger_photo'])?.toString(),
      riderPhone: (json['riderPhone'] ?? json['rider_phone'])?.toString(),
      riderPhoto: (json['riderPhoto'] ?? json['rider_photo'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'riderId': riderId,
      'riderName': riderName,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'status': status.name,
      'type': type.name,
      'pointsAwarded': pointsAwarded,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'currentLat': currentLat,
      'currentLng': currentLng,
      'vehicleDetails': vehicleDetails,
      'genderPreference': genderPreference,
      'passengerPhone': passengerPhone,
      'passengerPhoto': passengerPhoto,
      'riderPhone': riderPhone,
      'riderPhoto': riderPhoto,
    };
  }

  RideModel copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    String? riderId,
    String? riderName,
    String? fromLocation,
    String? toLocation,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    RideStatus? status,
    RideType? type,
    int? pointsAwarded,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? scheduledTime,
    double? currentLat,
    double? currentLng,
    String? vehicleDetails,
    String? genderPreference,
    String? passengerPhone,
    String? passengerPhoto,
    String? riderPhone,
    String? riderPhoto,
  }) {
    return RideModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      status: status ?? this.status,
      type: type ?? this.type,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      genderPreference: genderPreference ?? this.genderPreference,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerPhoto: passengerPhoto ?? this.passengerPhoto,
      riderPhone: riderPhone ?? this.riderPhone,
      riderPhoto: riderPhoto ?? this.riderPhoto,
    );
  }
}
