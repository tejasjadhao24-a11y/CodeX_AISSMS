import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String studentId;
  final String collegeName;
  final String avatarUrl;

  const ProfileCard({
    super.key,
    required this.name,
    required this.studentId,
    required this.collegeName,
    this.avatarUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Larger profile picture
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.white.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: AppColors.white,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 35,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      collegeName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: $studentId',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  // Small achievement badges
                  Row(
                    children: [
                      _buildBadge(
                        Icons.eco,
                        AppColors.ecoGreen,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        Icons.directions_car,
                        AppColors.accentBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, color: AppColors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms);
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 13,
          color: color,
        ),
      ),
    );
  }
}
