import 'package:flutter/material.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../services/socket_service.dart';
import '../../widgets/ride_history_list.dart';

class MyRidesScreen extends StatefulWidget {
  final String? role; // 'passenger' or 'rider' / 'driver'

  const MyRidesScreen({super.key, this.role});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  int _selectedTab = 0;
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      try {
        _socketService = Provider.of<SocketService>(context, listen: false);
        _socketService?.onRideCompleted((_) {
          if (mounted) _loadData();
        });
        _socketService?.onRideAccepted((_) {
          if (mounted) _loadData();
        });
      } catch (e) {
        debugPrint('SocketService not available for ride history listener: $e');
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final effectiveRole = widget.role ?? userProvider.currentUser?.role ?? 'passenger';
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    await Future.wait([
      rideProvider.fetchHistory(role: effectiveRole),
      rideProvider.fetchUpcomingRides(role: effectiveRole),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final effectiveRole = widget.role ?? userProvider.currentUser?.role ?? 'passenger';
    final isDriver = effectiveRole == 'rider' || effectiveRole == 'driver';
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: canPop ? const BackButton(color: AppColors.textPrimary) : null,
        title: canPop
            ? Text(
                isDriver ? 'Trip History' : 'My Rides',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const CampusLiftLogo(
                size: 24,
                showTagline: false,
              ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isDriver ? 'Upcoming Trips' : 'Upcoming',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isDriver ? 'Past Trips' : 'Past Rides',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 1
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: rideProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _selectedTab == 0
                        ? RideHistoryList(
                            rides: rideProvider.upcomingRides,
                            role: effectiveRole,
                            isUpcoming: true,
                          )
                        : RideHistoryList(
                            rides: rideProvider.rideHistory,
                            role: effectiveRole,
                            isUpcoming: false,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
