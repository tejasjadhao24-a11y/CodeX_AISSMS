import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ride_provider.dart';
import '../../models/ride_model.dart';
import '../../widgets/ride_map_widget.dart';
import '../../services/mock_mode.dart';

class PassengerActiveRideScreen extends StatefulWidget {
  const PassengerActiveRideScreen({super.key});

  @override
  State<PassengerActiveRideScreen> createState() => _PassengerActiveRideScreenState();
}

class _PassengerActiveRideScreenState extends State<PassengerActiveRideScreen> {
  LatLng? _riderLocation;
  late LatLng _pickupLocation;
  late LatLng _dropLocation;
  Timer? _mockTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final ride = rideProvider.activeRide;

    // Set pickup/drop from activeRide coords or VIT defaults
    if (ride != null) {
      _pickupLocation = LatLng(ride.fromLat, ride.fromLng);
    } else {
      _pickupLocation = const LatLng(18.4624, 73.8670);
    }

    if (ride != null) {
      _dropLocation = LatLng(ride.toLat, ride.toLng);
    } else {
      _dropLocation = const LatLng(18.4700, 73.8750);
    }

    // Join ride room and listen for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
      if (ride != null) {
        // Fix 3.7: Mock movement simulation
        if (kMockMode) {
          _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
            if (mounted) {
              setState(() {
                _riderLocation = LatLng(
                  (_riderLocation?.latitude ?? _pickupLocation.latitude) + 0.0001,
                  (_riderLocation?.longitude ?? _pickupLocation.longitude) + 0.0001,
                );
              });
            }
          });
        }
      }
    });
  }

  bool _hasNavigated = false;
  int _nullCount = 0; // Grace period counter

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _hasNavigated) return;
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      await rideProvider.fetchActiveRide();
      
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;
    
    final provider = context.read<RideProvider>();
    final active = provider.activeRide;
    final last = provider.lastCompletedRide;
    
    // Ride completed — navigate to rating screen
    if (last != null) {
      _hasNavigated = true;
      _pollTimer?.cancel();
      Navigator.pushReplacementNamed(context, '/ride-completed');
      return;
    }
    
    // Ride disappeared — use grace period (2 polls = 6 seconds)
    // to avoid race condition between socket and polling
    if (active == null) {
      _nullCount++;
      if (_nullCount >= 2) {
        _hasNavigated = true;
        _pollTimer?.cancel();
        Navigator.pushNamedAndRemoveUntil(context, '/passenger-home', (route) => false);
      }
    } else {
      _nullCount = 0; // Reset if ride reappears
    }
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String _calculateETA([LatLng? loc]) {
    final location = loc ?? _riderLocation;
    if (location == null) return "Calculating...";
    
    // Simple distance calculation (Haversine)
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((_pickupLocation.latitude - location.latitude) * p) / 2 +
              math.cos(location.latitude * p) * math.cos(_pickupLocation.latitude * p) *
              (1 - math.cos((_pickupLocation.longitude - location.longitude) * p)) / 2;
    final distance = 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
    
    // Assuming 30 km/h average speed
    final minutes = (distance / 30 * 60).round();
    return minutes <= 1 ? "Arriving now" : "Arriving in ~$minutes mins";
  }

  Future<void> _callRider(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rider phone number is not available')),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, child) {
        final ride = rideProvider.activeRide;
        
        if (rideProvider.state == RideState.completed) {
          if (!_hasNavigated) {
            _hasNavigated = true;
            _pollTimer?.cancel();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/ride-completed');
            });
          }
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text("Arrived! Preparing your summary...", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        if (ride == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Connecting to ride...')),
          );
        }

        final effectiveRiderLocation = (ride.currentLat != null && ride.currentLng != null)
            ? LatLng(ride.currentLat!, ride.currentLng!)
            : _riderLocation;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Ride', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                flex: 1,
                child: RideMapWidget(
                  isRider: false,
                  riderLocation: effectiveRiderLocation,
                  pickupLocation: _pickupLocation,
                  dropLocation: _dropLocation,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
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
                          child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.riderName ?? 'Rider',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                               ),
                               Text(
                                 ride.status == RideStatus.accepted 
                                   ? '🚗 Rider is on the way' 
                                   : '✅ Ride in Progress',
                                 style: TextStyle(
                                   color: ride.status == RideStatus.accepted 
                                     ? Colors.orange 
                                     : Colors.green,
                                   fontWeight: FontWeight.w600,
                                   fontSize: 14,
                                 ),
                               ),
                            ],
                          ),
                        ),
                        if (ride.status == RideStatus.accepted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _calculateETA(effectiveRiderLocation),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride.fromLocation,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride.toLocation,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _callRider(ride.riderPhone),
                        icon: const Icon(Icons.call),
                        label: const Text('Call Rider'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          final rideProvider = Provider.of<RideProvider>(context, listen: false);
                          await rideProvider.cancelRide(ride.id);
                          if (mounted) {
                            nav.pushNamedAndRemoveUntil('/passenger-home', (route) => false);
                          }
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel Ride'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
}
