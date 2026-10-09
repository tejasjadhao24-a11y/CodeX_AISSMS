import 'package:flutter/material.dart';

enum RideType { solo, shared, eco, event, rental }

extension RideTypeExtension on RideType {
  String get displayName {
    switch (this) {
      case RideType.solo:
        return 'Solo Ride';
      case RideType.shared:
        return 'Shared Ride';
      case RideType.eco:
        return 'Eco Ride';
      case RideType.event:
        return 'Event Ride';
      case RideType.rental:
        return 'Rental Ride';
    }
  }

  String get description {
    switch (this) {
      case RideType.solo:
        return 'Just you - Quick & Private';
      case RideType.shared:
        return 'Share the cost & make friends';
      case RideType.eco:
        return 'Save the planet together';
      case RideType.event:
        return 'Group rides for events';
      case RideType.rental:
        return 'Rent a rider for multiple stops';
    }
  }

  String get tagline {
    switch (this) {
      case RideType.solo:
        return 'Fastest way to your destination';
      case RideType.shared:
        return 'Save money while traveling';
      case RideType.eco:
        return 'Carbon-neutral transportation';
      case RideType.event:
        return 'Perfect for campus events';
      case RideType.rental:
        return 'Your personal driver for the day';
    }
  }

  IconData get icon {
    switch (this) {
      case RideType.solo:
        return Icons.person;
      case RideType.shared:
        return Icons.people;
      case RideType.eco:
        return Icons.eco;
      case RideType.event:
        return Icons.event;
      case RideType.rental:
        return Icons.timer;
    }
  }

  String get illustrationPath {
    switch (this) {
      case RideType.solo:
        return 'assets/illustrations/solo_bike.svg';
      case RideType.shared:
        return 'assets/illustrations/shared_ride_small.svg';
      case RideType.eco:
        return 'assets/illustrations/eco_bike.svg';
      case RideType.event:
        return 'assets/illustrations/event_ride.svg';
      case RideType.rental:
        return 'assets/illustrations/rental_bike.svg';
    }
  }

  double get basePrice {
    switch (this) {
      case RideType.solo:
        return 50.0;
      case RideType.shared:
        return 25.0;
      case RideType.eco:
        return 45.0;
      case RideType.event:
        return 40.0;
      case RideType.rental:
        return 100.0;
    }
  }

  int get maxPassengers {
    switch (this) {
      case RideType.solo:
        return 1;
      case RideType.shared:
        return 3;
      case RideType.eco:
        return 2;
      case RideType.event:
        return 4;
      case RideType.rental:
        return 1;
    }
  }

  bool get allowsSplitting {
    return this == RideType.shared;
  }

  bool get isEcoFriendly {
    return this == RideType.eco;
  }

  bool get requiresScheduling {
    return this == RideType.event || this == RideType.rental;
  }
}

