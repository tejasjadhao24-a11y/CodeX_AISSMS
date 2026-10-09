import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child:
          ElevatedButton(
                onPressed: isLoading ? () {} : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor ?? AppColors.primary,
                  foregroundColor: textColor ?? AppColors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  shadowColor: (backgroundColor ?? AppColors.primary)
                      .withValues(alpha: 0.3),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              )
              .animate(target: isLoading ? 0 : 1)
              .scaleXY(
                begin: 0.95,
                end: 1.0,
                duration: 100.ms,
                curve: Curves.easeOut,
              ),
    );
  }
}
