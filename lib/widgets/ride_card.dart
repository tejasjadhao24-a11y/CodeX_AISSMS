import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class RideCard extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String price;
  final String eta;

  const RideCard({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.price,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [Colors.white, AppColors.primary.withValues(alpha: 0.01)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                const BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.shadowMedium.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Small illustration on left
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ride Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        eta,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLocationRow(
                  icon: Icons.my_location,
                  iconColor: AppColors.secondary,
                  title: 'Pickup',
                  subtitle: pickupLocation,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
                  child: Container(
                    width: 2,
                    height: 20,
                    color: AppColors.borderGrey,
                  ),
                ),
                _buildLocationRow(
                  icon: Icons.location_on,
                  iconColor: AppColors.primary,
                  title: 'Drop-off',
                  subtitle: dropoffLocation,
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderGrey),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Fare',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Arrow indicator on right
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
