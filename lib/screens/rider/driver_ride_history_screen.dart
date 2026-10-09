import 'package:flutter/material.dart';
import '../passenger/my_rides_screen.dart';

/// Driver-side ride history screen parameterized by the 'rider' / 'driver' role.
/// Reuses the shared [MyRidesScreen] and [RideHistoryList] components.
class DriverRideHistoryScreen extends StatelessWidget {
  const DriverRideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyRidesScreen(role: 'rider');
  }
}
