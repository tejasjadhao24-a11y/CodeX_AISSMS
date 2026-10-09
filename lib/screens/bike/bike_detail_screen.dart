import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/bike_provider.dart';
import '../../models/bike_model.dart';
import 'package:intl/intl.dart';

class BikeDetailScreen extends StatefulWidget {
  const BikeDetailScreen({super.key});

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  DateTime _startTime = DateTime.now().add(const Duration(minutes: 15));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2, minutes: 15));
  String _selectedPaymentMethod = 'UPI';
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final bike = ModalRoute.of(context)!.settings.arguments as BikeModel;
    final totalHours = max(0.5, _endTime.difference(_startTime).inMinutes / 60.0);
    final totalAmount = totalHours * bike.pricePerHour;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary.withValues(alpha: 0.12),
                child: Center(
                  child: Icon(
                    bike.bikeType == 'bicycle' ? Icons.pedal_bike_rounded : Icons.moped_rounded,
                    size: 96,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bike.bikeName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${bike.bikeType.toUpperCase()} • ${bike.bikeNumber}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${bike.pricePerHour.toInt()}/hr',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(Icons.person, 'Owner', bike.ownerName),
                  _buildInfoRow(Icons.location_on, 'Pickup Location', bike.location),
                  _buildInfoRow(Icons.payments_outlined, 'Payment', 'Accepts ${bike.paymentMethod}'),
                  if (bike.description != null && bike.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(bike.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 28),
                  const Text('Select Rental Window', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  _buildTimePicker('Start Time', _startTime, (val) => setState(() => _startTime = val)),
                  const SizedBox(height: 10),
                  _buildTimePicker('End Time', _endTime, (val) => setState(() => _endTime = val)),
                  const SizedBox(height: 24),
                  const Text('Preferred Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (bike.paymentMethod != 'Cash')
                        Expanded(
                          child: _paymentChoiceChip(
                            label: 'UPI Online',
                            value: 'UPI',
                            icon: Icons.qr_code,
                            isSelected: _selectedPaymentMethod == 'UPI',
                          ),
                        ),
                      if (bike.paymentMethod == 'Both') const SizedBox(width: 10),
                      if (bike.paymentMethod != 'UPI')
                        Expanded(
                          child: _paymentChoiceChip(
                            label: 'Cash',
                            value: 'Cash',
                            icon: Icons.money,
                            isSelected: _selectedPaymentMethod == 'Cash',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Estimated Duration', '${totalHours.toStringAsFixed(1)} hours'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Hourly Rate', '₹${bike.pricePerHour.toInt()}/hr'),
                        const Divider(height: 20),
                        _buildSummaryRow('Total Amount', '₹${totalAmount.toInt()}', isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : () => _requestRental(bike.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isRequesting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send Rental Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChoiceChip({
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, DateTime current, Function(DateTime) onSelected) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 7)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(current),
          );
          if (time != null) {
            onSelected(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderGrey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(DateFormat('MMM d, h:mm a').format(current), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: isBold ? AppColors.primary : AppColors.textPrimary)),
      ],
    );
  }

  double max(double a, double b) => a > b ? a : b;

  Future<void> _requestRental(String bikeId) async {
    setState(() => _isRequesting = true);
    final provider = Provider.of<BikeProvider>(context, listen: false);
    final success = await provider.requestRental(
      bikeId,
      _startTime,
      _endTime,
      paymentMethod: _selectedPaymentMethod,
    );
    
    if (mounted) {
      setState(() => _isRequesting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request sent! Wait for owner approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to send request. Bike may be booked or unavailable.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}
