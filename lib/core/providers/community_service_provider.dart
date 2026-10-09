import 'package:flutter/material.dart';
import '../../models/community_service_model.dart';
import '../../models/shuttle_schedule_model.dart';

class CommunityServiceProvider extends ChangeNotifier {
  final List<CommunityServiceModel> _services = [
    CommunityServiceModel(
      id: 'shuttle_1',
      name: 'Campus Shuttle',
      description: 'Free internal university transport',
      status: 'Schedule coming soon',
      type: CommunityServiceType.shuttle,
      actionLabel: 'Schedule coming soon',
    ),
    CommunityServiceModel(
      id: 'auto_1',
      name: 'Local Auto Stand',
      description: 'Reliable campus gate service',
      status: 'Main Gate & South Gate',
      type: CommunityServiceType.auto,
      phoneNumber: '+91 98765 43210',
      actionLabel: 'Call Auto',
    ),
    CommunityServiceModel(
      id: 'taxi_1',
      name: 'City Taxi Services',
      description: 'Verified airport & city drops',
      status: 'Citywide & Airport Drops',
      type: CommunityServiceType.taxi,
      phoneNumber: '+91 87654 32109',
      actionLabel: 'Call Taxi',
    ),
    CommunityServiceModel(
      id: 'bike_1',
      name: 'Campus Bike Rentals',
      description: 'Scan & Ride - Eco Friendly',
      status: 'Hostel Blocks',
      type: CommunityServiceType.bike,
      actionLabel: 'Find Bikes',
    ),
  ];

  final List<ShuttleSchedule> _shuttleSchedules = [
    ShuttleSchedule(
      route: 'Main Gate to Academic Block',
      timings: ['08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '02:00 PM', '04:00 PM', '06:00 PM'],
      frequency: 'Every 60 mins',
    ),
    ShuttleSchedule(
      route: 'Hostel to Library',
      timings: ['07:30 AM', '08:30 AM', '09:30 AM', '10:30 AM', '11:30 AM', '01:30 PM', '03:30 PM', '05:30 PM'],
      frequency: 'Every 60 mins',
    ),
    ShuttleSchedule(
      route: 'Academic Block to Sports Complex',
      timings: ['04:30 PM', '05:30 PM', '06:30 PM', '07:30 PM'],
      frequency: 'Evening Service',
    ),
  ];

  List<CommunityServiceModel> get services => _services;
  List<ShuttleSchedule> get shuttleSchedules => _shuttleSchedules;
}
