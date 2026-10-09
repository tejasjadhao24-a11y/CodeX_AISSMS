import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'ride_booking_screen.dart';
import 'available_drivers_screen.dart';
import 'active_ride_screen.dart';

import '../../core/providers/ride_provider.dart';
import '../../models/ride_model.dart';
import 'passenger_active_ride_screen.dart';
import 'ride_request_waiting_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  Timer? _refreshTimer;
  bool _hasNavigated = false;
  
  void _navigate(String route) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _refreshTimer?.cancel();
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    await context.read<RideProvider>().fetchActiveRide();
    if (!mounted) return;
    await context.read<RideProvider>().fetchCommunityRides();
    _checkAndNavigate();
    _startTimer();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      await context.read<RideProvider>().fetchActiveRide();
      if (!mounted) return;
      await context.read<RideProvider>().fetchCommunityRides();
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    if (rideProvider.state == RideState.accepted || rideProvider.state == RideState.inProgress) {
      _navigate('/passenger-active-ride');
    } else if (rideProvider.state == RideState.waiting) {
      final ride = rideProvider.activeRide;
      if (ride != null) {
         _hasNavigated = true;
         _refreshTimer?.cancel();
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
          RideRequestWaitingScreen(fromLocation: ride.fromLocation, toLocation: ride.toLocation)));
      }
    } else if (rideProvider.state == RideState.completed) {
      _navigate('/ride-completed');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final userName = user?.name.split(' ')[0] ?? 'Student';
    final credits = user?.points ?? 0;

    return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  Container(
                    height: 260,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            const CampusLiftLogo(
                              size: 28,
                              textColor: Colors.white,
                              showTagline: false,
                            ),
                            const SizedBox(height: 20),
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.waving_hand,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Hi, $userName!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.stars, color: Colors.amber, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$credits pts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Where to next?',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Find affordable rides within your campus community.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms),

                  // Search Bar
                  Transform.translate(
                    offset: const Offset(0, -25),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RideBookingScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Search for a destination...',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<RideProvider>(
                          builder: (context, provider, child) {
                            final activeRide = provider.activeRide;
                            if (activeRide != null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Active Ride',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                                  const SizedBox(height: 16),
                                  
                                  _buildActiveRideCard(context, activeRide),
                                     
                                  const SizedBox(height: 32),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context,
                                'Find Ride',
                                'Search available rides',
                                Icons.directions_car,
                                AppColors.primary,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AvailableDriversScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionCard(
                                context,
                                'Create Request',
                                'Ask for a custom ride',
                                Icons.add_location_alt,
                                AppColors.secondary,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const RideBookingScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                        const SizedBox(height: 24),

                        // Community Rides
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Active Community Rides',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                context.read<RideProvider>().fetchCommunityRides();
                              },
                              child: const Text('Refresh'),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                        const SizedBox(height: 8),

                        Consumer<RideProvider>(
                          builder: (context, rideProvider, child) {
                            if (rideProvider.isCommunityLoading && rideProvider.communityRides.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderGrey),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (rideProvider.communityError != null && rideProvider.communityRides.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderGrey),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Unable to load community rides",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          context.read<RideProvider>().fetchCommunityRides();
                                        },
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final rides = rideProvider.communityRides;
                            if (rides.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderGrey),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.directions_car_filled_outlined, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        "No community rides right now. Check back later!",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rides.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildCommunityRideCard(
                                  context,
                                  rides[index],
                                );
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityRideCard(
    BuildContext context,
    RideModel ride,
  ) {
    final route = '${ride.fromLocation} to ${ride.toLocation}';
    final timeStr = ride.scheduledTime != null 
        ? DateFormat('hh:mm a').format(ride.scheduledTime!)
        : (DateFormat('hh:mm a').format(ride.createdAt));
    
    String statusLabel = 'Pending';
    Color statusColor = AppColors.secondary;
    if (ride.status == RideStatus.accepted) {
      statusLabel = 'Assigned';
      statusColor = Colors.teal;
    } else if (ride.status == RideStatus.inProgress) {
      statusLabel = 'En Route';
      statusColor = AppColors.primary;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideBookingScreen(
                initialPickup: ride.fromLocation,
                initialDropoff: ride.toLocation,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.passengerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ride.vehicleDetails ?? 'Ride with ${ride.passengerName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Book this route',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRideCard(BuildContext context, RideModel ride) {
    switch (ride.status) {
      case RideStatus.pending:
        return _buildPendingCard(context, ride);
      case RideStatus.accepted:
        return _buildAcceptedCard(context, ride);
      case RideStatus.inProgress:
        return _buildInProgressCard(context, ride);
      default:
        return _buildRideDetailsCard(context, ride);
    }
  }

  Widget _buildPendingCard(BuildContext context, RideModel ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Looking for a rider...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Your request is visible to nearby riders', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Provider.of<RideProvider>(context, listen: false).cancelRide(ride.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel Ride Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedCard(BuildContext context, RideModel ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.celebration, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('🎉 Ride Accepted!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          _buildRideDetailsCard(context, ride),
        ],
      ),
    );
  }

  Widget _buildInProgressCard(BuildContext context, RideModel ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('🚗 Ride in Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          _buildRideDetailsCard(context, ride),
        ],
      ),
    );
  }

  Widget _buildRideDetailsCard(BuildContext context, RideModel ride) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride Status: ${ride.status.toString().toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Icon(Icons.navigation, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(ride.fromLocation, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 7),
              child: Icon(Icons.more_vert, size: 12, color: AppColors.textMuted),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(ride.toLocation, style: const TextStyle(fontSize: 14))),
              ],
            ),
            if (ride.riderName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Rider: ${ride.riderName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (ride.status == RideStatus.accepted || ride.status == RideStatus.inProgress) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const PassengerActiveRideScreen()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ActiveRideScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Track Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

