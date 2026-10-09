import 'package:flutter/material.dart';
import '../../models/rider_model.dart';
import '../../models/ride_model.dart';
import '../../models/ride_type.dart';
import 'dart:math';

class RentalProvider extends ChangeNotifier {
  // Mock list of riders
  final List<RiderModel> _riders = [
    RiderModel(id: 'r1', name: 'John Doe', vehicleType: 'Bike', vehicleNumber: 'MH12 AB 1234', isAvailable: true),
    RiderModel(id: 'r2', name: 'Jane Smith', vehicleType: 'Scooter', vehicleNumber: 'MH12 CD 5678', isAvailable: false),
    RiderModel(id: 'r3', name: 'Alex Johnson', vehicleType: 'Bike', vehicleNumber: 'MH12 EF 9012', isAvailable: true),
  ];

  final List<RideModel> _rentalRequests = [];

  List<RiderModel> get availableRiders => _riders.where((r) => r.isAvailable).toList();
  List<RideModel> get rentalRequests => _rentalRequests;

  /// Toggle rider availability (ONLINE/OFFLINE)
  void toggleAvailability(String riderId, bool available) {
    final index = _riders.indexWhere((r) => r.id == riderId);
    if (index != -1) {
      _riders[index] = _riders[index].copyWith(isAvailable: available);
      notifyListeners();
    }
  }

  /// Passenger sends a rental request
  void sendRentalRequest({
    required String passengerId,
    String? riderId, // Optional: if null, auto-assign first available
  }) {
    String? targetRiderId = riderId;
    
    if (targetRiderId == null) {
      final available = availableRiders;
      if (available.isNotEmpty) {
        targetRiderId = available.first.id;
      }
    }

    if (targetRiderId != null) {
      final request = RideModel(
        id: "rent_${Random().nextInt(10000)}",
        passengerId: passengerId,
        passengerName: "Rental Passenger", // Placeholder
        fromLocation: "Current Location",
        toLocation: "Flexible",
        fromLat: 0.0, // Placeholder
        fromLng: 0.0, // Placeholder
        toLat: 0.0,   // Placeholder
        toLng: 0.0,   // Placeholder
        createdAt: DateTime.now(),
        type: RideType.rental,
        status: RideStatus.pending,
        riderId: targetRiderId,
      );
      
      _rentalRequests.add(request);
      notifyListeners();
    }
  }

  /// Rider handles the rental request (Accept/Reject)
  void handleResponse(String requestId, RideStatus status) {
    final index = _rentalRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      if (status == RideStatus.accepted) {
        _rentalRequests[index] = _rentalRequests[index].copyWith(status: RideStatus.accepted);
      } else if (status == RideStatus.cancelled) {
        // Fallback or just cancel for now
        _rentalRequests[index] = _rentalRequests[index].copyWith(status: RideStatus.cancelled);
      }
      notifyListeners();
    }
  }
}

