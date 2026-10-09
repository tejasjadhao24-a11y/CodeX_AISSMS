import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'landing/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startExitTimer();
  }

  void _startExitTimer() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background decor
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 3.seconds, curve: Curves.easeInOut).then().scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: 3.seconds),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CampusLiftLogo(
                  size: 60,
                  textColor: Colors.white,
                  showTagline: true,
                ).animate()
                 .fadeIn(duration: 1.seconds)
                 .scale(delay: 200.ms, duration: 500.ms, begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
                 .shimmer(delay: 1.5.seconds, duration: 1.seconds),
                
                const SizedBox(height: 40),
                
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ).animate()
                 .fadeIn(delay: 1.seconds)
                 .scale(delay: 1.seconds, begin: const Offset(0.5, 0.5)),
              ],
            ),
            
            Positioned(
              bottom: 40,
              child: const Text(
                'CAMPUS MOBILITY REDEFINED',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
              ).animate()
               .fadeIn(delay: 1.5.seconds)
               .slideY(begin: 1, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}
