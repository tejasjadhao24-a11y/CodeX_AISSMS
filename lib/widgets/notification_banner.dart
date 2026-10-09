import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum NotificationType { success, error, warning, info }

class NotificationBanner extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onClose;

  const NotificationBanner({
    super.key,
    required this.message,
    required this.type,
    this.onClose,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case NotificationType.success:
        return AppColors.ecoGreen;
      case NotificationType.error:
        return AppColors.alertRed;
      case NotificationType.warning:
        return Colors.amber.shade700;
      case NotificationType.info:
        return AppColors.secondary;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: AppColors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.white, size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
