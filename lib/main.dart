import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/ride_provider.dart';
import 'core/providers/rental_provider.dart';
import 'core/providers/taxi_provider.dart';
import 'core/providers/community_service_provider.dart';
import 'core/providers/bike_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'services/socket_service.dart';
import 'services/location_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/driver_agreement_screen.dart';
import 'screens/rider/main_rider_screen.dart';
import 'screens/passenger/main_passenger_screen.dart';
import 'screens/rider/active_ride_screen.dart';
import 'screens/passenger/ride_completed_screen.dart';
import 'screens/bike/bike_rental_screen.dart';
import 'screens/bike/post_bike_screen.dart';
import 'screens/bike/bike_detail_screen.dart';
import 'screens/bike/rental_detail_screen.dart';

import 'screens/profile/emergency_contacts_screen.dart';
import 'screens/profile/certificates_screen.dart';
import 'screens/passenger/passenger_active_ride_screen.dart';
import 'screens/passenger/ride_booking_screen.dart';
import 'screens/passenger/ride_request_waiting_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => SocketService()),
        Provider(create: (context) => LocationService()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProxyProvider<SocketService, UserProvider>(
          create: (context) => UserProvider(Provider.of<SocketService>(context, listen: false)),
          update: (context, socketService, userProvider) => userProvider!,
        ),
        ChangeNotifierProxyProvider<SocketService, RideProvider>(
          create: (context) => RideProvider(Provider.of<SocketService>(context, listen: false)),
          update: (context, socketService, rideProvider) => rideProvider!,
        ),
        ChangeNotifierProvider(create: (context) => RentalProvider()),
        ChangeNotifierProvider(create: (context) => TaxiProvider()),
        ChangeNotifierProvider(create: (context) => CommunityServiceProvider()),
        ChangeNotifierProxyProvider<SocketService, BikeProvider>(
          create: (context) => BikeProvider(Provider.of<SocketService>(context, listen: false)),
          update: (context, socketService, bikeProvider) => bikeProvider!,
        ),
      ],
      child: const CampusLiftApp(),
    ),
  );
}

class CampusLiftApp extends StatelessWidget {
  const CampusLiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserProvider>(
      builder: (context, themeProvider, userProvider, child) {
        return MaterialApp(
          title: 'CampusLift',
          theme: themeProvider.currentTheme,
          home: const AuthWrapper(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/role-selection': (context) => const RoleSelectionScreen(),
            '/active-ride': (context) => const ActiveRideScreen(),
            '/ride-completed': (context) => const RideCompletedScreen(),
            '/rider-dashboard': (context) => const MainRiderScreen(),
            '/passenger-home': (context) => const MainPassengerScreen(),
            '/emergency-contacts': (context) => const EmergencyContactsScreen(),
            '/bike-rental': (context) => const BikeRentalScreen(),
            '/post-bike': (context) => const PostBikeScreen(),
            '/bike-detail': (context) => const BikeDetailScreen(),
            '/rental-detail': (context) => const RentalDetailScreen(),
            '/ride-booking': (context) => const RideBookingScreen(),
            '/ride-waiting': (context) => const RideRequestWaitingScreen(fromLocation: '', toLocation: ''),
            '/passenger-active-ride': (context) => const PassengerActiveRideScreen(),
            '/certificates': (context) => const CertificatesScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isInitializing) {
          return const SplashScreen();
        }
        
        if (provider.currentUser == null) {
          return const LoginScreen();
        }
        
        final user = provider.currentUser!;
        
        if (!user.acceptedGuidelines) {
          return const DriverAgreementScreen();
        }
        
        if (user.role == null || user.role!.isEmpty) {
          return const RoleSelectionScreen();
        }
        
        if (user.role == 'rider') {
          return const MainRiderScreen();
        }
        
        return const MainPassengerScreen();
      }
    );
  }
}
