import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/bike_provider.dart';
import '../../models/bike_model.dart';
import '../../models/bike_rental_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class BikeRentalScreen extends StatefulWidget {
  const BikeRentalScreen({super.key});

  @override
  State<BikeRentalScreen> createState() => _BikeRentalScreenState();
}

class _BikeRentalScreenState extends State<BikeRentalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Show data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bikeProvider = Provider.of<BikeProvider>(context, listen: false);
      bikeProvider.fetchAvailableBikes();
      bikeProvider.fetchMyBikes();
      bikeProvider.fetchMyRentals();
      bikeProvider.fetchIncomingRentals();
      
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          bikeProvider.fetchAvailableBikes();
          bikeProvider.fetchIncomingRentals();
          bikeProvider.fetchMyRentals();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bike Rental', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Bikes'),
            Tab(text: 'My Rentals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableBikesTab(),
          _MyBikesTab(),
          _MyRentalsTab(),
        ],
      ),
    );
  }
}

class _AvailableBikesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, child) {
        final bikes = provider.availableBikes;
        
        // BUG 3: Show skeleton cards if loading and empty
        if (provider.isLoading && bikes.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => _SkeletonBikeCard(),
          );
        }
        
        if (bikes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pedal_bike, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('No bikes available for rent right now', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAvailableBikes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bikes.length,
            itemBuilder: (context, index) => _BikeCard(bike: bikes[index]),
          ),
        );
      },
    );
  }
}

class _SkeletonBikeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 150, height: 16, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 12, color: Colors.grey[200]),
                ],
              ),
            ),
            Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  final BikeModel bike;
  const _BikeCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/bike-detail', arguments: bike),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (bike.bikeType == 'bicycle' ? Colors.green : AppColors.secondary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  bike.bikeType == 'bicycle' ? Icons.pedal_bike : Icons.moped,
                  color: bike.bikeType == 'bicycle' ? Colors.green : AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bike.bikeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(bike.ownerName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(bike.location, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pay: ${bike.paymentMethod}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${bike.pricePerHour.toInt()}/hr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Rent', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyBikesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/post-bike'),
              icon: const Icon(Icons.add),
              label: const Text('Post My Bike'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<BikeProvider>(
            builder: (context, provider, child) {
              final bikes = provider.myBikes;
              final incomingRentals = provider.incomingRentals;
              
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (bikes.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('You haven\'t posted any bikes', style: TextStyle(color: AppColors.textMuted)),
                    ))
                  else
                    ...bikes.map((b) => _MyBikeCard(bike: b)),
                    
                  const SizedBox(height: 24),
                  const Text('Rental Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (incomingRentals.isEmpty)
                    const Center(child: Text('No incoming requests', style: TextStyle(color: AppColors.textMuted, fontSize: 13)))
                  else
                    ...incomingRentals.map((r) => _RentalCard(rental: r, isOwner: true)),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MyBikeCard extends StatelessWidget {
  final BikeModel bike;
  const _MyBikeCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BikeProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bike.bikeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(bike.bikeNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Switch(
                    value: bike.isAvailable,
                    onChanged: (val) => provider.toggleAvailability(bike.id),
                    activeThumbColor: Colors.green,
                  ),
                  Consumer<BikeProvider>(
                    builder: (context, provider, child) {
                      final pendingCount = provider.incomingRentals
                          .where((r) => r.bikeId == bike.id && r.status == 'requested')
                          .length;
                      if (pendingCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => provider.deleteBike(bike.id),
              ),
            ],
          ),
          const Divider(),
          Consumer<BikeProvider>(
            builder: (context, provider, child) {
              final requests = provider.incomingRentals.where((r) => r.bikeId == bike.id && (r.status == 'requested' || r.status == 'payment_done')).length;
              if (requests == 0) return const SizedBox.shrink();
              return InkWell(
                onTap: () {
                  // Show incoming rentals for this bike
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.notification_important, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text('$requests pending action(s)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MyRentalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, child) {
        final myRentals = provider.myRentals;
        final incomingRentals = provider.incomingRentals;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (incomingRentals.isNotEmpty) ...[
              const Text('Incoming Requests (I am Owner)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...incomingRentals.map((r) => _RentalCard(rental: r, isOwner: true)),
              const SizedBox(height: 24),
            ],
            const Text('My Rental Requests (I am Renter)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (myRentals.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No rental requests found', style: TextStyle(color: AppColors.textMuted)),
              ))
            else
              ...myRentals.map((r) => _RentalCard(rental: r, isOwner: false)),
          ],
        );
      },
    );
  }
}

class _RentalCard extends StatelessWidget {
  final BikeRentalModel rental;
  final bool isOwner;
  const _RentalCard({required this.rental, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (rental.status) {
      case 'active': statusColor = Colors.green; break;
      case 'completed': statusColor = Colors.blue; break;
      case 'cancelled': statusColor = Colors.red; break;
      case 'payment_done': statusColor = Colors.orange; break;
      default: statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/rental-detail', arguments: rental),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rental.bikeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rental.statusDisplay, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOwner ? 'Renter: ${rental.renterName}' : 'Owner: ${rental.ownerId}', // In real app use names
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('MMM d, h:mm a').format(rental.startTime)} - ${DateFormat('h:mm a').format(rental.endTime)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ₹${rental.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('View Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
