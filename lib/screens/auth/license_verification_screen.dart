import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../rider/main_rider_screen.dart';

class LicenseVerificationScreen extends StatefulWidget {
  const LicenseVerificationScreen({super.key});

  @override
  State<LicenseVerificationScreen> createState() => _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _licenseExpiryController;
  late TextEditingController _rcNumberController;
  late TextEditingController _vehicleNameController;
  late TextEditingController _vehicleNumberController;

  String _selectedLicenseType = 'Two Wheeler';
  String _selectedVehicleType = 'Bike/Scooter';
  bool _isSubmitting = false;
  String? _licensePhoto;
  String? _rcPhoto;
  bool _isUploadingLicense = false;
  bool _isUploadingRc = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _licenseNumberController = TextEditingController(text: user?.licenseNumber ?? '');
    _licenseExpiryController = TextEditingController(text: user?.licenseExpiry ?? '');
    _rcNumberController = TextEditingController(text: user?.vehicleRcNumber ?? '');
    _vehicleNameController = TextEditingController(text: user?.vehicleName ?? '');
    _vehicleNumberController = TextEditingController(text: user?.vehicleNumber ?? '');

    if (user?.licenseType != null && user!.licenseType!.isNotEmpty) {
      _selectedLicenseType = user.licenseType!;
    }
    if (user?.vehicleType != null && user!.vehicleType!.isNotEmpty) {
      _selectedVehicleType = user.vehicleType!;
    }
    _licensePhoto = user?.licensePhoto;
    _rcPhoto = user?.rcPhoto;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _rcNumberController.dispose();
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _licenseExpiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickAndUploadDocument(bool isLicense) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                isLicense ? 'Upload Driving License' : 'Upload Vehicle RC',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processDocUpload(isLicense, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processDocUpload(isLicense, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processDocUpload(bool isLicense, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        if (isLicense) {
          _isUploadingLicense = true;
        } else {
          _isUploadingRc = true;
        }
      });

      final bytes = await picked.readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final payload = isLicense ? {'license_base64': b64} : {'rc_base64': b64};
      final res = await _apiService.post('/users/license/documents', payload);

      if (mounted) {
        setState(() {
          if (isLicense) {
            _licensePhoto = res['licensePhoto'] ?? res['license_photo'];
          } else {
            _rcPhoto = res['rcPhoto'] ?? res['rc_photo'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLicense ? 'Driving License uploaded!' : 'Vehicle RC uploaded!'),
            backgroundColor: AppColors.ecoGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isLicense) {
            _isUploadingLicense = false;
          } else {
            _isUploadingRc = false;
          }
        });
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final body = {
        'licenseNumber': _licenseNumberController.text.trim(),
        'licenseType': _selectedLicenseType,
        'licenseExpiry': _licenseExpiryController.text.trim(),
        'vehicleRcNumber': _rcNumberController.text.trim(),
        'vehicleType': _selectedVehicleType,
        'vehicleName': _vehicleNameController.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim(),
        if (_licensePhoto != null) 'licensePhoto': _licensePhoto,
        if (_rcPhoto != null) 'rcPhoto': _rcPhoto,
      };

      await _apiService.patch('/users/license', body);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        await Provider.of<UserProvider>(context, listen: false).loadUser();
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Verification details submitted successfully!'),
            backgroundColor: AppColors.ecoGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final status = user?.verificationStatus ?? 'unverified';

    final bool isPending = status == 'pending';
    final bool isApproved = status == 'approved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Driver Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<UserProvider>(context, listen: false).loadUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(status, user?.verificationNote),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name (Prefilled/ReadOnly)
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 24),

                  // License Info
                  _buildSectionHeader('Driving License Details'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _licenseNumberController,
                    label: 'License Number',
                    icon: Icons.badge_outlined,
                    hint: 'e.g. MH1220230123456',
                    readOnly: isPending || isApproved,
                    validator: (v) => v!.trim().isEmpty ? 'License number is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'License Type',
                    icon: Icons.commute_outlined,
                    value: _selectedLicenseType,
                    items: ['Two Wheeler', 'Four Wheeler'],
                    enabled: !isPending && !isApproved,
                    onChanged: (val) {
                      setState(() {
                        _selectedLicenseType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _licenseExpiryController,
                    label: 'License Expiry Date',
                    icon: Icons.calendar_today_outlined,
                    hint: 'YYYY-MM-DD',
                    readOnly: true,
                    onTap: (isPending || isApproved) ? null : _selectExpiryDate,
                    validator: (v) => v!.trim().isEmpty ? 'Expiry date is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Vehicle Details
                  _buildSectionHeader('Vehicle Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _rcNumberController,
                    label: 'Vehicle RC Number',
                    icon: Icons.description_outlined,
                    hint: 'e.g. MH-12-AB-1234',
                    readOnly: isPending || isApproved,
                    validator: (v) => v!.trim().isEmpty ? 'Vehicle RC number is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Vehicle Type',
                    icon: Icons.category_outlined,
                    value: _selectedVehicleType,
                    items: ['Bike/Scooter', 'Car'],
                    enabled: !isPending && !isApproved,
                    onChanged: (val) {
                      setState(() {
                        _selectedVehicleType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vehicleNameController,
                    label: 'Vehicle / Bike Name',
                    icon: Icons.directions_bike_outlined,
                    hint: 'e.g. Honda Activa 6G / Splendor',
                    readOnly: isPending || isApproved,
                    validator: (v) => v!.trim().isEmpty ? 'Vehicle name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vehicleNumberController,
                    label: 'Vehicle License Plate Number',
                    icon: Icons.pin_outlined,
                    hint: 'e.g. MH 12 GH 9876',
                    readOnly: isPending || isApproved,
                    validator: (v) => v!.trim().isEmpty ? 'Plate number is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Verification Documents
                  _buildSectionHeader('Verification Documents'),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload clear photos of your Driving License and Vehicle Registration Certificate (RC) for verification.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _buildDocUploadCard(
                    title: 'Driving License Photo',
                    subtitle: 'Front side showing name, DL number and validity',
                    icon: Icons.badge_outlined,
                    fileName: _licensePhoto,
                    isUploading: _isUploadingLicense,
                    readOnly: isPending || isApproved,
                    onTap: () => _pickAndUploadDocument(true),
                  ),
                  const SizedBox(height: 16),
                  _buildDocUploadCard(
                    title: 'Vehicle RC Document',
                    subtitle: 'Registration certificate matching plate number',
                    icon: Icons.assignment_outlined,
                    fileName: _rcPhoto,
                    isUploading: _isUploadingRc,
                    readOnly: isPending || isApproved,
                    onTap: () => _pickAndUploadDocument(false),
                  ),
                  const SizedBox(height: 32),

                  // Submit Actions
                  if (!isPending && !isApproved)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit for Verification',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  
                  if (isApproved)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const MainRiderScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ecoGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Go to Rider Dashboard',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        isApproved ? 'Back' : 'Skip for Now',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStatusCard(String status, String? note) {
    Color cardColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String description;
    bool showRefresh = false;

    switch (status) {
      case 'pending':
        cardColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade300;
        textColor = Colors.amber.shade900;
        icon = Icons.hourglass_empty_outlined;
        title = 'Verification Pending';
        description = 'Your details have been submitted and are currently being reviewed by campus administration. This process usually takes less than 24 hours.';
        showRefresh = true;
        break;
      case 'approved':
        cardColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle_outline;
        title = 'Verification Approved';
        description = 'Congratulations! Your license and vehicle details have been fully verified. You are now authorized to host rides and earn points.';
        break;
      case 'rejected':
        cardColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        textColor = Colors.red.shade900;
        icon = Icons.error_outline;
        title = 'Verification Rejected';
        description = 'Rejection Reason: ${note ?? "No reason provided."}\n\nPlease check your inputs, update the fields below, and re-submit for verification.';
        showRefresh = true;
        break;
      case 'unverified':
      default:
        cardColor = AppColors.primary.withValues(alpha: 0.05);
        borderColor = AppColors.primary.withValues(alpha: 0.2);
        textColor = AppColors.primary;
        icon = Icons.info_outline;
        title = 'Verification Required';
        description = 'To host rides on CampusLift and earn reward points, Pune university regulations require you to submit your active driver\'s license and vehicle registration (RC).';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (showRefresh) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() {
                                _isSubmitting = true;
                              });
                              try {
                                await Provider.of<UserProvider>(context, listen: false).loadUser();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Status updated successfully!'),
                                      backgroundColor: AppColors.ecoGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to check status: $e'),
                                      backgroundColor: AppColors.alertRed,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 14),
                      label: const Text('Check Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'pending' ? Colors.amber.shade700 : Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: TextStyle(
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
        fontWeight: readOnly ? FontWeight.w500 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: readOnly,
        fillColor: readOnly ? AppColors.borderGrey.withValues(alpha: 0.3) : Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required bool enabled,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: !enabled,
        fillColor: !enabled ? AppColors.borderGrey.withValues(alpha: 0.3) : Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required bool isUploading,
    required bool readOnly,
    required VoidCallback onTap,
  }) {
    final bool hasDoc = fileName != null && fileName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDoc ? AppColors.ecoGreen.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
          width: hasDoc ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasDoc ? AppColors.ecoGreen.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasDoc ? Icons.check_circle : icon,
              color: hasDoc ? AppColors.ecoGreen : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDoc ? 'Document attached ($fileName)' : subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasDoc ? AppColors.ecoGreen : AppColors.textSecondary,
                    fontWeight: hasDoc ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (!readOnly)
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDoc ? Colors.grey[100] : AppColors.primary,
                foregroundColor: hasDoc ? AppColors.textPrimary : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                hasDoc ? 'Change' : 'Upload',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
