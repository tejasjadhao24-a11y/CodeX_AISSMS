import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';

import '../../core/providers/ride_provider.dart';
import '../../services/socket_service.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';
import '../auth/license_verification_screen.dart';
import '../passenger/my_rides_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  Timer? _pollTimer;
  int _totalRides = 0;
  int _credits = 0;
  double _rating = 0.0;
  Map? _certificate;

  @override
  void initState() {
    super.initState();
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRides();
      _startPolling();
    });
  }

  Future<void> _loadStats() async {
    try {
      final api = ApiService();
      final response = await api.get('/users/profile-stats');
      if (mounted) {
        setState(() {
          _totalRides = response['totalRides'] ?? 0;
          _credits = response['points'] ?? 0;
          _rating = (response['avgRating'] ?? 0.0).toDouble();
          _certificate = response['certificate'];
        });
      }
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).loadUser();
      }
    } catch (e) {
      debugPrint('Dashboard stats: $e');
    }
  }

  void _loadRides() {
    if (!mounted) return;
    context.read<RideProvider>().fetchPendingRides();
    context.read<RideProvider>().fetchHistory(role: 'rider');
    context.read<RideProvider>().syncWithServer().then((_) => _checkAndNavigate());
  }

  bool _hasNavigated = false;
  void _navigateTo(String route) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _pollTimer?.cancel();
    Navigator.pushNamed(context, route).then((_) {
      if (mounted) {
        _hasNavigated = false;
        _startPolling();
        _loadRides();
      }
    });
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    if (rideProvider.state == RideState.accepted || rideProvider.state == RideState.inProgress) {
      _navigateTo('/active-ride');
    } else if (rideProvider.state == RideState.completed) {
      _navigateTo('/ride-completed');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4), (_) {
        _loadRides();
      });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleOnline(bool value) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final status = userProvider.currentUser?.verificationStatus ?? 'unverified';
    if (status != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account must be verified before you can go online.'),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }

    final socketService = Provider.of<SocketService>(context, listen: false);
    await userProvider.toggleOnline(value);
    if (value) {
      socketService.joinRidersRoom();
    } else {
      socketService.leaveRidersRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, RideProvider>(
      builder: (context, userProvider, rideProvider, child) {
        final user = userProvider.currentUser;
        final status = user?.verificationStatus ?? 'unverified';
        final userName = user?.name.split(' ')[0] ?? 'Driver';
        final isOnline = user?.isOnline ?? false;
        final activeRide = rideProvider.activeRide;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: false,
            title: const CampusLiftLogo(
              size: 24,
              showTagline: false,
            ),
            actions: [
              Row(
                children: [
                  Text(
                    (isOnline && status == 'approved') ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (isOnline && status == 'approved') ? AppColors.secondary : AppColors.textMuted,
                    ),
                  ),
                  Switch(
                    value: isOnline && (status == 'approved'),
                    onChanged: (status == 'approved') ? _toggleOnline : (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Your account must be verified by admin before going online.'),
                          backgroundColor: AppColors.alertRed,
                        ),
                      );
                    },
                    activeThumbColor: AppColors.secondary,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                color: AppColors.textSecondary,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await rideProvider.fetchPendingRides();
              await rideProvider.fetchActiveRide();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.drive_eta,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Welcome back, $userName!',
                                        style: Theme.of(context).textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (status == 'approved') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text(
                                              'Verified',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_certificate != null && _certificate!['level'] > 0) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(_certificate!['color'].replaceFirst('#', 'FF'), radix: 16)).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(int.parse(_certificate!['color'].replaceFirst('#', 'FF'), radix: 16)).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      '${_certificate!['emoji']} ${_certificate!['title']}',
                                      style: TextStyle(
                                        color: Color(int.parse(_certificate!['color'].replaceFirst('#', 'FF'), radix: 16)),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (isOnline && status == 'approved')
                            ? 'You are online and visible to passengers.'
                            : 'Go online to start accepting ride requests.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: 16),
                _buildVerificationBanner(context, status, user?.verificationNote),
                const SizedBox(height: 16),

                // Active Ride
                if (activeRide != null) ...[
                  _buildActiveRideCard(context, activeRide),
                  const SizedBox(height: 32),
                ],

                // Pending Requests Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Requests',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                
                if (status != 'approved')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Ride Requests Locked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Verify your driving credentials above to unlock live student ride requests.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms)
                else if (isOnline)
                  Builder(
                    builder: (context) {
                      if (rideProvider.isLoading && rideProvider.pendingRides.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (rideProvider.pendingRides.isEmpty) {
                        return const Center(child: Text('No new requests'));
                      }
                      // Use a Column since we are inside a SingleChildScrollView
                      return Column(
                        children: rideProvider.pendingRides.map((ride) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RideRequestCard(
                              ride: ride,
                              onRideAccepted: () => _navigateTo('/active-ride'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: const Text(
                      'Go online to see ride requests',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                const SizedBox(height: 32),

                // Stats Cards
                Text(
                  'Your Stats',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Rides',
                        '$_totalRides',
                        Icons.directions_car,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Credits Earned',
                        '$_credits pts',
                        Icons.stars,
                        Colors.amber,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                const SizedBox(height: 16),

                _buildStatCard(
                  context,
                  'Rating',
                  _rating.toStringAsFixed(1),
                  Icons.star,
                  AppColors.accentBlue,
                  isFullWidth: true,
                ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                const SizedBox(height: 32),

                // Ride History Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ride History',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyRidesScreen(role: 'rider'),
                          ),
                        );
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 700.ms),

                const SizedBox(height: 16),

                if (rideProvider.rideHistory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('No recent rides'),
                  )
                else
                  ...rideProvider.rideHistory.take(3).map((ride) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildActivityCard(
                      context,
                      'Ride completed',
                      '${ride.fromLocation} to ${ride.toLocation}',
                      '+ ${ride.pointsAwarded} pts',
                      'Recently',
                      AppColors.secondary,
                    ),
                  )),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildActiveRideCard(BuildContext context, RideModel ride) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Active Ride',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Text(
                ride.status.name.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('From: ${ride.fromLocation}', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('To: ${ride.toLocation}', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _navigateTo('/active-ride');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Details'),
            ),
          )
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms);
  }

  // _buildRequestCard replaced by _RideRequestCard StatefulWidget below

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String subtitle,
    String amount,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context, String status, String? note) {
    if (status == 'approved') {
      return const SizedBox.shrink();
    }

    Color bannerColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String message;
    String buttonText;
    VoidCallback? onButtonPress;

    switch (status) {
      case 'pending':
        bannerColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade300;
        textColor = Colors.amber.shade900;
        icon = Icons.hourglass_empty;
        message = 'Verification under review ⏳. We are currently verifying your driver details. Once approved, you can start accepting rides.';
        buttonText = 'Check Details';
        onButtonPress = () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LicenseVerificationScreen()),
          );
        };
        break;
      case 'rejected':
        bannerColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        textColor = Colors.red.shade900;
        icon = Icons.error_outline;
        message = 'Verification rejected ❌. Reason: ${note ?? "Details did not match."} Please correct your details and re-submit.';
        buttonText = 'Fix Now';
        onButtonPress = () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LicenseVerificationScreen()),
          );
        };
        break;
      case 'unverified':
      default:
        bannerColor = AppColors.primary.withValues(alpha: 0.05);
        borderColor = AppColors.primary.withValues(alpha: 0.2);
        textColor = AppColors.primary;
        icon = Icons.info_outline;
        message = 'Driver registration is incomplete. Please submit your license & RC details to start accepting rides.';
        buttonText = 'Verify Now';
        onButtonPress = () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LicenseVerificationScreen()),
          );
        };
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onButtonPress,
              style: TextButton.styleFrom(
                backgroundColor: textColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                buttonText,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ---------------------------------------------------------------------------
// _RideRequestCard — StatefulWidget so each card can own its loading state
// ---------------------------------------------------------------------------
class _RideRequestCard extends StatefulWidget {
  final RideModel ride;
  final VoidCallback? onRideAccepted;
  const _RideRequestCard({required this.ride, this.onRideAccepted});

  @override
  State<_RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends State<_RideRequestCard> {
  bool _isAccepting = false;

  Future<void> _onAccept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    
    try {
      final success = await context.read<RideProvider>().acceptRide(widget.ride.id);
      
      if (!mounted) return;
      
      if (success) {
        if (widget.onRideAccepted != null) {
          widget.onRideAccepted!();
        } else {
          Navigator.pushNamed(context, '/active-ride');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<RideProvider>().errorMessage ?? 'Failed to accept ride'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final ride = widget.ride;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ride.passengerName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade700, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${ride.fromLocation} to ${ride.toLocation}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('+${ride.pointsAwarded} pts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_isAccepting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => rideProvider.declineRide(ride.id),
                  icon: const Icon(Icons.close, color: Colors.red),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  onPressed: _isAccepting ? null : _onAccept,
                  icon: const Icon(Icons.check_circle,
                      color: AppColors.secondary),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
