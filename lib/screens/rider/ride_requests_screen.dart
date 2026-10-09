import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/core/providers/ride_provider.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import '../../models/ride_model.dart';

class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRides();
      _startPolling();
    });
  }

  void _loadRides() {
    if (!mounted) return;
    context.read<RideProvider>().fetchPendingRides();
  }

  void _startPolling() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const CampusLiftLogo(size: 24, showTagline: false),
      ),
      body: Consumer<RideProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingRides.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.pendingRides.isEmpty) {
            return const Center(child: Text('No new requests'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: provider.pendingRides.length,
            itemBuilder: (context, index) {
              final ride = provider.pendingRides[index];
              return _RideRequestCardItem(ride: ride, index: index);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RideRequestCardItem — StatefulWidget so each card owns its loading state
// ---------------------------------------------------------------------------
class _RideRequestCardItem extends StatefulWidget {
  final RideModel ride;
  final int index;
  const _RideRequestCardItem({required this.ride, required this.index});

  @override
  State<_RideRequestCardItem> createState() => _RideRequestCardItemState();
}

class _RideRequestCardItemState extends State<_RideRequestCardItem> {
  bool _isAccepting = false;
  bool _isNavigating = false;

  Future<void> _onAccept() async {
    if (_isAccepting || _isNavigating) return;
    setState(() => _isAccepting = true);
    
    try {
      final success = await context.read<RideProvider>().acceptRide(widget.ride.id);
      
      if (!mounted) return;
      
      if (success) {
        _isNavigating = true;
        Navigator.pushNamed(context, '/active-ride').then((_) {
          if (mounted) _isNavigating = false;
        });
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(ride.passengerName,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold))),
              Text('+${ride.pointsAwarded} pts',
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
              Icons.radio_button_checked, AppColors.primary, ride.fromLocation),
          _buildLocationRow(
              Icons.location_on, AppColors.secondary, ride.toLocation),
          const SizedBox(height: 20),
          if (_isAccepting)
            const SizedBox(
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _onAccept,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => rideProvider.declineRide(ride.id),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(delay: (widget.index * 100).ms);
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
