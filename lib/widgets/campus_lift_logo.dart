import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampusLiftLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool showIcon;
  final bool isVertical;
  final Color textColor;

  const CampusLiftLogo({
    super.key,
    this.size = 40,
    this.showTagline = true,
    this.showIcon = true,
    this.isVertical = false,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final Widget iconPart = showIcon
        ? SizedBox(
            width: size * 1.5,
            height: size * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Blue Gradient Pin
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Icon(
                    Icons.location_on,
                    size: size * 1.4,
                    color: Colors.white,
                  ),
                ),
                // White Graduation Cap inside - perfectly centered in the pin head
                Positioned(
                  top: size * 0.25,
                  child: Icon(
                    Icons.school,
                    size: size * 0.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final Widget textPart = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          isVertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'CampusLift',
          style: GoogleFonts.poppins(
            fontSize: size * 0.9,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            'CAMPUS TRAVEL MADE EASY',
            textAlign: isVertical ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.poppins(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconPart,
                const SizedBox(height: 8),
                textPart,
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconPart,
                if (showIcon) const SizedBox(width: 4),
                textPart,
              ],
            ),
    );
  }
}
