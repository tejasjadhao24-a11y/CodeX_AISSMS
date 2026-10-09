import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import '../../services/sos_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/ride_provider.dart';
import '../../services/mock_mode.dart';

import '../../services/emergency_contact_service.dart';
import '../../services/api_service.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _dynamicEmergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
  }

  Future<void> _fetchEmergencyContacts() async {
    try {
      final res = await ApiService().get('/users/trusted-contacts');
      if (res is Map && res['contacts'] is List) {
        final all = List<Map<String, dynamic>>.from(res['contacts'] as List);
        final filtered = all.where((c) {
          final cat = (c['category'] ?? '').toString().toLowerCase();
          return cat == 'security' || cat == 'health' || cat == 'emergency' || cat == 'police';
        }).toList();
        if (mounted && filtered.isNotEmpty) {
          setState(() {
            _dynamicEmergencyContacts = filtered;
          });
        }
      }
    } catch (_) {}
  }

  void _confirmStopSharing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Live Location Sharing?'),
        content: const Text(
          'Are you sure you want to stop sharing your live location with campus security and admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SOSService().stopLiveLocationSharing();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live emergency location sharing stopped.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persistent Live Location Sharing Banner (Task 8)
                ValueListenableBuilder<bool>(
                  valueListenable: SOSService.isSharingLiveLocation,
                  builder: (context, isSharing, _) {
                    if (!isSharing) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.alertRed,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.alertRed.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.share_location, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sharing live location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Campus security and admin are tracking live',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _confirmStopSharing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.alertRed,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Stop',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // SOS Emergency Button - Prominent with glow
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.alertRed.withValues(alpha: 0.2),
                        AppColors.alertRed.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.alertRed.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.alertRed.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        _showEmergencyDialog(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.alertRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.alertRed.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.emergency,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'EMERGENCY SOS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.alertRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to alert emergency contacts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.alertRed,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scaleXY(begin: 0.95, end: 1.0, duration: 400.ms),

                const SizedBox(height: 32),

                // Safety Features
                Text(
                  'Safety Features',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                const SizedBox(height: 16),

                _buildSafetyFeature(
                  context,
                  'Share Ride Details',
                  'Automatically share your location with emergency contacts',
                  Icons.share_location,
                  AppColors.primary,
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                _buildSafetyFeature(
                  context,
                  'Verified Drivers',
                  'All drivers undergo background verification',
                  Icons.verified_user,
                  AppColors.secondary,
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                _buildSafetyFeature(
                  context,
                  '24/7 Support',
                  'Round-the-clock customer support available',
                  Icons.support_agent,
                  AppColors.accentBlue,
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                const SizedBox(height: 32),

                // Emergency Contacts
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                const SizedBox(height: 16),

                if (_dynamicEmergencyContacts.isNotEmpty)
                  ..._dynamicEmergencyContacts.map((c) {
                    final name = c['name']?.toString() ?? 'Emergency Contact';
                    final phone = c['phone']?.toString() ?? '112';
                    final cat = (c['category'] ?? '').toString().toLowerCase();
                    IconData icon = Icons.security;
                    Color color = AppColors.primary;
                    if (cat == 'health') {
                      icon = Icons.medical_services;
                      color = AppColors.secondary;
                    } else if (cat == 'emergency' || cat == 'police') {
                      icon = Icons.local_hospital;
                      color = AppColors.alertRed;
                    }
                    return _buildEmergencyContact(context, name, phone, icon, color);
                  })
                else ...[
                  _buildEmergencyContact(
                    context,
                    'Campus Security',
                    '+91 98765 43210',
                    Icons.security,
                    AppColors.primary,
                  ).animate().fadeIn(duration: 500.ms, delay: 700.ms),

                  _buildEmergencyContact(
                    context,
                    'Emergency Services',
                    '112',
                    Icons.local_hospital,
                    AppColors.alertRed,
                  ).animate().fadeIn(duration: 500.ms, delay: 800.ms),

                  _buildEmergencyContact(
                    context,
                    'Campus Health Center',
                    '+91 98765 43211',
                    Icons.medical_services,
                    AppColors.secondary,
                  ).animate().fadeIn(duration: 500.ms, delay: 900.ms),
                ],

                const SizedBox(height: 32),

                // Safety Tips
                Text(
                  'Safety Tips',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 1000.ms),

                const SizedBox(height: 16),

                _buildSafetyTip(
                  context,
                  'Always share your ride details with a trusted contact',
                  Icons.info_outline,
                ).animate().fadeIn(duration: 500.ms, delay: 1100.ms),

                _buildSafetyTip(
                  context,
                  'Verify your driver\'s identity before starting the ride',
                  Icons.verified,
                ).animate().fadeIn(duration: 500.ms, delay: 1200.ms),

                _buildSafetyTip(
                  context,
                  'Keep emergency contacts updated in your profile',
                  Icons.contact_phone,
                ).animate().fadeIn(duration: 500.ms, delay: 1300.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.alertRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSafetyFeature(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            child: Icon(icon, color: color, size: 24),
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
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(
    BuildContext context,
    String name,
    String number,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  number,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.call, color: color, size: 24),
            onPressed: () async {
               final sosService = SOSService();
               await sosService.callEmergency();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(BuildContext context, String tip, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.emergency, color: AppColors.alertRed, size: 28),
            const SizedBox(width: 12),
            Text(
              'Emergency Alert',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.alertRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to your emergency contacts with your current location. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final contactService = EmergencyContactService();
              final numbers = await contactService.getPhoneNumbers();
              if (!context.mounted) return;

              if (numbers.isEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('No Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text(
                      'Please add emergency contacts first.\n'
                      'Go to Settings → Emergency Contacts',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/emergency-contacts');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add Now'),
                      ),
                    ],
                  ),
                );
                return;
              }

              if (kMockMode) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚨 Mock SOS Alert Sent!'),
                    backgroundColor: AppColors.alertRed,
                    behavior: SnackBarBehavior.floating,
                  )
                );
                return;
              }

              setState(() => _isLoading = true);
              try {
                if (!context.mounted) return;
                final sosService = SOSService();
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final rideProvider = Provider.of<RideProvider>(context, listen: false);

                await sosService.triggerSOS(
                  userName: userProvider.currentUser?.name ?? 'Unknown',
                  userId: userProvider.currentUser?.id ?? '',
                  rideId: rideProvider.activeRide?.id,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚨 SOS Alert Sent! Help is on the way.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  )
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('SOS Error: $e'))
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}
