import 'api_service.dart';
import '../models/ride_model.dart';
import '../models/ride_type.dart';
import 'mock_mode.dart';

class RideService {
  final ApiService _apiService = ApiService();

  static final List<RideModel> _mockPendingRides = [
    RideModel(
      id: 'mock-pending-1',
      passengerId: 'p1',
      passengerName: 'John Doe',
      fromLocation: 'Library',
      toLocation: 'Dorm A',
      fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
      status: RideStatus.pending,
      type: RideType.solo,
      createdAt: DateTime.now(),
    ),
    RideModel(
      id: 'mock-pending-2',
      passengerId: 'p2',
      passengerName: 'Jane Smith',
      fromLocation: 'Gym',
      toLocation: 'Science Hall',
      fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
      status: RideStatus.pending,
      type: RideType.solo,
      createdAt: DateTime.now(),
    ),
  ];

  Future<RideModel> requestRide(
    String from,
    String to,
    double fromLat,
    double fromLng,
    double toLat,
    double toLng, {
    DateTime? scheduledTime,
    String? genderPreference,
  }) async {
    if (kMockMode) {
      final newRide = RideModel(
        id: 'mock-ride-${DateTime.now().millisecondsSinceEpoch}',
        passengerId: 'mock-user-123',
        passengerName: 'Mock Student',
        fromLocation: from,
        toLocation: to,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        status: RideStatus.pending,
        type: RideType.solo,
        createdAt: DateTime.now(),
        scheduledTime: scheduledTime,
        genderPreference: genderPreference,
      );
      _mockPendingRides.add(newRide);
      return newRide;
    }

    final response = await _apiService.post('/rides/request', {
      'fromLocation': from,
      'toLocation': to,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'scheduledTime': scheduledTime?.toIso8601String(),
      if (genderPreference != null) 'gender_preference': genderPreference,
    });
    
    if (response is Map && response['ride'] != null && response['ride'] is Map) {
      return RideModel.fromJson(response['ride'] as Map<String, dynamic>);
    }

    return RideModel(
      id: (response['ride_id'] ?? '').toString(),
      passengerId: '', 
      passengerName: '',
      fromLocation: from,
      toLocation: to,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      genderPreference: genderPreference,
      status: RideStatus.values.firstWhere(
        (e) => e.name == (response['status'] == 'in_progress' ? 'inProgress' : response['status'] ?? 'pending'), 
        orElse: () => RideStatus.pending
      ),
      type: RideType.solo,
      createdAt: DateTime.now(),
    );
  }

