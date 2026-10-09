import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';
import 'mock_mode.dart';

class SocketService {
  io.Socket? _socket;
  io.Socket? get socket => _socket;

  void connect(String token) {
    if (kMockMode) return;

    _socket = io.io(ApiService.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'token': token},
    });

    _socket?.connect();

    _socket?.onConnect((_) => debugPrint('Connected to SocketIO'));
    _socket?.onDisconnect((_) => debugPrint('Disconnected from SocketIO'));
  }

  void joinUserRoom(String userId) {
    if (kMockMode) return;
    _socket?.emit('join_user_room', {'user_id': userId});
  }

  void joinRideRoom(String rideId) {
    if (kMockMode) return;
    _socket?.emit('join_ride_room', {'ride_id': rideId});
  }

  void leaveRideRoom(String rideId) {
    if (kMockMode) return;
    _socket?.emit('leave_ride_room', {'ride_id': rideId});
  }

  void joinRidersRoom() {
    if (kMockMode) return;
    _socket?.emit('rider_online');
  }

  void setRiderOnline() {
    if (kMockMode) return;
    _socket?.emit('rider_online', {});
  }

  void leaveRidersRoom() {
    if (kMockMode) return;
    _socket?.emit('rider_offline');
  }

  void joinAdminRoom(String token) {
    if (kMockMode) return;
    _socket?.emit('join_admin_room', {'token': token});
  }

  void leaveAdminRoom() {
    if (kMockMode) return;
    _socket?.emit('leave_admin_room');
  }

  void onSosTriggered(Function(dynamic) callback) {
    _on('sos_triggered', callback);
  }

  void emit(String event, [dynamic data]) {
    if (kMockMode) return;
    _socket?.emit(event, data);
  }

  // Rider sends location
  void sendLocationUpdate({
    required String rideId,
    required double lat,
    required double lng,
  }) {
    if (kMockMode) {
      // Simulate by calling onLocationUpdate callbacks
      _listeners['location_update']?.forEach((cb) {
        cb({'lat': lat, 'lng': lng, 'ride_id': rideId});
      });
      return;
    }
    _socket?.emit('update_location', {
      'ride_id': rideId,
      'lat': lat,
      'lng': lng,
    });
  }

  // Map to store multiple listeners for each event
  final Map<String, List<Function(dynamic)>> _listeners = {};

  void _on(String event, Function(dynamic) callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
      _socket?.on(event, (data) {
        for (var cb in List.from(_listeners[event]!)) {
          cb(data);
        }
      });
    }
    _listeners[event]!.add(callback);
  }

  void _off(String event, [Function(dynamic)? callback]) {
    if (callback == null) {
      _listeners[event]?.clear();
      _socket?.off(event);
    } else {
      _listeners[event]?.remove(callback);
      if (_listeners[event]?.isEmpty ?? true) {
        _socket?.off(event);
      }
    }
  }

  void onEvent(String event, Function(dynamic) callback) => _on(event, callback);
  void offEvent(String event, [Function(dynamic)? callback]) => _off(event, callback);

  void onLocationUpdate(Function(dynamic) callback) => _on('location_update', callback);
  void offLocationUpdate(Function(dynamic) callback) => _off('location_update', callback);
  void clearLocationListeners() => _off('location_update');

  void onNewRideRequest(Function(dynamic) callback) => _on('new_ride_request', callback);
  
  void onRideAccepted(Function(Map<String, dynamic>) callback) {
    _on('ride_accepted', (data) => callback(data as Map<String, dynamic>));
  }

  void onRideStarted(Function(Map<String, dynamic>) callback) {
    _on('ride_started', (data) => callback(data as Map<String, dynamic>));
  }

  void onRideCompleted(Function(Map<String, dynamic>) callback) {
    _on('ride_completed', (data) => callback(data as Map<String, dynamic>));
  }
  
  void onRideCancelled(Function(Map<String, dynamic>) callback) {
    _on('ride_cancelled', (data) => callback(data as Map<String, dynamic>));
  }

  void onSosLocationUpdate(Function(Map<String, dynamic>) callback) {
    _on('sos_location_update', (data) => callback(data is Map ? Map<String, dynamic>.from(data) : {}));
  }

  void onSosResolved(Function(Map<String, dynamic>) callback) {
    _on('sos_resolved', (data) => callback(data is Map ? Map<String, dynamic>.from(data) : {}));
  }

  void clearAllListeners() {
    _listeners.clear();
    // Also tell the native socket to clear its internal listeners for these events
    final events = [
      'new_ride_request', 
      'ride_accepted', 
      'ride_started', 
      'ride_completed', 
      'ride_cancelled', 
      'location_update'
    ];
    for (var event in events) {
      _socket?.off(event);
    }
    debugPrint('[SocketService] All listeners cleared');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _listeners.clear();
  }

  // Mock helpers
  void simulateNewRideRequest(Map<String, dynamic> data) {
    _listeners['new_ride_request']?.forEach((cb) => cb(data));
  }

  void simulateRideAccepted(Map<String, dynamic> data) {
    _listeners['ride_accepted']?.forEach((cb) => cb(data));
  }

  void simulateRideStarted(Map<String, dynamic> data) {
    _listeners['ride_started']?.forEach((cb) => cb(data));
  }

  void simulateRideCompleted(Map<String, dynamic> data) {
    _listeners['ride_completed']?.forEach((cb) => cb(data));
  }
}
