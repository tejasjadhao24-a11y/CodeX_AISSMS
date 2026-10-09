import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../models/bike_model.dart';
import '../../models/bike_rental_model.dart';
import '../../services/mock_mode.dart';

class BikeProvider extends ChangeNotifier {
  final SocketService? _socketService;
  final ApiService _apiService = ApiService();
  
  List<BikeModel> _availableBikes = [];
  List<BikeModel> _myBikes = [];
  List<BikeRentalModel> _myRentals = [];
  List<BikeRentalModel> _incomingRentals = [];
  bool _isLoading = false;
  String? _errorMessage;

  BikeProvider([this._socketService]) {
    if (_socketService != null) {
      _initSocketListeners();
    }
  }

  void _initSocketListeners() {
    _socketService?.onEvent('rental_requested', (_) {
      fetchIncomingRentals();
      fetchMyBikes();
    });

    _socketService?.onEvent('rental_approved', (_) {
      fetchMyRentals();
      fetchAvailableBikes();
    });

    _socketService?.onEvent('payment_done', (_) {
      fetchIncomingRentals();
      fetchMyRentals();
    });

    _socketService?.onEvent('rental_active', (_) {
      fetchMyRentals();
      fetchIncomingRentals();
      fetchAvailableBikes();
    });

    _socketService?.onEvent('rental_completed', (_) {
      fetchMyRentals();
      fetchIncomingRentals();
      fetchAvailableBikes();
    });

    _socketService?.onEvent('new_bike_posted', (_) {
      fetchAvailableBikes();
    });
    
    _socketService?.onEvent('rental_cancelled', (_) {
      fetchMyRentals();
      fetchIncomingRentals();
      fetchAvailableBikes();
    });
  }

  List<BikeModel> get availableBikes => _availableBikes;
  List<BikeModel> get myBikes => _myBikes;
  List<BikeRentalModel> get myRentals => _myRentals;
  List<BikeRentalModel> get incomingRentals => _incomingRentals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAvailableBikes() async {
    if (kMockMode) {
      _availableBikes = [
        BikeModel(
          id: 'mock-001',
          ownerName: 'Tejas J',
          bikeName: 'Honda Activa',
          bikeType: 'scooter',
          pricePerHour: 30.0,
          location: 'VIT Hostel Block A',
          isAvailable: true,
          ownerUpiId: 'tejas@upi',
          bikeNumber: 'MH12AB1234',
          ownerId: 'mock-owner-1',
          createdAt: DateTime.now(),
        ),
      ];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/bikes/available');
      if (response is List) {
        _availableBikes = response.map((e) => BikeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching available bikes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyBikes() async {
    if (kMockMode) return;
    try {
      final response = await _apiService.get('/bikes/my-bikes');
      if (response is List) {
        _myBikes = response.map((e) => BikeModel.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching my bikes: $e');
    }
  }

  Future<bool> postBike(Map<String, dynamic> bikeData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/bikes/post', bikeData);
      await fetchMyBikes();
      await fetchAvailableBikes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error posting bike: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAvailability(String bikeId) async {
    try {
      await _apiService.patch('/bikes/$bikeId/toggle-availability', {});
      await fetchMyBikes();
    } catch (e) {
      debugPrint('Error toggling availability: $e');
    }
  }

  Future<bool> deleteBike(String bikeId) async {
    try {
      await _apiService.delete('/bikes/$bikeId');
      await fetchMyBikes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting bike: $e');
      return false;
    }
  }

  Future<bool> requestRental(String bikeId, DateTime start, DateTime end, {String paymentMethod = 'UPI'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/bikes/$bikeId/request-rental', {
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'paymentMethod': paymentMethod,
      });
      await fetchMyRentals();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error requesting rental: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyRentals() async {
    if (kMockMode) return;
    try {
      final response = await _apiService.get('/bikes/my-rentals');
      if (response is List) {
        _myRentals = response.map((e) => BikeRentalModel.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching my rentals: $e');
    }
  }

  Future<void> fetchIncomingRentals() async {
    if (kMockMode) return;
    try {
      final response = await _apiService.get('/bikes/incoming-rentals');
      if (response is List) {
        _incomingRentals = response.map((e) => BikeRentalModel.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching incoming rentals: $e');
    }
  }

  Future<bool> approveRental(String rentalId) async {
    try {
      await _apiService.post('/bikes/rentals/$rentalId/approve', {});
      await fetchIncomingRentals();
      await fetchAvailableBikes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error approving rental: $e');
      return false;
    }
  }

  Future<bool> confirmPayment(String rentalId, {String? paymentScreenshot, String? paymentMethod}) async {
    try {
      await _apiService.post('/bikes/rentals/$rentalId/confirm-payment', {
        if (paymentScreenshot != null) 'paymentScreenshot': paymentScreenshot,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      });
      await fetchMyRentals();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error confirming payment: $e');
      return false;
    }
  }

  Future<bool> confirmReceived(String rentalId) async {
    try {
      await _apiService.post('/bikes/rentals/$rentalId/confirm-received', {});
      await fetchIncomingRentals();
      await fetchAvailableBikes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error confirming handover: $e');
      return false;
    }
  }

  Future<bool> returnBike(String rentalId) async {
    try {
      await _apiService.post('/bikes/rentals/$rentalId/return', {});
      await fetchIncomingRentals();
      await fetchMyRentals();
      await fetchAvailableBikes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error returning bike: $e');
      return false;
    }
  }

  Future<bool> cancelRental(String rentalId) async {
    try {
      await _apiService.post('/bikes/rentals/$rentalId/cancel', {});
      await fetchMyRentals();
      await fetchIncomingRentals();
      await fetchAvailableBikes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cancelling rental: $e');
      return false;
    }
  }
}
