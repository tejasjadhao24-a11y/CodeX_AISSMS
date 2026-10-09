import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';

class RideCompletedScreen extends StatefulWidget {
  final RideModel? ride;
  const RideCompletedScreen({super.key, this.ride});

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int _selectedRating = 0;
  RideProvider? _rideProvider;
  bool _isNavigating = false;

  void _finishAndGoToRoleSelection({int? rating}) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final ride = rideProvider.lastCompletedRide ?? widget.ride;

    // 1. Submit rating to backend in background if passenger submitted
    if (rating != null && rating > 0 && ride != null) {
      unawaited(rideProvider.rateRide(ride.id, rating));
    }

    // 2. Clear role and reset ride in memory and storage (non-blocking)
    unawaited(userProvider.clearRole());
    unawaited(rideProvider.resetForNewRide());

    // 3. Smooth, immediate navigation with clean stack replacement
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/role-selection',
      (route) => false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rideProvider = Provider.of<RideProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RideProvider>(context, listen: false).clearActiveRide();
      _checkAchievement();
    });
  }

  @override
  void dispose() {
    try {
      if (_rideProvider?.state == RideState.completed) {
        _rideProvider?.resetForNewRide();
      }
    } catch (e) {
      debugPrint('Error resetting completed ride in dispose: $e');
    }
    super.dispose();
  }

  Future<void> _checkAchievement() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final points = userProvider.currentUser?.points ?? 0;
    
    // Threshold check (assuming exactly hit, or slightly over if we want to be safe, but we'll use exact for now or ranges)
    // Actually if they just earned points, maybe they crossed it. Let's just check if it's in a window or use the exact thresholds.
    // The previous summary mentioned "when a user crosses a points threshold". We will fetch anyway to show if needed, but to avoid spam, we can just do:
    if (points >= 100) {
      try {
        final api = ApiService();
        final res = await api.get('/users/profile-stats');
        final cert = res['certificate'];
        // Ideally we'd store the 'lastSeenLevel' locally to only show once, but for now we'll show if they hit exactly
        if (cert != null && mounted) {
           if (points == 100 || points == 105 || points == 110 || points == 500 || points == 505 || points == 1000 || points == 2000) {
             showDialog(
               context: context,
               builder: (_) => AlertDialog(
                 title: const Text('🎉 New Achievement!'),
                 content: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(cert['emoji'], style: const TextStyle(fontSize: 50)),
                     const SizedBox(height: 10),
                     Text('You are now a ${cert['title']}!', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     Text(cert['description'], textAlign: TextAlign.center),
                   ],
                 ),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(context),
                     child: const Text('Awesome!'),
                   )
                 ],
               ),
             );
           }
        }
      } catch (e) {
        debugPrint('Achievement err: \$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    final isPassenger = userProvider.currentUser?.role == 'passenger' || 
                        ((rideProvider.lastCompletedRide ?? widget.ride)?.passengerId == userProvider.currentUser?.id);
    final ride = rideProvider.lastCompletedRide ?? widget.ride;

    if (ride == null) {
      // If we have a persisted ID, don't redirect home yet - wait for the fetch
      if (rideProvider.lastCompletedRideId != null) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text("Loading ride details...", style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishAndGoToRoleSelection();
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finishAndGoToRoleSelection();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              isPassenger ? AppColors.primary.withValues(alpha: 0.05) : AppColors.secondary.withValues(alpha: 0.05),
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CampusLiftLogo(size: 28, showTagline: false)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 40),
                  
                  // Success Icon with pulses
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: (isPassenger ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.5, 1.5), duration: 2.seconds, curve: Curves.easeOut).fadeOut(),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isPassenger ? AppColors.primary : AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isPassenger ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ]
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 200.ms, duration: 500.ms, begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    isPassenger ? "You've Arrived!" : "Ride Completed!",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    isPassenger ? "Hope you had a great ride" : "Excellent service, Rider!",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Points Summary Card
                  _buildPremiumPointsCard(isPassenger, ride)
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  if (isPassenger) ...[
                    const Text(
                      "Rate your experience",
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 16),
                    _buildStarRating()
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .shimmer(delay: 1.seconds, duration: 1.seconds),
                    const SizedBox(height: 32),
                  ],
                  
                  // Summary Receipt
                  _buildDigitalReceipt(context, ride)
                      .animate()
                      .fadeIn(delay: 900.ms)
                      .slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  if (isPassenger) 
                    _buildPassengerActions(ride)
                  else
                    _buildRiderActions(),
                    
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPremiumPointsCard(bool isPassenger, RideModel ride) {
    final color = isPassenger ? AppColors.primary : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPassenger ? "POINTS EARNED" : "REWARD EARNED",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                isPassenger ? "+5 Points" : "+${ride.pointsAwarded} Points",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) => IconButton(
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          icon: Icon(
            index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: index < _selectedRating ? Colors.amber : AppColors.borderGrey,
            size: 40,
          ),
          onPressed: () => setState(() => _selectedRating = index + 1),
        )),
      ),
    );
  }

  Widget _buildDigitalReceipt(BuildContext context, RideModel ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("RIDE SUMMARY", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textMuted, letterSpacing: 1)),
              Text((ride.id.length >= 8 ? ride.id.substring(0, 8) : ride.id).toUpperCase(), style: const TextStyle(fontFamily: 'monospace', color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 20),
          _buildReceiptRow(Icons.circle, AppColors.primary, "From", ride.fromLocation),
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Container(width: 2, height: 20, color: AppColors.borderGrey),
          ),
          _buildReceiptRow(Icons.location_on, AppColors.ecoGreen, "To", ride.toLocation),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _buildParticipantInfo("Rider", ride.riderName ?? "N/A"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildParticipantInfo(
                  "Passenger",
                  ride.passengerName,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantInfo(
    String role,
    String name, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(role, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPassengerActions(RideModel ride) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: (_selectedRating == 0 || _isNavigating)
                ? null
                : () => _finishAndGoToRoleSelection(rating: _selectedRating),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: const Text('Submit & Finish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isNavigating ? null : () => _finishAndGoToRoleSelection(),
          child: const Text('Skip rating', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildRiderActions() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isNavigating ? null : () => _finishAndGoToRoleSelection(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: const Text('Done - Choose Next Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
