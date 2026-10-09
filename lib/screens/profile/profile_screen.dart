import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/primary_button.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import '../rider/main_rider_screen.dart';
import '../passenger/main_passenger_screen.dart';
import 'settings_screen.dart';
import '../../services/api_service.dart';
import '../passenger/my_rides_screen.dart';
import '../../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalRides = 0;
  double _avgRating = 0.0;
  int _ecoScore = 0;
  Map? _certificate;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = ApiService();
      final response = await api.get('/users/profile-stats');
      if (mounted) {
        setState(() {
          _totalRides = response['totalRides'] ?? 0;
          _avgRating = (response['avgRating'] ?? 0.0).toDouble();
          _ecoScore = response['ecoScore'] ?? 0;
          _certificate = response['certificate'];
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
  }

  Future<void> _showAvatarSourceSheet() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hasCustomPhoto = userProvider.avatarUrl != null && userProvider.avatarUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              if (hasCustomPhoto)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.alertRed),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.alertRed),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmAndRemoveAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndRemoveAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Photo?'),
        content: const Text('Are you sure you want to remove your profile photo? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _removeAvatar();
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final api = ApiService();
      await api.delete('/users/profile/avatar');

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clearAvatar();
        await userProvider.loadUser();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final bytes = await picked.readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final api = ApiService();
      final res = await api.post('/users/profile/avatar', {
        'avatar_base64': b64,
      });

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final newUrl = res != null && res is Map ? (res['avatarUrl'] ?? res['avatar_url']) : null;
        if (newUrl != null) {
          Provider.of<UserProvider>(context, listen: false).updateAvatar(newUrl);
        }
        await Provider.of<UserProvider>(context, listen: false).loadUser();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.ecoGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar with edit badge
            GestureDetector(
              onTap: _isUploadingAvatar ? null : _showAvatarSourceSheet,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (userProvider.avatarUrl == null || userProvider.avatarUrl!.isEmpty)
                          ? AppColors.primaryGradient
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploadingAvatar
                          ? Container(
                              color: Colors.black26,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            )
                          : (userProvider.avatarUrl != null && userProvider.avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  AppConfig.resolveUrl(userProvider.avatarUrl!),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.person, size: 60, color: Colors.white),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(Icons.person, size: 60, color: Colors.white),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scaleXY(begin: 0.8, end: 1.0, duration: 400.ms),
            const SizedBox(height: 16),
            // Name and College
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userProvider.userName ?? 'User Name',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_certificate != null && _certificate!['level'] > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(_certificate!['color'].replaceFirst('#', 'FF'), radix: 16)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 4),
            Text(
              userProvider.collegeName ?? (userProvider.isRider ? userProvider.serviceArea ?? 'Service Area' : 'College Name'),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (userProvider.isPassenger || userProvider.prn != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PRN: ${userProvider.prn ?? 'Not set'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (userProvider.isRider)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${userProvider.vehicleType ?? 'Vehicle'} • ${userProvider.vehicleNumber ?? 'No Info'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (userProvider.isPassenger)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${userProvider.course ?? 'Course'} • Year ${userProvider.yearOfStudy ?? '1'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            // Stats Cards
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
                    'Eco Score',
                    '$_ecoScore',
                    Icons.eco,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              'Rating',
              _avgRating.toStringAsFixed(1),
              Icons.star,
              AppColors.accentBlue,
              isFullWidth: true,
            ),
            const SizedBox(height: 40),
            // Menu List
            _buildMenuItem(
              context,
              'Ride History',
              'View all your completed rides',
              Icons.history,
              () {
                final userRole = context.read<UserProvider>().currentUser?.role ?? 'passenger';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MyRidesScreen(role: userRole),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              'Certificates',
              'Download ride certificates',
              Icons.card_membership,
              () {
                Navigator.pushNamed(context, '/certificates');
              },
            ),
            _buildMenuItem(
              context,
              'Settings',
              'Manage account preferences',
              Icons.settings,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              'Help',
              'Get help and support',
              Icons.help_outline,
              () {},
            ),
            const SizedBox(height: 20),
            // Role Switcher (only show if user wants to change role)
            if (userProvider.hasSelectedRole)
              Container(
                width: double.infinity,
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
                child: Column(
                  children: [
                    Text(
                      'Current Role: ${userProvider.isRider ? 'Rider' : 'Passenger'}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'Switch Role',
                      onPressed: () => _showRoleSwitchDialog(context),
                      backgroundColor: AppColors.accentBlue,
                      height: 48,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            // App Version
            const CampusLiftLogo(
              size: 20,
              showTagline: true,
              showIcon: false,
            ),
            const SizedBox(height: 8),
            Text(
              'v1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
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
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0.0, duration: 400.ms);
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
            onTap: onTap,
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideX(begin: -0.1, end: 0.0, duration: 400.ms);
  }

  void _showRoleSwitchDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Switch Role'),
        content: const Text(
          'Are you sure you want to switch your role? This will change your app experience.',
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
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                await userProvider.switchRole();
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // Dismiss loading
                  Navigator.of(context).pop(); // Dismiss switch dialog
                  
                  // Navigation will be handled by AuthWrapper in main.dart 
                  // but we can also push manually for immediate feel
                  if (userProvider.isRider) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainRiderScreen()),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainPassengerScreen()),
                      (route) => false,
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Dismiss loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error switching role: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Switch Role'),
          ),
        ],
      ),
    );
  }
}
