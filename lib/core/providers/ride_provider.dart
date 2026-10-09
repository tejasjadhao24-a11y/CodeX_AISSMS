import 'dart:async';
import 'package:flutter/material.dart';
import 'user_provider.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../../services/mock_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RideState {
  idle,
  requesting,
  waiting,
  accepted,
  inProgress,
  completed,
  cancelled,
  error
}

class RideProvider extends ChangeNotifier {
  final RideService _rideService = RideService();
  final ApiService _apiService = ApiService();
  final SocketService _socketService;
  
  // State variables
  RideState _state = RideState.idle;
  RideModel? _activeRide;
  RideModel? _lastCompletedRide;
  String? _lastCompletedRideId;
  List<RideModel> _pendingRides = [];
  List<RideModel> _communityRides = [];
  List<RideModel> _rideHistory = [];
  List<RideModel> _upcomingRides = [];
  bool _isLoading = false;
  bool _isCommunityLoading = false;
  String? _errorMessage;
  String? _communityError;
  bool _isTestMode = false;
  
  // Getters
  RideState get state => _state;
  RideState get rideState => _state; // For backward compatibility
  RideModel? get activeRide => _activeRide;
  RideModel? get lastCompletedRide => _lastCompletedRide;
  String? get lastCompletedRideId => _lastCompletedRideId;
  List<RideModel> get pendingRides => _pendingRides;
  List<RideModel> get communityRides => _communityRides;
  List<RideModel> get rideHistory => _rideHistory;
  List<RideModel> get upcomingRides => _upcomingRides;
  bool get isLoading => _isLoading;
  bool get isCommunityLoading => _isCommunityLoading;
  String? get errorMessage => _errorMessage;
  String? get communityError => _communityError;

  RideProvider(this._socketService) {
    _init();
  }

  Future<void> _init() async {
    await syncWithServer();
  }


  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- CORE LOGIC ---

  Future<void> syncWithServer() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // 1. Recover last completed ride if any
      final prefs = await SharedPreferences.getInstance();
      _lastCompletedRideId = prefs.getString('last_completed_ride_id');
      
      if (_lastCompletedRideId != null && _lastCompletedRide == null) {
        try {
          final res = await _apiService.get('/rides/$_lastCompletedRideId');
          final data = res is Map && res.containsKey('data') ? res['data'] : res;
          if (data != null) {
            _lastCompletedRide = RideModel.fromJson(data as Map<String, dynamic>);
            if (_lastCompletedRide?.status == RideStatus.completed) {
              _state = RideState.completed;
            }
          }
        } catch (e) {
          debugPrint('Failed to recover last ride: $e');
        }
      }

