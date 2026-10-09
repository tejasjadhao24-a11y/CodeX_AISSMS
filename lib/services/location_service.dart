import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';

class LocationService {
  Timer? _locationTimer;
  
  // Get current position once
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Start sending location every 3 seconds
  void startSendingLocation({
    required String rideId,
    required SocketService socketService,
  }) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        final position = await getCurrentPosition();
        if (position != null) {
          socketService.sendLocationUpdate(
            rideId: rideId,
            lat: position.latitude,
            lng: position.longitude,
          );
        }
      }
    );
  }
  
  // Stop sending location
  void stopSendingLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
  
  // Mock location for Chrome testing
  // VIT Pune coordinates
  Position getMockPosition() {
    return Position(
      latitude: 18.4624,
      longitude: 73.8670,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
  
  // Simulate moving location for mock
  double _mockLat = 18.4624;
  double _mockLng = 73.8670;
  
  void startMockSendingLocation({
    required String rideId,
    required SocketService socketService,
  }) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        // Simulate small movement
        _mockLat += 0.0001;
        _mockLng += 0.0001;
        socketService.sendLocationUpdate(
          rideId: rideId,
          lat: _mockLat,
          lng: _mockLng,
        );
      }
    );
  }
}
