import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/bike_provider.dart';

class PostBikeScreen extends StatefulWidget {
  const PostBikeScreen({super.key});

  @override
  State<PostBikeScreen> createState() => _PostBikeScreenState();
}

class _PostBikeScreenState extends State<PostBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _bikeType = 'bicycle';
  String _paymentMethod = 'Both';
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _upiController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post My Bike', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bike Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                initialValue: _bikeType,
                decoration: _inputDecoration('Bike Type'),
                items: const [
                  DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                  DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                  DropdownMenuItem(value: 'motorcycle', child: Text('Motorcycle')),
                ],
                onChanged: (val) => setState(() => _bikeType = val!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Bike Name (e.g. Hero Cycle, Honda Activa)'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _numberController,
                decoration: _inputDecoration('Bike Number / Frame ID'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration('Price per Hour (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Default Pickup Location on Campus'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description / Instructions (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              const Text('Accepted Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: _inputDecoration('Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'Both', child: Text('Both UPI & Cash (Recommended)')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI Online Only')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash on Handover Only')),
                ],
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 16),

              if (_paymentMethod != 'Cash') ...[
                TextFormField(
                  controller: _upiController,
                  decoration: _inputDecoration('Your UPI ID (to receive online payment)', hintText: 'name@upi'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Renter will pay to this UPI ID once you approve their rental.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post Bike Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter bike name');
      return;
    }
    if (_numberController.text.trim().isEmpty) {
      _showSnack('Please enter bike number / frame ID');
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      _showSnack('Please enter hourly rate');
      return;
    }
    double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showSnack('Please enter a valid positive price');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showSnack('Please enter campus location');
      return;
    }
    if (_paymentMethod != 'Cash' && _upiController.text.trim().isEmpty) {
      _showSnack('Please enter UPI ID to accept online payments');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bikeProvider = Provider.of<BikeProvider>(context, listen: false);
      
      final success = await bikeProvider.postBike({
        'bikeType': _bikeType,
        'bikeName': _nameController.text.trim(),
        'bikeNumber': _numberController.text.trim(),
        'pricePerHour': price,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'ownerUpiId': _upiController.text.trim(),
        'paymentMethod': _paymentMethod,
      });
      
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bike posted successfully! Available for campus students.'),
            backgroundColor: Colors.green,
          )
        );
      } else {
        _showSnack(bikeProvider.errorMessage ?? 'Failed to post bike');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
    );
  }
}
