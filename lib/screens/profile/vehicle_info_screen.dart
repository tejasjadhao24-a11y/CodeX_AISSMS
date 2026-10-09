import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../services/api_service.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSwitchingRole = false;

  final _vehicleNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  String? _selectedVehicleType;
  bool _licenseVerified = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isRider) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/users/profile');
      if (response != null && mounted) {
        setState(() {
          _vehicleNameController.text = response['vehicleName'] ?? response['vehicle_name'] ?? '';
          _vehicleNumberController.text = response['vehicleNumber'] ?? response['vehicle_number'] ?? '';
          _serviceAreaController.text = response['serviceArea'] ?? response['service_area'] ?? '';
          _licenseVerified = response['licenseVerified'] ?? response['license_verified'] ?? false;
          
          final vType = response['vehicleType'] ?? response['vehicle_type'];
          if (vType != null && const ['Bicycle', 'Scooter', 'Motorcycle', 'Car'].contains(vType)) {
            _selectedVehicleType = vType;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vehicle details: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveVehicleInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final patchData = {
      'vehicleType': _selectedVehicleType,
      'vehicleName': _vehicleNameController.text.trim(),
      'vehicleNumber': _vehicleNumberController.text.trim(),
      'serviceArea': _serviceAreaController.text.trim(),
    };

    try {
      await _apiService.patch('/users/profile', patchData);
      
      // Update local state in UserProvider
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).loadUser();
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle information updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _switchRoleAndReload() async {
    setState(() {
      _isSwitchingRole = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.switchRole();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to Rider mode successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload vehicle data
        await _loadVehicleData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch role: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingRole = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isRider = userProvider.isRider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text(
          'Vehicle Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isRider
              ? Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car_outlined,
                            size: 80,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Riders Only',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Vehicle info is only for riders. Switch to rider mode to add vehicle.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isSwitchingRole ? null : _switchRoleAndReload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _isSwitchingRole
                                ? const SizedBox.shrink()
                                : const Icon(Icons.swap_horiz, color: Colors.white),
                            label: _isSwitchingRole
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Switch to Rider Mode',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification badge
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _licenseVerified
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _licenseVerified ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _licenseVerified ? Icons.verified : Icons.warning_amber_rounded,
                                color: _licenseVerified ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _licenseVerified ? 'Driver Verified' : 'Pending Verification',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _licenseVerified ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _licenseVerified
                                          ? 'Your vehicle and license information are verified.'
                                          : 'Our team is verifying your license and vehicle details.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _licenseVerified ? Colors.green.shade700 : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Vehicle Type Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedVehicleType,
                                items: const [
                                  DropdownMenuItem(value: 'Bicycle', child: Text('Bicycle')),
                                  DropdownMenuItem(value: 'Scooter', child: Text('Scooter')),
                                  DropdownMenuItem(value: 'Motorcycle', child: Text('Motorcycle')),
                                  DropdownMenuItem(value: 'Car', child: Text('Car')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVehicleType = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select vehicle type';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Type',
                                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Vehicle Name Field
                              TextFormField(
                                controller: _vehicleNameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter vehicle name';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Model / Name',
                                  hintText: 'Ex: Activa 6G, Splendor, Swift',
                                  prefixIcon: const Icon(Icons.directions_car_outlined, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Vehicle Number Field
                              TextFormField(
                                controller: _vehicleNumberController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter vehicle number';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Plate Number',
                                  hintText: 'Ex: MH 12 AB 1234',
                                  prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Service Area Field
                              TextFormField(
                                controller: _serviceAreaController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter service area';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Primary Service Area',
                                  hintText: 'Ex: VIT Campus & Nearby',
                                  prefixIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveVehicleInfo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
