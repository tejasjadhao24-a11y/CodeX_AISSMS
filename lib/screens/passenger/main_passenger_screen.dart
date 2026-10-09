import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/theme/app_colors.dart';
import 'passenger_home_screen.dart';
import 'my_rides_screen.dart';
import '../safety/safety_screen.dart';
import '../profile/profile_screen.dart';
import '../shared/community_services_screen.dart';

class MainPassengerScreen extends StatefulWidget {
  const MainPassengerScreen({super.key});

  @override
  State<MainPassengerScreen> createState() => _MainPassengerScreenState();
}

class _MainPassengerScreenState extends State<MainPassengerScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      
      // 1. Start listening to real-time events
      rideProvider.listenToSocketEvents(userProvider);
      
      // 2. Fetch current state
      rideProvider.fetchActiveRide();
    });
  }

  final List<Widget> _screens = [
    const PassengerHomeScreen(),
    const MyRidesScreen(),
    const CommunityServicesScreen(),
    const SafetyScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _passengerNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'My Rides',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Community',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shield_outlined),
      activeIcon: Icon(Icons.shield),
      label: 'Safety',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.borderGrey, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            items: _passengerNavItems,
          ),
        ),
      ),
    );
  }
}
