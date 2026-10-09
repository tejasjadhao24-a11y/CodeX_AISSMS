import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.borderGrey, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              shadowColor: AppColors.secondary.withValues(alpha: 0.3),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          );

    return SizedBox(
      width: double.infinity,
      child: button
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 0.98,
            duration: 2.seconds,
            curve: Curves.easeInOut,
          )
          .then()
          .scaleXY(
            begin: 0.98,
            end: 1.0,
            duration: 2.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}
