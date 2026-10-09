class UserModel {
  final String id;
  final String name;
  final String email;
  final String? role;
  final int points;
  final bool licenseVerified;
  final bool isOnline;
  final bool acceptedGuidelines;
  final String? collegeName;
  final String? serviceArea;
  final String? prn;
  final String? vehicleType;
  final String? vehicleName;
  final String? vehicleNumber;
  final String? course;
  final String? yearOfStudy;
  final String? phoneNumber;
  final String? drivingLicense;
  final String? phone;
  final String? dob;
  final String? gender;
  final String? branch;
  final String? division;
  final String? licenseNumber;
  final String? licenseType;
  final String? licenseExpiry;
  final String? vehicleRcNumber;
  final String? verificationStatus;
  final String? verificationNote;
  final String? avatarUrl;
  final String? licensePhoto;
  final String? rcPhoto;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.points = 0,
    this.licenseVerified = false,
    this.isOnline = false,
    this.acceptedGuidelines = false,
    this.collegeName,
    this.serviceArea,
    this.prn,
    this.vehicleType,
    this.vehicleName,
    this.vehicleNumber,
    this.course,
    this.yearOfStudy,
    this.phoneNumber,
    this.drivingLicense,
    this.phone,
    this.dob,
    this.gender,
    this.branch,
    this.division,
    this.licenseNumber,
    this.licenseType,
    this.licenseExpiry,
    this.vehicleRcNumber,
    this.verificationStatus = 'unverified',
    this.verificationNote,
    this.avatarUrl,
    this.licensePhoto,
    this.rcPhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      points: json['points'] ?? 0,
      licenseVerified: json['license_verified'] ?? json['licenseVerified'] ?? false,
      isOnline: json['is_online'] ?? false,
      acceptedGuidelines: json['accepted_guidelines'] ?? false,
      collegeName: json['college_name'] ?? json['collegeName'],
      serviceArea: json['service_area'] ?? json['serviceArea'],
      prn: json['prn'],
      vehicleType: json['vehicle_type'] ?? json['vehicleType'],
      vehicleName: json['vehicle_name'] ?? json['vehicleName'],
      vehicleNumber: json['vehicle_number'] ?? json['vehicleNumber'],
      course: json['course'],
      yearOfStudy: json['year_of_study'] ?? json['yearOfStudy'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      drivingLicense: json['driving_license'],
      phone: json['phone'] ?? json['phone_number'],
      dob: json['dob'],
      gender: json['gender'],
      branch: json['branch'],
      division: json['division'],
      licenseNumber: json['licenseNumber'] ?? json['license_number'],
      licenseType: json['licenseType'] ?? json['license_type'],
      licenseExpiry: json['licenseExpiry'] ?? json['license_expiry'],
      vehicleRcNumber: json['vehicleRcNumber'] ?? json['vehicle_rc_number'],
      verificationStatus: json['verificationStatus'] ?? json['verification_status'] ?? 'unverified',
      verificationNote: json['verificationNote'] ?? json['verification_note'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      licensePhoto: json['license_photo'] ?? json['licensePhoto'],
      rcPhoto: json['rc_photo'] ?? json['rcPhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'points': points,
      'license_verified': licenseVerified,
      'licenseVerified': licenseVerified,
      'is_online': isOnline,
      'accepted_guidelines': acceptedGuidelines,
      'college_name': collegeName,
      'collegeName': collegeName,
      'service_area': serviceArea,
      'serviceArea': serviceArea,
      'prn': prn,
      'vehicle_type': vehicleType,
      'vehicleType': vehicleType,
      'vehicle_name': vehicleName,
      'vehicleName': vehicleName,
      'vehicle_number': vehicleNumber,
      'vehicleNumber': vehicleNumber,
      'course': course,
      'year_of_study': yearOfStudy,
      'yearOfStudy': yearOfStudy,
      'phone_number': phoneNumber,
      'driving_license': drivingLicense,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'branch': branch,
      'division': division,
      'licenseNumber': licenseNumber,
      'license_number': licenseNumber,
      'licenseType': licenseType,
      'license_type': licenseType,
      'licenseExpiry': licenseExpiry,
      'license_expiry': licenseExpiry,
      'vehicleRcNumber': vehicleRcNumber,
      'vehicle_rc_number': vehicleRcNumber,
      'verificationStatus': verificationStatus,
      'verification_status': verificationStatus,
      'verificationNote': verificationNote,
      'verification_note': verificationNote,
      'avatarUrl': avatarUrl,
      'avatar_url': avatarUrl,
      'licensePhoto': licensePhoto,
      'license_photo': licensePhoto,
      'rcPhoto': rcPhoto,
      'rc_photo': rcPhoto,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    int? points,
    bool? licenseVerified,
    bool? isOnline,
    bool? acceptedGuidelines,
    String? collegeName,
    String? serviceArea,
    String? prn,
    String? vehicleType,
    String? vehicleName,
    String? vehicleNumber,
    String? course,
    String? yearOfStudy,
    String? phoneNumber,
    String? drivingLicense,
    String? phone,
    String? dob,
    String? gender,
    String? branch,
    String? division,
    String? licenseNumber,
    String? licenseType,
    String? licenseExpiry,
    String? vehicleRcNumber,
    String? verificationStatus,
    String? verificationNote,
    String? avatarUrl,
    bool clearAvatar = false,
    String? licensePhoto,
    String? rcPhoto,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      points: points ?? this.points,
      licenseVerified: licenseVerified ?? this.licenseVerified,
      isOnline: isOnline ?? this.isOnline,
      acceptedGuidelines: acceptedGuidelines ?? this.acceptedGuidelines,
      collegeName: collegeName ?? this.collegeName,
      serviceArea: serviceArea ?? this.serviceArea,
      prn: prn ?? this.prn,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      course: course ?? this.course,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      branch: branch ?? this.branch,
      division: division ?? this.division,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseType: licenseType ?? this.licenseType,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      vehicleRcNumber: vehicleRcNumber ?? this.vehicleRcNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNote: verificationNote ?? this.verificationNote,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      licensePhoto: licensePhoto ?? this.licensePhoto,
      rcPhoto: rcPhoto ?? this.rcPhoto,
    );
  }
}


