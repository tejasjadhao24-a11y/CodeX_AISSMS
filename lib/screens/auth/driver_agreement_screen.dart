import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/core/providers/user_provider.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';

class DriverAgreementScreen extends StatefulWidget {
  const DriverAgreementScreen({super.key});

  @override
  State<DriverAgreementScreen> createState() => _DriverAgreementScreenState();
}

class _DriverAgreementScreenState extends State<DriverAgreementScreen> {
  bool _agreed = false;

  final List<String> _agreements = [
    'Possess a valid driving license',
    'Provide accurate vehicle details',
    'Maintain vehicle safety and cleanliness',
    'Follow all traffic laws and regulations',
    'Not engage in reckless driving',
    'Respect passengers and maintain professional behavior',
    'Avoid discrimination based on gender, religion, or background',
    'Not misuse passenger data',
    'Follow campus transportation guidelines',
    'Allow ride tracking for safety',
    'Accept platform suspension if rules are violated',
  ];

  Future<void> _continue() async {
    if (_agreed) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.acceptGuidelines();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/role-selection');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the terms to continue.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Guidelines & Rules',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'By proceeding, you agree to:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._agreements.map((rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  rule,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (val) {
                          setState(() {
                            _agreed = val ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'I agree to the CampusLift Driver Agreement and Community Guidelines.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _agreed ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _agreed ? AppColors.primary : AppColors.borderGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Accept & Continue', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