      // 2. Fetch truly active ride
      if (!kMockMode) {
        final response = await _apiService.get('/rides/active');
        final rideData = response is Map && response.containsKey('data') ? response['data'] : response;
        
        if (rideData != null && rideData is Map) {
          _activeRide = RideModel.fromJson(rideData as Map<String, dynamic>);
          _updateStateFromRide(_activeRide!);
          _socketService.joinRideRoom(_activeRide!.id);
        } else {
          // No active ride on server.
          // If we had an active ride locally, let's query its status to see if it was completed or cancelled!
          if (_activeRide != null) {
            try {
              final rideId = _activeRide!.id;
              final res = await _apiService.get('/rides/$rideId');
              final data = res is Map && res.containsKey('data') ? res['data'] : res;
              if (data != null) {
                final checkedRide = RideModel.fromJson(data as Map<String, dynamic>);
                if (checkedRide.status == RideStatus.completed) {
                  _lastCompletedRide = checkedRide;
                  _lastCompletedRideId = checkedRide.id;
                  _activeRide = null;
                  _state = RideState.completed;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('last_completed_ride_id', checkedRide.id);
                  notifyListeners();
                  return; // Don't proceed to clear
                } else if (checkedRide.status == RideStatus.cancelled) {
                  _activeRide = null;
                  _state = RideState.cancelled;
                  notifyListeners();
                  return; // Don't proceed to clear
                }
              }
            } catch (e) {
              debugPrint('Error checking active ride status: $e');
            }
          }
          
          if (_state != RideState.completed) {
            _activeRide = null;
            _state = RideState.idle;
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _state = RideState.error;
    } finally {
      _setLoading(false);
    }
  }


  void _updateStateFromRide(RideModel ride) {
    switch (ride.status) {
      case RideStatus.pending:
        _state = RideState.waiting;
        break;
      case RideStatus.accepted:
        _state = RideState.accepted;
        break;
      case RideStatus.inProgress:
        _state = RideState.inProgress;
        break;
      case RideStatus.completed:
        _state = RideState.completed;
        break;
      case RideStatus.cancelled:
        _state = RideState.cancelled;
        break;
    }
  }

  void listenToSocketEvents(UserProvider userProvider) {
    _socketService.clearAllListeners();

    _socketService.onNewRideRequest((data) {
      final newRide = RideModel.fromJson(data);
      if (newRide.passengerId != userProvider.currentUser?.id) {
        if (!_pendingRides.any((r) => r.id == newRide.id)) {
          _pendingRides.insert(0, newRide);
          notifyListeners();
        }
      }
    });

    _socketService.onRideAccepted((data) {
      final ride = RideModel.fromJson(data);
      final currentUserId = userProvider.currentUser?.id;
      
      if (ride.passengerId == currentUserId || ride.riderId == currentUserId) {
        _activeRide = ride;
        _state = RideState.accepted;
        _socketService.joinRideRoom(ride.id);
        notifyListeners();
      }
      
      _pendingRides.removeWhere((r) => r.id == ride.id);
      notifyListeners();
    });

    _socketService.onRideStarted((data) {
      final ride = RideModel.fromJson(data);
      final currentUserId = userProvider.currentUser?.id;
      if (ride.passengerId == currentUserId || ride.riderId == currentUserId) {
        _activeRide = ride;
        _state = RideState.inProgress;
        notifyListeners();
      }
    });

    _socketService.onRideCompleted((data) async {
      final ride = RideModel.fromJson(data);
      final currentUserId = userProvider.currentUser?.id;
      if (ride.passengerId == currentUserId || ride.riderId == currentUserId) {
        _lastCompletedRide = ride;
        _lastCompletedRideId = ride.id;
        _activeRide = null;
        _state = RideState.completed;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_completed_ride_id', ride.id);
        
        userProvider.loadUser();
        notifyListeners();
      }
    });

    _socketService.onRideCancelled((data) {
      final rideId = data['id'];
      if (_activeRide != null && _activeRide!.id == rideId) {
        _activeRide = null;
        _state = RideState.cancelled;
        notifyListeners();
      }
      _pendingRides.removeWhere((r) => r.id == rideId);
      notifyListeners();
    });

    _socketService.onLocationUpdate((data) {
      if (_activeRide != null && (data['ride_id'] == _activeRide!.id || data['rideId'] == _activeRide!.id)) {
        final lat = (data['latitude'] ?? data['lat'] as num?)?.toDouble();
        final lng = (data['longitude'] ?? data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _activeRide = _activeRide!.copyWith(
            currentLat: lat,
            currentLng: lng,
          );
          notifyListeners();
        }
      }
    });
  }

  // --- ACTIONS ---

  Future<bool> requestRide({
    required String fromLocation, 
    required String toLocation, 
    double? fromLat, 
    double? fromLng, 
    double? toLat, 
    double? toLng,
    DateTime? scheduledTime,
    UserProvider? userProvider,
    String? genderPreference,
  }) async {
    // Clear any previous ride completion state
    _lastCompletedRide = null;
    _lastCompletedRideId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_completed_ride_id');
    } catch (e) {
      debugPrint('Error clearing completed ride prefs: $e');
    }

    _setLoading(true);
    _state = RideState.requesting;
    try {
      final result = await _rideService.requestRide(
        fromLocation,
        toLocation,
        fromLat ?? 18.4624,
        fromLng ?? 73.8670,
        toLat ?? 18.4700,
        toLng ?? 73.8750,
        scheduledTime: scheduledTime,
        genderPreference: genderPreference,
      );
      
      _activeRide = result;
      _state = RideState.waiting;
      _socketService.joinRideRoom(result.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = RideState.idle;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptRide(String rideId) async {
    // Clear any previous ride completion state
    _lastCompletedRide = null;
    _lastCompletedRideId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_completed_ride_id');
    } catch (e) {
      debugPrint('Error clearing completed ride prefs: $e');
    }

    _setLoading(true);
    try {
      final response = await _apiService.post('/rides/$rideId/accept', {});
      final rideData = response['ride'] ?? response;
      _activeRide = RideModel.fromJson(rideData);
      _state = RideState.accepted;
      _socketService.joinRideRoom(_activeRide!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> startRide(String rideId) async {
    try {
      final response = await _apiService.post('/rides/$rideId/start', {});
      final rideData = response is Map && response.containsKey('ride') ? response['ride'] : response;
      if (rideData != null && rideData is Map) {
        _activeRide = RideModel.fromJson(rideData as Map<String, dynamic>);
      } else if (_activeRide != null) {
        _activeRide = _activeRide!.copyWith(status: RideStatus.inProgress);
      }
      _state = RideState.inProgress;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> completeRide(String rideId, [UserProvider? userProvider]) async {
    try {
      final response = await _apiService.post('/rides/$rideId/complete', {});
      
      final rideData = response is Map && response.containsKey('ride') ? response['ride'] : response;
      if (rideData != null && rideData is Map) {
        final completedRide = RideModel.fromJson(rideData as Map<String, dynamic>);
        _lastCompletedRide = completedRide;
        _lastCompletedRideId = completedRide.id;
        _activeRide = null;
        _state = RideState.completed;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_completed_ride_id', completedRide.id);
        
        if (userProvider != null) {
          await userProvider.loadUser();
        }
        notifyListeners();
      } else {
        await syncWithServer();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> rateRide(String rideId, int rating, [UserProvider? userProvider]) async {
    if (kMockMode || _isTestMode) return;
    try {
      await _apiService.post('/rides/$rideId/rate', {'rating': rating});
      if (userProvider != null && (userProvider.currentUser?.role ?? '').isNotEmpty) {
        await userProvider.loadUser();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error rating ride: $e');
    }
  }

  Future<void> resetForNewRide() async {
    _activeRide = null;
    _lastCompletedRide = null;
    _lastCompletedRideId = null;
    _state = RideState.idle;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_completed_ride_id');
    } catch (e) {
      debugPrint('Error removing completed ride id: $e');
    }
  }

  void clearActiveRide() {
    _activeRide = null;
    notifyListeners();
  }

  Future<void> fetchPendingRides() async {
    try {
      final response = await _apiService.get('/rides/pending');
      final ridesJson = response['rides'] as List?;
      if (ridesJson != null) {
        _pendingRides = ridesJson.map((r) => RideModel.fromJson(r)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching pending rides: $e');
    }
  }

  Future<void> fetchCommunityRides() async {
    _isCommunityLoading = true;
    _communityError = null;
    notifyListeners();

    try {
      final rides = await _rideService.getCommunityRides();
      _communityRides = rides;
    } catch (e) {
      _communityError = e.toString();
      debugPrint('Error fetching community rides: $e');
    } finally {
      _isCommunityLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingRides({String? role}) async {
    try {
      _upcomingRides = await _rideService.getUpcomingRides(role: role);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching upcoming rides: $e');
    }
  }

  Future<void> fetchActiveRide() async {
    await syncWithServer();
  }

  Future<void> loadLastCompletedRide() async {
    await syncWithServer();
  }

  Future<void> declineRide(String rideId) async {
    try {
      await _apiService.post('/rides/$rideId/decline', {});
      _pendingRides.removeWhere((r) => r.id == rideId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  void updateLocation(String rideId, double lat, double lng) {
    _socketService.sendLocationUpdate(rideId: rideId, lat: lat, lng: lng);
  }

  Future<void> cancelRide(String rideId) async {
    try {
      await _apiService.post('/rides/$rideId/cancel', {});
      _activeRide = null;
      _state = RideState.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> fetchHistory({String? role}) async {
    _setLoading(true);
    try {
      _rideHistory = await _rideService.getRideHistory(role: role);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setCompletedRideForTesting(RideModel ride) {
    _isTestMode = true;
    _lastCompletedRide = ride;
    notifyListeners();
  }
}
