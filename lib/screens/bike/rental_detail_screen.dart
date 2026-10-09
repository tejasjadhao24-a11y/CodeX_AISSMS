import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/bike_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../models/bike_rental_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RentalDetailScreen extends StatefulWidget {
  const RentalDetailScreen({super.key});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final initialRental = ModalRoute.of(context)!.settings.arguments as BikeRentalModel;
    final bikeProvider = Provider.of<BikeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Find updated rental from provider if available
    final currentUserId = userProvider.currentUser?.id;
    final rental = bikeProvider.myRentals.firstWhere(
      (r) => r.id == initialRental.id,
      orElse: () => bikeProvider.incomingRentals.firstWhere(
        (r) => r.id == initialRental.id,
        orElse: () => initialRental,
      ),
    );

    final isOwner = rental.ownerId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rental Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(rental),
            const SizedBox(height: 24),
            _buildInfoSection(context, rental, isOwner),
            const SizedBox(height: 24),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              _buildActions(context, rental, isOwner),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BikeRentalModel rental) {
    Color color;
    IconData icon;
    String description;

    switch (rental.status) {
      case 'requested':
        color = Colors.orange;
        icon = Icons.pending_actions_rounded;
        description = 'Waiting for owner to review and approve';
        break;
      case 'approved':
      case 'payment_pending':
        color = Colors.blue;
        icon = Icons.payment_rounded;
        description = rental.paymentMethod == 'Cash'
            ? 'Approved! Pay cash on handover'
            : 'Approved! Please complete online payment';
        break;
      case 'payment_done':
        color = Colors.teal;
        icon = Icons.hourglass_top_rounded;
        description = 'Payment submitted. Awaiting owner handover';
        break;
      case 'active':
        color = Colors.green;
        icon = Icons.directions_bike_rounded;
        description = 'Rental in progress. Ride safely!';
        break;
      case 'completed':
        color = Colors.grey;
        icon = Icons.check_circle_rounded;
        description = 'Rental successfully completed';
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        description = 'This rental was cancelled';
        break;
      default:
        color = AppColors.primary;
        icon = Icons.info_rounded;
        description = rental.status;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rental.statusDisplay,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, BikeRentalModel rental, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Bike', rental.bikeName),
          _buildDetailRow('Type', rental.bikeType.toUpperCase()),
          _buildDetailRow(isOwner ? 'Renter' : 'Role', isOwner ? rental.renterName : 'You are renting'),
          _buildDetailRow('Payment Mode', rental.paymentMethod),
          const Divider(height: 28),
          _buildDetailRow('Start Time', DateFormat('MMM d, h:mm a').format(rental.startTime)),
          _buildDetailRow('End Time', DateFormat('MMM d, h:mm a').format(rental.endTime)),
          _buildDetailRow('Duration', '${rental.totalHours.toStringAsFixed(1)} hours'),
          const Divider(height: 28),
          _buildDetailRow('Total Amount', '₹${rental.totalAmount.toInt()}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 17 : 14,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, BikeRentalModel rental, bool isOwner) {
    final provider = Provider.of<BikeProvider>(context, listen: false);

    if (isOwner) {
      if (rental.status == 'requested') {
        return Row(
          children: [
            Expanded(
              child: _buildButton('Decline', Colors.red, () async {
                setState(() => _isProcessing = true);
                final ok = await provider.cancelRental(rental.id);
                if (mounted) {
                  setState(() => _isProcessing = false);
                  _handleResult(ok, 'Rental declined');
                }
              }, isOutlined: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton('Approve', Colors.green, () async {
                setState(() => _isProcessing = true);
                final ok = await provider.approveRental(rental.id);
                if (mounted) {
                  setState(() => _isProcessing = false);
                  _handleResult(ok, 'Rental approved!');
                }
              }),
            ),
          ],
        );
      }
      if (rental.status == 'payment_done' || rental.status == 'approved') {
        return Column(
          children: [
            Text(
              rental.paymentMethod == 'Cash'
                  ? 'Collect ₹${rental.totalAmount.toInt()} in cash upon handover.'
                  : 'Renter has paid online. Hand over keys and activate rental.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildButton('Confirm Handover & Start Rental', Colors.green, () async {
              setState(() => _isProcessing = true);
              final ok = await provider.confirmReceived(rental.id);
              if (mounted) {
                setState(() => _isProcessing = false);
                _handleResult(ok, 'Rental activated!');
              }
            }),
          ],
        );
      }
      if (rental.status == 'active') {
        return _buildButton('Confirm Bike Returned', AppColors.primary, () async {
          setState(() => _isProcessing = true);
          final ok = await provider.returnBike(rental.id);
          if (mounted) {
            setState(() => _isProcessing = false);
            _handleResult(ok, 'Bike marked as returned!');
          }
        });
      }
    } else {
      // Renter Actions
      if (rental.status == 'requested') {
        return _buildButton('Cancel Request', Colors.red, () async {
          setState(() => _isProcessing = true);
          final ok = await provider.cancelRental(rental.id);
          if (mounted) {
            setState(() => _isProcessing = false);
            _handleResult(ok, 'Rental request cancelled');
          }
        }, isOutlined: true);
      }
      if (rental.status == 'approved' || rental.status == 'payment_pending') {
        return Column(
          children: [
            if (rental.paymentMethod != 'Cash')
              _buildPaymentCard(rental)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.payments, color: Colors.amber, size: 32),
                    const SizedBox(height: 8),
                    const Text('Cash on Handover', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'Please keep ₹${rental.totalAmount.toInt()} ready in cash to pay the owner.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _buildButton('I Have Paid / Agreed', Colors.green, () async {
              setState(() => _isProcessing = true);
              final ok = await provider.confirmPayment(rental.id, paymentMethod: rental.paymentMethod);
              if (mounted) {
                setState(() => _isProcessing = false);
                _handleResult(ok, 'Payment status updated! Waiting for owner handover.');
              }
            }),
          ],
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _handleResult(bool ok, String successMsg) {
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
    } else {
      final provider = Provider.of<BikeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Action failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPaymentCard(BikeRentalModel rental) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('Payment via UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            rental.ownerUpiId.isNotEmpty ? 'UPI ID: ${rental.ownerUpiId}' : 'Pay to Owner',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Amount: ₹${rental.totalAmount.toInt()}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (rental.ownerUpiId.isNotEmpty) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _launchUPI(rental),
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Open UPI App to Pay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isOutlined 
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              foregroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
    );
  }

  Future<void> _launchUPI(BikeRentalModel rental) async {
    if (rental.ownerUpiId.isEmpty) return;
    final upiUrl = 'upi://pay?pa=${rental.ownerUpiId}&pn=CampusLift&am=${rental.totalAmount}&tn=CampusLift%20Bike%20Rental&cu=INR';
    final uri = Uri.parse(upiUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }
}
