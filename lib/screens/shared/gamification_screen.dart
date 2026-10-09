import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Campus Points',
                    '2,450',
                    Icons.star,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Eco Score',
                    '842',
                    Icons.eco,
                    AppColors.ecoGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Rides',
                    '24',
                    Icons.directions_car,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'COâ‚‚ Saved',
                    '19.2 kg',
                    Icons.eco,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Achievements Section
            Text(
              'Your Achievements',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Achievement 1: Green Rider
            _buildAchievementCard(
              context,
              'Green Rider',
              'Completed 10 eco rides',
              Icons.eco,
              AppColors.ecoGreen,
              100.0,
            ),
            const SizedBox(height: 12),
            // Achievement 2: Safe Driver
            _buildAchievementCard(
              context,
              'Safe Driver',
              'Completed 15 safe rides with 5â˜… ratings',
              Icons.verified,
              AppColors.primary,
              80.0,
            ),
            const SizedBox(height: 12),
            // Achievement 3: Community Helper
            _buildAchievementCard(
              context,
              'Community Helper',
              'Shared trips with 20 different people',
              Icons.people,
              Colors.purple,
              60.0,
            ),
            const SizedBox(height: 12),
            // Achievement 4: Night Owl
            _buildAchievementCard(
              context,
              'Night Owl',
              'Completed 5 late night rides safely',
              Icons.nights_stay,
              Colors.indigo,
              40.0,
            ),
            const SizedBox(height: 32),
            // Progress Section
            Text(
              'Current Progress',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Eco Score Progress
            _buildProgressCard(
              context,
              'Eco Score Progress',
              842,
              1000,
              AppColors.ecoGreen,
              'Reach 1000 points for next tier',
            ),
            const SizedBox(height: 16),
            // Campus Points Progress
            _buildProgressCard(
              context,
              'Campus Points Progress',
              2450,
              5000,
              AppColors.primary,
              'Reach 5000 points for rewards',
            ),
            const SizedBox(height: 32),
            // Badges Section
            Text(
              'Unlocked Badges',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildBadge(context, 'ðŸŒ±', 'Starter', 'First ride completed'),
                _buildBadge(context, 'â­', '5â˜… Driver', 'Got 5â˜… rating'),
                _buildBadge(context, 'â™»ï¸', 'Eco Hero', 'Saved 10kg COâ‚‚'),
                _buildBadge(
                  context,
                  'ðŸš€',
                  'Speed Racer',
                  'Completed 5 rides in a day',
                ),
                _buildBadge(
                  context,
                  'ðŸ¤',
                  'Social Butterfly',
                  'Shared 5 trips',
                ),
                _buildBadge(
                  context,
                  'ðŸ’š',
                  'Green Guardian',
                  'Preferred eco rides',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: 0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Campus badge style
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 30,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Animated progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.borderGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 2.seconds,
                          color: color.withValues(alpha: 0.3),
                        ),
              ),
              const SizedBox(height: 6),
              Text(
                '${progress.toInt()}% Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    int current,
    int target,
    Color color,
    String subtitle,
  ) {
    double progress = (current / target).clamp(0.0, 1.0);

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: 0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$current / $target',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Animated progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: AppColors.borderGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 2.seconds,
                          color: color.withValues(alpha: 0.3),
                        ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  Widget _buildBadge(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
  ) {
    return Container(
          width: (MediaQuery.of(context).size.width - 60) / 3,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.primary.withValues(alpha: 0.01)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Collectible badge visual
              Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scaleXY(
                    begin: 1.0,
                    end: 1.1,
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.1,
                    end: 1.0,
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}
