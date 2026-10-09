import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/core/providers/user_provider.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import '../passenger/main_passenger_screen.dart';
import 'driver_agreement_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared
  final _phoneController = TextEditingController();

  // Passenger Specific
  final _collegeNameController = TextEditingController();
  final _prnController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();

  // Driver Specific
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _serviceAreaController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _collegeNameController.dispose();
    _prnController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _drivingLicenseController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      userProvider.setUserProfile(
        phoneNumber: _phoneController.text,
        collegeName: _collegeNameController.text,
        prn: _prnController.text,
        course: _courseController.text,
        yearOfStudy: _yearController.text,
        vehicleType: _vehicleTypeController.text,
        vehicleNumber: _vehicleNumberController.text,
        drivingLicense: _drivingLicenseController.text,
        serviceArea: _serviceAreaController.text,
      );

      if (userProvider.isRider) {
        // Driver must agree to terms
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverAgreementScreen()),
        );
      } else {
        // Passenger goes straight to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPassengerScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRider = Provider.of<UserProvider>(context).isRider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRider ? 'Driver Verification' : 'Student Verification',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide these details to continue.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField('Phone Number', 'Ex: +91 9876543210', Icons.phone, _phoneController),

              if (!isRider) ...[
                // Passenger
                _buildSectionTitle('College Details'),
                _buildTextField('College Name', 'Ex: Pune University', Icons.school, _collegeNameController),
                _buildTextField('PRN / Student ID', 'Ex: 12345678', Icons.badge, _prnController),
                _buildTextField('Course / Department', 'Ex: Computer Science', Icons.book, _courseController),
                _buildTextField('Year of Study', 'Ex: 3rd Year', Icons.calendar_today, _yearController),
              ] else ...[
                // Driver
                _buildSectionTitle('Vehicle Details'),
                _buildTextField('Vehicle Type', 'Ex: Sedan, SUV, Bike', Icons.directions_car, _vehicleTypeController),
                _buildTextField('Vehicle Number', 'Ex: MH 12 AB 1234', Icons.pin, _vehicleNumberController),
                _buildSectionTitle('Driving Details'),
                _buildTextField('Driving License Number', 'Ex: MH1220110000000', Icons.card_membership, _drivingLicenseController),
                _buildTextField('Service Area (City)', 'Ex: Pune', Icons.location_city, _serviceAreaController),
                _buildTextField('College Affiliation (Optional)', 'Ex: Pune University', Icons.school, _collegeNameController, isOptional: true),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save & Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