  Future<List<RideModel>> getPendingRides() async {
    if (kMockMode) {
      return List.from(_mockPendingRides);
    }

    final dynamic response = await _apiService.get('/rides/pending');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['rides'] != null) {
      list = response['rides'] as List;
    } else {
      list = [];
    }
    return list.map((e) => RideModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RideModel>> getCommunityRides() async {
    if (kMockMode) {
      return List.from(_mockPendingRides);
    }

    final dynamic response = await _apiService.get('/rides/community');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['community_rides'] != null) {
      list = response['community_rides'] as List;
    } else if (response is Map && response['rides'] != null) {
      list = response['rides'] as List;
    } else {
      list = [];
    }
    return list.map((e) => RideModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RideModel> acceptRide(String rideId) async {
    if (kMockMode) {
      // Return a modified version of a mock ride
      return RideModel(
        id: rideId,
        passengerId: 'p1',
        passengerName: 'John Doe',
        fromLocation: 'Library',
        toLocation: 'Dorm A',
        fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
        status: RideStatus.accepted,
        type: RideType.solo,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );
    }

    final response = await _apiService.post('/rides/$rideId/accept', {});
    return RideModel.fromJson(response);
  }

  Future<void> declineRide(String rideId) async {
    if (kMockMode) return;
    await _apiService.post('/rides/$rideId/decline', {});
  }

  Future<RideModel> startRide(String rideId) async {
    if (kMockMode) {
       return RideModel(
        id: rideId,
        passengerId: 'p1',
        passengerName: 'John Doe',
        fromLocation: 'Library',
        toLocation: 'Dorm A',
        fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
        status: RideStatus.inProgress,
        type: RideType.solo,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );
    }
    final response = await _apiService.post('/rides/$rideId/start', {});
    return RideModel.fromJson(response);
  }

  Future<RideModel> completeRide(String rideId) async {
    if (kMockMode) {
       return RideModel(
        id: rideId,
        passengerId: 'p1',
        passengerName: 'John Doe',
        fromLocation: 'Library',
        toLocation: 'Dorm A',
        fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
        status: RideStatus.completed,
        type: RideType.solo,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
    }
    final response = await _apiService.post('/rides/$rideId/complete', {});
    return RideModel.fromJson(response);
  }

  Future<void> cancelRide(String rideId) async {
    if (kMockMode) return;
    await _apiService.post('/rides/$rideId/cancel', {});
  }

  Future<List<RideModel>> getRideHistory({String? role}) async {
    if (kMockMode) {
      return [
        RideModel(
          id: 'mock-hist-1',
          passengerId: 'p1',
          passengerName: 'Mock Student',
          riderId: 'r1',
          riderName: 'Tejas Jadhao',
          fromLocation: 'VIT Gate 1',
          toLocation: 'Pune Station',
          fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
          status: RideStatus.completed,
          type: RideType.solo,
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          pointsAwarded: 10,
        ),
        RideModel(
          id: 'mock-hist-2',
          passengerId: 'p1',
          passengerName: 'Mock Student',
          riderId: 'r2',
          riderName: 'Aditya Jadhav',
          fromLocation: 'Hostel Block C',
          toLocation: 'Deccan Gymkhana',
          fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
          status: RideStatus.completed,
          type: RideType.solo,
          createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
          pointsAwarded: 10,
        ),
      ];
    }
    final String endpoint = role != null ? '/rides/history?role=$role' : '/rides/history';
    final dynamic response = await _apiService.get(endpoint);
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['rides'] != null) {
      list = response['rides'] as List;
    } else if (response is Map && response['data'] != null) {
      list = response['data'] as List;
    } else {
      list = [];
    }
    return list.map((e) => RideModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RideModel>> getUpcomingRides({String? role}) async {
    if (kMockMode) {
      return [];
    }
    final String endpoint = role != null ? '/rides/upcoming?role=$role' : '/rides/upcoming';
    final dynamic response = await _apiService.get(endpoint);
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['rides'] != null) {
      list = response['rides'] as List;
    } else if (response is Map && response['data'] != null) {
      list = response['data'] as List;
    } else {
      list = [];
    }
    return list.map((e) => RideModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RideModel?> getActiveRide() async {
    if (kMockMode) {
      return RideModel(
        id: 'mock-active-1',
        passengerId: 'p1',
        passengerName: 'John Doe',
        fromLocation: 'Library',
        toLocation: 'Dorm A',
        fromLat: 0, fromLng: 0, toLat: 0, toLng: 0,
        status: RideStatus.accepted,
        type: RideType.solo,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );
    }
    final response = await _apiService.get('/rides/active');
    return response != null ? RideModel.fromJson(response) : null;
  }

  Future<List<Map<String, dynamic>>> getNearbyDrivers({
    double? lat,
    double? lng,
    double? radius,
    String? gender,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();
      if (radius != null) queryParams['radius'] = radius.toString();
      if (gender != null && gender.isNotEmpty && gender.toLowerCase() != 'all') {
        queryParams['gender'] = gender;
      }
      
      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final path = '/rides/nearby-drivers${queryString.isNotEmpty ? '?$queryString' : ''}';
      
      final dynamic response = await _apiService.get(path);
      if (response is Map && response['drivers'] is List) {
        return List<Map<String, dynamic>>.from(response['drivers'] as List);
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }
}
