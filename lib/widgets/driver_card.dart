import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class DriverCard extends StatelessWidget {
  final String driverName;
  final String vehicleInfo;
  final double rating;
  final String avatarUrl;

  const DriverCard({
    super.key,
    required this.driverName,
    required this.vehicleInfo,
    required this.rating,
    this.avatarUrl = '',
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
                colors: [Colors.white, AppColors.ecoGreen.withValues(alpha: 0.01)],
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
            child: Row(
              children: [
                // Circular driver photo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.borderGrey,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 28,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Vehicle icon
                          const Icon(
                            Icons.directions_car,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vehicleInfo,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Rating stars
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : index < rating
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Small car illustration
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.ecoGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 24,
                      color: AppColors.ecoGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}
