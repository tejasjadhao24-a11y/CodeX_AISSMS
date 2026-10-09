import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BikeRentalInfoScreen extends StatelessWidget {
  const BikeRentalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Campus Bike Rentals',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.pedal_bike, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Eco-Friendly Campus Mobility',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rent a bike anytime, anywhere within campus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'How it works',
              [
                _buildStep(context, '1', 'Find a bike at any designated bike stand.'),
                _buildStep(context, '2', 'Scan the QR code on the bike frame.'),
                _buildStep(context, '3', 'Unlock and ride to your destination.'),
                _buildStep(context, '4', 'Park and lock at any official stand.'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Rental Rates',
              [
                _buildRateRow('Student Rate', '₹5 / 30 mins'),
                _buildRateRow('Daily Max', '₹50'),
                _buildRateRow('Monthly Pass', '₹299'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Major Bike Stands',
              [
                _buildLocationRow('Main Library'),
                _buildLocationRow('Academic Block A'),
                _buildLocationRow('Hostel Block C'),
                _buildLocationRow('Campus Cafeteria'),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate opening a scanner or finding on map
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Find Nearby Stands', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, String rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(location, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
