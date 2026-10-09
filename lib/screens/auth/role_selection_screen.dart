import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/campus_lift_logo.dart';

import 'license_verification_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: CampusLiftLogo(
                  size: 32,
                  showTagline: false,
                ),
              ),
              const SizedBox(height: 32),
              // Header
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 12),
              Text(
                'Select how you want to use CampusLift',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 250.ms, delay: 60.ms),
              const SizedBox(height: 30),

              // Rider Option
              _buildRoleCard(
                context,
                'Become a Rider',
                'Earn money by providing rides to fellow students',
                'Continue as Rider',
                AppColors.primary,
                () => _selectRole(context, 'rider'),
              ).animate().fadeIn(duration: 280.ms, delay: 120.ms).slideY(
                begin: 0.1,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),

              const SizedBox(height: 20),

              // Passenger Option
              _buildRoleCard(
                context,
                'Ride as Passenger',
                'Get affordable and sustainable rides on campus',
                'Continue as Passenger',
                AppColors.secondary,
                () => _selectRole(context, 'passenger'),
              ).animate().fadeIn(duration: 280.ms, delay: 180.ms).slideY(
                begin: 0.1,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),

              const SizedBox(height: 30),
              // Footer
              Text(
                'You can change your role later in settings',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 250.ms, delay: 240.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String title,
    String description,
    String buttonText,
    Color accentColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              title.contains('Rider') ? Icons.drive_eta : Icons.person,
              size: 35,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: buttonText,
              onPressed: onPressed,
              backgroundColor: accentColor,
              height: 52,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRole(BuildContext context, String role) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateRole(role);

    if (context.mounted) {
      if (role == 'rider') {
        final status = userProvider.currentUser?.verificationStatus ?? 'unverified';
        Navigator.of(context).pushNamedAndRemoveUntil('/rider-dashboard', (route) => false);
        if (status != 'approved') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LicenseVerificationScreen()),
          );
        }
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/passenger-home', (route) => false);
      }
    }
  }
}
