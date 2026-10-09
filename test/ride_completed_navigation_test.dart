import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campus_lift/core/providers/ride_provider.dart';
import 'package:campus_lift/core/providers/user_provider.dart';
import 'package:campus_lift/core/theme/theme_provider.dart';
import 'package:campus_lift/models/ride_model.dart';
import 'package:campus_lift/models/user_model.dart';
import 'package:campus_lift/screens/passenger/ride_completed_screen.dart';
import 'package:campus_lift/screens/auth/role_selection_screen.dart';
import 'package:campus_lift/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Passenger lands on role selection screen when clicking skip rating', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final socketService = SocketService();
    final userProvider = UserProvider(socketService, isTestMode: true);
    userProvider.setUserForTesting(UserModel(
      id: 'test-passenger-1',
      name: 'Passenger Alice',
      email: 'alice@vit.edu',
      role: 'passenger',
      phone: '9876543210',
    ));

    final testRide = RideModel(
      id: 'ride-1234',
      passengerId: 'test-passenger-1',
      passengerName: 'Passenger Alice',
      riderId: 'test-rider-1',
      riderName: 'Driver Bob',
      fromLocation: 'Gate 1',
      toLocation: 'Library',
      status: RideStatus.completed,
      pointsAwarded: 10,
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
          routes: {
            '/': (context) => RideCompletedScreen(ride: testRide),
            '/role-selection': (context) => const RoleSelectionScreen(),
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final skipFinder = find.text('Skip rating');
    expect(skipFinder, findsOneWidget);
    await tester.ensureVisible(skipFinder);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(skipFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Must land on Role Selection Screen
    expect(find.text('Choose Your Role'), findsOneWidget);
    expect(find.text('Become a Rider'), findsOneWidget);
    expect(find.text('Ride as Passenger'), findsOneWidget);
    expect(userProvider.currentUser?.role == null || userProvider.currentUser?.role == '', isTrue);
  });

  testWidgets('Driver lands on role selection screen when clicking finish/done', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final socketService = SocketService();
    final userProvider = UserProvider(socketService, isTestMode: true);
    userProvider.setUserForTesting(UserModel(
      id: 'test-rider-1',
      name: 'Driver Bob',
      email: 'bob@vit.edu',
      role: 'rider',
      phone: '9876543210',
    ));

    final testRide = RideModel(
      id: 'ride-1234',
      passengerId: 'test-passenger-1',
      passengerName: 'Passenger Alice',
      riderId: 'test-rider-1',
      riderName: 'Driver Bob',
      fromLocation: 'Gate 1',
      toLocation: 'Library',
      status: RideStatus.completed,
      pointsAwarded: 10,
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
          routes: {
            '/': (context) => RideCompletedScreen(ride: testRide),
            '/role-selection': (context) => const RoleSelectionScreen(),
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final doneFinder = find.text('Done - Choose Next Role');
    expect(doneFinder, findsOneWidget);
    await tester.ensureVisible(doneFinder);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(doneFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Must land on Role Selection Screen
    expect(find.text('Choose Your Role'), findsOneWidget);
    expect(find.text('Become a Rider'), findsOneWidget);
    expect(find.text('Ride as Passenger'), findsOneWidget);
    expect(userProvider.currentUser?.role == null || userProvider.currentUser?.role == '', isTrue);
  });

  testWidgets('Passenger selects star rating and clicks Submit & Finish lands on role selection screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final socketService = SocketService();
    final userProvider = UserProvider(socketService, isTestMode: true);
    userProvider.setUserForTesting(UserModel(
      id: 'test-passenger-1',
      name: 'Passenger Alice',
      email: 'alice@vit.edu',
      role: 'passenger',
      phone: '9876543210',
    ));

    final testRide = RideModel(
      id: 'ride-1234',
      passengerId: 'test-passenger-1',
      passengerName: 'Passenger Alice',
      riderId: 'test-rider-1',
      riderName: 'Driver Bob',
      fromLocation: 'Gate 1',
      toLocation: 'Library',
      status: RideStatus.completed,
      pointsAwarded: 10,
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
          routes: {
            '/': (context) => RideCompletedScreen(ride: testRide),
            '/role-selection': (context) => const RoleSelectionScreen(),
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap on a rating star
    final starFinders = find.byIcon(Icons.star_outline_rounded);
    expect(starFinders, findsWidgets);
    await tester.tap(starFinders.last);
    await tester.pump(const Duration(milliseconds: 300));

    // Submit button is now enabled
    final submitFinder = find.text('Submit & Finish');
    expect(submitFinder, findsOneWidget);
    await tester.ensureVisible(submitFinder);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(submitFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Must land on Role Selection Screen
    expect(find.text('Choose Your Role'), findsOneWidget);
    expect(find.text('Become a Rider'), findsOneWidget);
    expect(find.text('Ride as Passenger'), findsOneWidget);
    expect(userProvider.currentUser?.role == null || userProvider.currentUser?.role == '', isTrue);
  });
}
