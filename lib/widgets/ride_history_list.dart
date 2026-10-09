import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/ride_model.dart';
import '../services/api_service.dart';
import '../services/certificate_service.dart';

class RideHistoryList extends StatelessWidget {
  final List<RideModel> rides;
  final String role; // 'passenger' or 'rider' / 'driver'
  final bool isUpcoming;

  const RideHistoryList({
    super.key,
    required this.rides,
    this.role = 'passenger',
    this.isUpcoming = false,
  });

  bool get isDriver => role == 'rider' || role == 'driver';

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUpcoming ? Icons.directions_car_outlined : Icons.history,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isUpcoming
                          ? (isDriver ? 'No upcoming trips' : 'No upcoming rides')
                          : (isDriver ? 'No completed trips yet' : 'No past rides yet'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isUpcoming
                          ? (isDriver
                              ? 'Accepted ride requests will appear here'
                              : 'Your booked rides will appear here')
                          : (isDriver
                              ? 'Completed rides and earned points will show here'
                              : 'Your ride history will appear here once you take a ride'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        return _buildRideCard(context, rides[index]);
      },
    );
  }

  Widget _buildRideCard(BuildContext context, RideModel ride) {
    String status;
    Color statusColor;

    if (isUpcoming) {
      if (ride.status == RideStatus.pending) {
        status = isDriver ? 'New Request' : 'Finding driver...';
        statusColor = Colors.orange;
      } else if (ride.status == RideStatus.accepted) {
        status = isDriver ? 'Accepted' : 'Driver Assigned';
        statusColor = Colors.teal;
      } else {
        status = 'In Progress';
        statusColor = AppColors.primary;
      }
    } else {
      if (ride.status == RideStatus.cancelled) {
        status = 'Cancelled';
        statusColor = Colors.red.shade400;
      } else {
        status = 'Completed';
        statusColor = AppColors.secondary;
      }
    }

    String dateStr = 'Now';
    if (ride.scheduledTime != null) {
      dateStr = DateFormat('MMM d, h:mm a').format(ride.scheduledTime!);
    } else if (!isUpcoming && ride.completedAt != null) {
      dateStr = DateFormat('MMM d, h:mm a').format(ride.completedAt!);
    } else {
      dateStr = DateFormat('MMM d, h:mm a').format(ride.createdAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Tag and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route with Icons
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: AppColors.borderGrey,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ride.fromLocation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ride.toLocation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Driver/Passenger Info and Price/Earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDriver
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: isDriver ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDriver ? 'Passenger' : 'Driver',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        isDriver
                            ? ride.passengerName
                            : (ride.riderName ??
                                (ride.status == RideStatus.pending
                                    ? 'Searching...'
                                    : 'Assigned Soon')),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isDriver ? 'Earned' : 'Price',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    isDriver
                        ? '+${ride.pointsAwarded} pts'
                        : '${ride.pointsAwarded} pts',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDriver ? AppColors.secondary : AppColors.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Receipt / Summary Button for completed rides
          if (!isUpcoming && ride.status == RideStatus.completed)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceipt(context, ride),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: Text(isDriver ? 'View Trip Summary' : 'Download Receipt'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    try {
                      await CertificateService.shareRideSummaryPdf(
                        ride: ride,
                        isDriver: isDriver,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share PDF: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.textSecondary),
                  tooltip: 'Share Summary PDF',
                ),
              ],
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  Future<void> _showReceipt(BuildContext context, RideModel ride) async {
    try {
      final api = ApiService();
      Map<String, dynamic>? receiptData;
      try {
        final response = await api.get('/rides/${ride.id}/receipt');
        if (response is Map && response['receipt'] != null) {
          receiptData = response['receipt'] as Map<String, dynamic>;
        }
      } catch (_) {
        // Fallback to local ride details if receipt endpoint is unavailable
      }

      final receiptId = receiptData?['receiptId'] ?? ride.id.substring(0, 8).toUpperCase();
      final date = receiptData?['date'] ??
          (ride.completedAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(ride.completedAt!)
              : DateFormat('dd MMM yyyy, hh:mm a').format(ride.createdAt));
      final pName = receiptData?['passengerName'] ?? ride.passengerName;
      final dName = receiptData?['riderName'] ?? ride.riderName ?? 'CampusLift Driver';
      final pts = receiptData?['pointsAwarded'] ?? ride.pointsAwarded;

      final receiptText = isDriver
          ? '''
╔══════════════════════════════╗
     CAMPUSLIFT TRIP SUMMARY
╚══════════════════════════════╝
Trip ID     : $receiptId
Date        : $date
──────────────────────────────
TRIP DETAILS
──────────────────────────────
Driver (You): $dName
Passenger   : $pName
From        : ${ride.fromLocation}
To          : ${ride.toLocation}
Status      : COMPLETED
──────────────────────────────
EARNINGS SUMMARY
──────────────────────────────
Points Earned: +$pts pts
Green Credits: Granted
──────────────────────────────
Thank you for driving with CampusLift!
Campus Trips Made Easy
'''
          : '''
╔══════════════════════════════╗
     CAMPUSLIFT RIDE RECEIPT
╚══════════════════════════════╝
Receipt ID  : $receiptId
Date        : $date
──────────────────────────────
RIDE DETAILS
──────────────────────────────
Passenger   : $pName
Driver      : $dName
From        : ${ride.fromLocation}
To          : ${ride.toLocation}
Status      : COMPLETED
──────────────────────────────
FARE SUMMARY
──────────────────────────────
Points Used : $pts pts
Platform Fee: Rs.0 (Waived)
Total       : $pts pts
──────────────────────────────
Thank you for using CampusLift!
Campus Trips Made Easy
''';

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(children: [
            Icon(Icons.receipt_long, color: isDriver ? AppColors.secondary : Colors.blue),
            const SizedBox(width: 8),
            Text(isDriver ? 'Trip Summary' : 'Ride Receipt'),
          ]),
          content: SingleChildScrollView(
            child: SelectableText(
              receiptText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await CertificateService.shareRideSummaryPdf(
                    ride: ride,
                    isDriver: isDriver,
                    receiptData: receiptData,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to share PDF: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share PDF'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await CertificateService.printRideSummaryPdf(
                    ride: ride,
                    isDriver: isDriver,
                    receiptData: receiptData,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate PDF: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('Download / Print'),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: receiptText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isDriver ? 'Trip summary copied!' : 'Receipt copied!'),
                  backgroundColor: Colors.green,
                ));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to load receipt details'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
