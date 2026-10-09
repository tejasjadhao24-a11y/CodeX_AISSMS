import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'package:campus_lift/core/providers/community_service_provider.dart';
import 'package:campus_lift/models/community_service_model.dart';
import 'shuttle_schedule_screen.dart';
import 'trusted_contacts_screen.dart';
class CommunityServicesScreen extends StatelessWidget {
  const CommunityServicesScreen({super.key});

  void _handleServiceAction(BuildContext context, CommunityServiceModel service) {
    switch (service.type) {
      case CommunityServiceType.shuttle:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShuttleScheduleScreen()),
        );
        break;
      case CommunityServiceType.auto:
      case CommunityServiceType.taxi:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrustedContactsScreen(
              serviceType: service.type,
              serviceName: service.name,
            ),
          ),
        );
        break;
      case CommunityServiceType.bike:
        Navigator.pushNamed(context, '/bike-rental');
        break;
    }
  }

  IconData _getServiceIcon(CommunityServiceType type) {
    switch (type) {
      case CommunityServiceType.shuttle:
        return Icons.directions_bus;
      case CommunityServiceType.auto:
        return Icons.local_taxi;
      case CommunityServiceType.taxi:
        return Icons.directions_car;
      case CommunityServiceType.bike:
        return Icons.pedal_bike;
    }
  }

  Color _getServiceColor(CommunityServiceType type) {
    switch (type) {
      case CommunityServiceType.shuttle:
        return Colors.blue;
      case CommunityServiceType.auto:
        return Colors.orange;
      case CommunityServiceType.taxi:
        return AppColors.primary;
      case CommunityServiceType.bike:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<CommunityServiceProvider>().services;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Services',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verified local transport options for your campus.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ...services.map((service) => _buildServiceCard(
                  context,
                  service,
                )),
          ],
        ),
      ),
    );
  }


  Widget _buildServiceCard(
    BuildContext context,
    CommunityServiceModel service,
  ) {
    final icon = _getServiceIcon(service.type);
    final color = _getServiceColor(service.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.phoneNumber ?? service.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                service.status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (service.type == CommunityServiceType.shuttle)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Schedule coming soon',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _handleServiceAction(context, service),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Details',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios, size: 10, color: Colors.blue.shade700),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _handleServiceAction(context, service),
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: Text(service.actionLabel),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
