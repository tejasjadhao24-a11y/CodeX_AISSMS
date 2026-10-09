import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/providers/ride_provider.dart';

class RideRequestWaitingScreen extends StatefulWidget {
  final String fromLocation;
  final String toLocation;

  const RideRequestWaitingScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
  });

  @override
  State<RideRequestWaitingScreen> createState() =>
      _RideRequestWaitingScreenState();
}

class _RideRequestWaitingScreenState extends State<RideRequestWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _checkTimer;
  bool _hasNavigated = false;
  
  void _navigate(String route) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _checkTimer?.cancel();
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RideProvider>();
      if (provider.activeRide == null) {
        await provider.fetchActiveRide();
      }
      
      if (!mounted) return;
      
      if (provider.activeRide == null && provider.state != RideState.waiting) {
        if (!_hasNavigated) {
          _hasNavigated = true;
          Navigator.pushNamedAndRemoveUntil(context, '/passenger-home', (route) => false);
        }
        return;
      }
      
      _startChecking();
    });
  }

  void _startChecking() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 3), 
      (_) async {
        if (!mounted || _hasNavigated) return;
        
        final provider = context.read<RideProvider>();
        await provider.fetchActiveRide();
        
        if (!mounted || _hasNavigated) return;
        
        if (provider.state == RideState.accepted || provider.state == RideState.inProgress) {
          _navigate('/passenger-active-ride');
        } else if (provider.state == RideState.idle || provider.state == RideState.cancelled) {
          _navigate('/passenger-home');
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        // Immediate socket reaction:
        if (provider.state == RideState.accepted || provider.state == RideState.inProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigate('/passenger-active-ride');
          });
        } else if (provider.state == RideState.cancelled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigate('/passenger-home');
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Request?'),
                    content: const Text('Are you sure you want to cancel your ride request?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final rideProvider = context.read<RideProvider>();
                  final activeRide = rideProvider.activeRide;
                  if (activeRide != null) {
                    await rideProvider.cancelRide(activeRide.id);
                  }
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/passenger-home', (route) => false);
                  }
                }
              },
            ),
          ),
      body: Column(
        children: [
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CampusLiftLogo(
                  size: 24,
                  showTagline: false,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer animated circle
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.2).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Middle circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    // Center Animated Car Illustration
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: const Icon(
                        Icons.drive_eta,
                        size: 40,
                        color: AppColors.primary,
                      )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .rotate(begin: 0, end: 0.1, duration: 500.ms)
                                .then()
                                .rotate(begin: 0.1, end: -0.1, duration: 500.ms)
                                .then()
                                .rotate(begin: -0.1, end: 0, duration: 500.ms),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // Finding text with animation
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Text(
                    'Finding nearby drivers...',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Loading dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(index * 0.2, (index + 1) * 0.2 + 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rider Info Card
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Ride Details',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pickup Location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.fromLocation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Drop Location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.toLocation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est. Price',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Consumer<RideProvider>(
                      builder: (context, provider, _) => Text(
                        '${provider.activeRide?.pointsAwarded ?? 10} pts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Cancel Ride Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () async {
                  final provider = context.read<RideProvider>();
                  if (provider.activeRide != null) {
                    await provider.cancelRide(provider.activeRide!.id);
                  }
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/passenger-home', (route) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.alertRed),
                ),
                child: Text(
                  'Cancel Ride',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.alertRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
