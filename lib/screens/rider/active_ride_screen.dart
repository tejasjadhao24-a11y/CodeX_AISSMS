import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ride_provider.dart';
import '../../services/location_service.dart';
import '../../models/ride_model.dart';
import '../../widgets/ride_map_widget.dart';
import '../../config/app_config.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  bool _isLoading = false;
  LatLng? _riderLocation;
  LatLng _pickupLocation = const LatLng(18.4624, 73.8670);
  LatLng _dropLocation = const LatLng(18.4700, 73.8750);
  final LocationService _locationService = LocationService();
  bool _hasNavigated = false;
  Timer? _fallbackSyncTimer;

  @override
  void initState() {
    super.initState();
    _initRide();
    // Fallback sync every 20 seconds as a safety net behind socket coverage
    _fallbackSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        final rideProvider = Provider.of<RideProvider>(context, listen: false);
        if (rideProvider.activeRide != null) {
          rideProvider.syncWithServer();
        }
      }
    });
  }

  Future<void> _initRide() async {
    setState(() => _isLoading = true);
    try {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      await rideProvider.syncWithServer();
      
      if (!mounted) return;
      final ride = rideProvider.activeRide;
      if (ride == null && rideProvider.state != RideState.completed) {
        Navigator.pushNamedAndRemoveUntil(context, '/rider-dashboard', (route) => false);
        return;
      }

      if (ride != null) {
        _pickupLocation = LatLng(ride.fromLat, ride.fromLng);
        _dropLocation = LatLng(ride.toLat, ride.toLng);
      }
      
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _riderLocation = LatLng(pos.latitude, pos.longitude);
        });
        if (ride != null) {
          rideProvider.updateLocation(ride.id, pos.latitude, pos.longitude);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fallbackSyncTimer?.cancel();
    _locationService.stopSendingLocation();
    super.dispose();
  }

  Future<void> _handleStartRide() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final ride = rideProvider.activeRide;
    if (ride == null) return;

    await rideProvider.startRide(ride.id);
  }

  Future<void> _handleCompleteRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Ride?'),
        content: const Text('Are you sure the ride has ended and you want to mark it complete?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.ecoGreen),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final ride = rideProvider.activeRide;
    if (ride == null) return;

    setState(() => _isLoading = true);
    try {
      await rideProvider.completeRide(ride.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, child) {
        final ride = rideProvider.activeRide;
        
        if (rideProvider.state == RideState.completed) {
          if (!_hasNavigated) {
            _hasNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/ride-completed');
            });
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (ride == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Connecting to ride...')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Map Section
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    RideMapWidget(
                      isRider: true,
                      riderLocation: _riderLocation,
                      pickupLocation: _pickupLocation,
                      dropLocation: _dropLocation,
                    ),
                    Positioned(
                      top: 40,
                      left: 20,
                      child: SafeArea(
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Ride Details Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: (ride.passengerPhoto != null && ride.passengerPhoto!.isNotEmpty)
                              ? NetworkImage(AppConfig.resolveUrl(ride.passengerPhoto!))
                              : null,
                          child: (ride.passengerPhoto == null || ride.passengerPhoto!.isEmpty)
                              ? const Icon(Icons.person, color: AppColors.primary, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.passengerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ride.status == RideStatus.accepted
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : AppColors.ecoGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ride.status == RideStatus.accepted
                                      ? 'Waiting for Pickup'
                                      : 'In Transit',
                                  style: TextStyle(
                                    color: ride.status == RideStatus.accepted
                                        ? Colors.orange.shade800
                                        : AppColors.ecoGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _callPassenger(ride.passengerPhone),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: AppColors.primary, size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _messagePassenger(ride.passengerPhone),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.message, color: AppColors.secondary, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLocationItem(Icons.radio_button_checked, 'Pickup', ride.fromLocation, AppColors.primary),
                    const SizedBox(height: 16),
                    _buildLocationItem(Icons.location_on, 'Dropoff', ride.toLocation, AppColors.secondary),
                    const SizedBox(height: 32),
                    if (ride.status == RideStatus.accepted)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleStartRide,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Start Ride',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else if (ride.status == RideStatus.inProgress)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleCompleteRide,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Complete Ride',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _callPassenger(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger phone number is not available')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call: $e')),
        );
      }
    }
  }

  Future<void> _messagePassenger(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger phone number is not available')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('sms:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open messaging: $e')),
        );
      }
    }
  }
}

