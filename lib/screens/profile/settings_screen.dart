import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../services/api_service.dart';
import 'personal_info_screen.dart';
import 'college_info_screen.dart';
import 'vehicle_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changeTheme(BuildContext context, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme set to ${mode.toUpperCase()}! Restart to apply changes.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_outlined, color: Colors.orange),
              title: const Text('Light Theme'),
              onTap: () {
                Navigator.pop(context);
                _changeTheme(context, 'light');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: Colors.indigo),
              title: const Text('Dark Theme'),
              onTap: () {
                Navigator.pop(context);
                _changeTheme(context, 'dark');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.grey),
              title: const Text('System Default'),
              onTap: () {
                Navigator.pop(context);
                _changeTheme(context, 'system');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Data Security', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your data is encrypted and never shared with third parties. Your location is only tracked during active rides.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Help Center & FAQs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              _buildFaqItem('How do I request a ride?', 'Go to the Passenger Home Screen, select your pick-up and drop-off locations, choose from the available driver listings, and request a ride. Keep an eye on your screen for driver acceptance.'),
              _buildFaqItem('How do I earn points?', 'You earn eco-points by offering rides as a rider to campus peers. Points are calculated based on travel distance and successful passenger carpooling.'),
              _buildFaqItem('How do I download my achievement certificates?', 'Go to your Profile tab, and tap "View Certificate". Once earned, you can preview, download, or share your CampusLift eco-friendly certificate as a PDF.'),
              _buildFaqItem('How does the SOS emergency feature work?', 'If you ever feel unsafe during a ride, tap the SOS/Emergency button on the active ride screen. This instantly triggers local alerts and shows emergency contacts.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String? issueType = 'App Bug';
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: issueType,
                        items: const [
                          DropdownMenuItem(value: 'App Bug', child: Text('App Bug')),
                          DropdownMenuItem(value: 'Ride Issue', child: Text('Ride Issue')),
                          DropdownMenuItem(value: 'Account Issue', child: Text('Account Issue')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            issueType = val;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Issue Type',
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: descController,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please describe the issue';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          hintText: 'Please detail what went wrong...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      
                      try {
                        final apiService = ApiService();
                        await apiService.post('/support/report', {
                          'issueType': issueType,
                          'description': descController.text.trim(),
                        });
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Issue reported! We'll respond within 24 hours."),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit issue: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContactUsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.email_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Text('support@campuslift.com', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.phone_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Text('+91 20 2420 2123', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Support Hours: 9 AM - 6 PM', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'support@campuslift.com'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support email copied to clipboard!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text(
                  'Copy Support Email',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScrollableTextSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      body,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('App Version Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CampusLift v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Build: 2026.05.19.01'),
            Text('Platform: Flutter Hybrid Client'),
            Text('Affiliation: VIT Pune, Campus Mobility initiative'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader(context, 'Account'),
            _buildSettingItem(
              context,
              'Personal Information',
              'Update your profile details',
              Icons.person_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
                );
              },
            ),
            _buildSettingItem(
              context,
              'College Information',
              'Update your college details',
              Icons.school_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CollegeInfoScreen()),
                );
              },
            ),
            _buildSettingItem(
              context,
              'Vehicle Information',
              'Manage your vehicle details',
              Icons.directions_car_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VehicleInfoScreen()),
                );
              },
            ),
            const SizedBox(height: 32),

            // Preferences Section
            _buildSectionHeader(context, 'Preferences'),
            _buildSwitchItem(
              context,
              'Notifications',
              'Receive ride updates and alerts',
              Icons.notifications_outlined,
              userProvider.notificationsEnabled,
              (value) => userProvider.setNotificationsEnabled(value),
            ),
            _buildSwitchItem(
              context,
              'Location Services',
              'Allow location access for rides',
              Icons.location_on_outlined,
              userProvider.locationEnabled,
              (value) => userProvider.setLocationEnabled(value),
            ),
            _buildSettingItem(
              context,
              'Theme',
              'Choose your preferred theme',
              Icons.palette_outlined,
              () => _showThemeDialog(context),
            ),
            const SizedBox(height: 32),

            // Safety Section
            _buildSectionHeader(context, 'Safety & Privacy'),
            _buildSettingItem(
              context,
              'Privacy Settings',
              'Manage your privacy preferences',
              Icons.privacy_tip_outlined,
              () => _showPrivacyDialog(context),
            ),
            _buildSettingItem(
              context,
              'Emergency Contacts',
              'Add emergency contact numbers',
              Icons.emergency_outlined,
              () => Navigator.pushNamed(context, '/emergency-contacts'),
            ),
            const SizedBox(height: 32),

            // Support Section
            _buildSectionHeader(context, 'Support'),
            _buildSettingItem(
              context,
              'Help Center',
              'Get help and support',
              Icons.help_outline,
              () => _showHelpCenterSheet(context),
            ),
            _buildSettingItem(
              context,
              'Report Issue',
              'Report a problem or bug',
              Icons.bug_report_outlined,
              () => _showReportIssueDialog(context),
            ),
            _buildSettingItem(
              context,
              'Contact Us',
              'Get in touch with our team',
              Icons.contact_support_outlined,
              () => _showContactUsSheet(context),
            ),
            const SizedBox(height: 32),

            // About Section
            _buildSectionHeader(context, 'About'),
            _buildSettingItem(
              context,
              'Terms of Service',
              'Read our terms and conditions',
              Icons.description_outlined,
              () => _showScrollableTextSheet(
                context,
                'Terms of Service',
                'Welcome to CampusLift. By using our application, you agree to comply with the terms set forth here. CampusLift is designed exclusively for carpooling and travel sharing among students and staff of Vishwakarma Institute of Technology, Pune (VIT Pune). All users must act responsibly and adhere to traffic safety laws. We are not liable for any issues arising during travel. Points earned are non-monetary and are used solely inside the app for rewards, recognition, and achievement certificates. Any misuse, spamming of requests, or behavioral misconduct will result in account suspension or termination from the platform.',
              ),
            ),
            _buildSettingItem(
              context,
              'Privacy Policy',
              'Learn about our privacy practices',
              Icons.policy_outlined,
              () => _showScrollableTextSheet(
                context,
                'Privacy Policy',
                'At CampusLift, we prioritize student privacy and data integrity. All personal, college, and vehicle data you submit is securely stored and encrypted. We do not sell or share your data with any third-party marketing networks or external entities. Location data is accessed solely during active rides to map travel and display nearby drivers, and is never tracked in the background when the app is closed. By using CampusLift, you consent to the secure collection of profile information required for role verification and student identification.',
              ),
            ),
            _buildSettingItem(
              context,
              'App Version',
              'CampusLift v1.0.0',
              Icons.info_outline,
              () => _showAppVersionDialog(context),
            ),
            const SizedBox(height: 40),

            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.1, end: 0.0, duration: 400.ms);
  }

  Widget _buildSwitchItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          activeThumbColor: AppColors.primary,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.1, end: 0.0, duration: 400.ms);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access your account.',
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
              await Provider.of<UserProvider>(context, listen: false).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
