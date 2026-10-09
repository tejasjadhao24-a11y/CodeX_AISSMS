import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campus_lift/core/providers/ride_provider.dart';
import 'package:campus_lift/core/providers/user_provider.dart';
import 'package:campus_lift/core/theme/theme_provider.dart';
import 'package:campus_lift/models/ride_model.dart';
import 'package:campus_lift/models/user_model.dart';
import 'package:campus_lift/screens/passenger/ride_completed_screen.dart';
import 'package:campus_lift/services/socket_service.dart';

void main() {
  testWidgets('RideCompletedScreen renders without overflow on 320x568 small screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final socketService = SocketService();
    final userProvider = UserProvider(socketService);
    userProvider.setUserForTesting(UserModel(
      id: 'test-passenger-1',
      name: 'Priya Sharma Longname Example',
      email: 'priya@vit.edu',
      role: 'passenger',
      phone: '9876543210',
    ));

    final testRide = RideModel(
      id: 'ride-12345678-abcd',
      passengerId: 'test-passenger-1',
      passengerName: 'Priya Sharma Longname Example',
      riderId: 'test-rider-1',
      riderName: 'Rahul Verma Longname Driver Example',
      fromLocation: 'VIT Pune Main Gate Sector A Campus',
      toLocation: 'Shivajinagar Station Bus Terminal',
      status: RideStatus.completed,
      pointsAwarded: 5,
      fromLat: 18.4624,
      fromLng: 73.8670,
      toLat: 18.4700,
      toLng: 73.8750,
      createdAt: DateTime.now(),
    );

    final rideProvider = RideProvider(socketService);
    rideProvider.setCompletedRideForTesting(testRide);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SocketService>.value(value: socketService),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<RideProvider>.value(value: rideProvider),
        ],
        child: MaterialApp(
          home: RideCompletedScreen(ride: testRide),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("You've Arrived!"), findsOneWidget);
    expect(find.text("RIDE SUMMARY"), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Verify no RenderFlex overflow exceptions were thrown
    expect(tester.takeException(), isNull);
  });
}
