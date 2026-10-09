import 'package:flutter/material.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'package:campus_lift/widgets/primary_button.dart';
import 'package:campus_lift/services/ride_service.dart';
import 'package:campus_lift/screens/passenger/ride_booking_screen.dart';

class Driver {
  final String id;
  final String name;
  final String photoUrl;
  final String gender;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final double distance;
  final String eta;
  final String serviceArea;

  Driver({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.gender,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
    required this.distance,
    required this.eta,
    required this.serviceArea,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Student Driver',
      photoUrl: json['photoUrl'] ?? '',
      gender: json['gender'] ?? 'Not specified',
      vehicleType: json['vehicleType'] ?? 'Bike',
      vehicleNumber: json['vehicleNumber'] ?? 'N/A',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      distance: (json['distance'] as num?)?.toDouble() ?? 1.5,
      eta: json['eta'] ?? '5 mins',
      serviceArea: json['serviceArea'] ?? 'Campus',
    );
  }
}

class AvailableDriversScreen extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;

  const AvailableDriversScreen({
    super.key,
    this.pickupLat,
    this.pickupLng,
  });

  @override
  State<AvailableDriversScreen> createState() => _AvailableDriversScreenState();
}

class _AvailableDriversScreenState extends State<AvailableDriversScreen> {
  final RideService _rideService = RideService();
  List<Driver> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedGender = 'All'; // 'All', 'Female', 'Male'

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _rideService.getNearbyDrivers(
        lat: widget.pickupLat,
        lng: widget.pickupLng,
        radius: 15.0,
        gender: _selectedGender == 'All' ? null : _selectedGender,
      );

      if (mounted) {
        setState(() {
          _drivers = data.map((json) => Driver.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to search for nearby drivers. Please check your network connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Drivers Nearby',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!_isLoading)
                Text(
                  '${_drivers.length} found',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                const Text(
                  'Filter:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                _buildGenderChip('All', 'All Drivers'),
                const SizedBox(width: 8),
                _buildGenderChip('Female', 'Female Only'),
                const SizedBox(width: 8),
                _buildGenderChip('Male', 'Male Only'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String value, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        if (_selectedGender != value) {
          setState(() {
            _selectedGender = value;
          });
          _fetchDrivers();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Scanning campus for nearby verified drivers...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchDrivers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_drivers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchDrivers,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _selectedGender != 'All'
                        ? 'No ${_selectedGender.toLowerCase()} drivers nearby right now'
                        : 'No drivers nearby right now',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedGender != 'All'
                        ? 'Try changing the gender filter to "All Drivers" or check back in a few moments.'
                        : 'Drivers will appear here once verified student riders go online in your campus area.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _fetchDrivers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDrivers,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDriverCard(context, driver),
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, Driver driver) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info Row
            Row(
              children: [
                // Driver Photo
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Driver Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              driver.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ecoGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: AppColors.ecoGreen,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  driver.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppColors.ecoGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${driver.vehicleType} • ${driver.vehicleNumber}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (driver.gender != 'Not specified')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                driver.gender,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Distance and ETA Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.near_me_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${driver.distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ETA: ${driver.eta}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Action Button
            PrimaryButton(
              text: 'Request Ride',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RideBookingScreen(),
                  ),
                );
              },
              height: 44,
            ),
          ],
        ),
      ),
    );
  }
}
