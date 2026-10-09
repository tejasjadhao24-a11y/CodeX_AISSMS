import 'package:flutter/material.dart';
import '../../models/taxi_model.dart';
import '../../services/api_service.dart';

class TaxiProvider extends ChangeNotifier {
  List<TaxiModel> _trustedServices = [
    TaxiModel(
      id: 't1',
      name: 'Campus Shuttle Service',
      phoneNumber: '+91 11223 34455',
      serviceType: TaxiServiceType.taxi,
      status: 'Active',
      description: 'Official university transit for all zones.',
      rating: 4.8,
      isRecommended: true,
      operatingArea: 'All Campus Zones',
    ),
    TaxiModel(
      id: 't2',
      name: 'Main Gate Auto Stand',
      phoneNumber: '+91 98765 43210',
      serviceType: TaxiServiceType.auto,
      status: 'Available',
      description: 'Reliable autos available at the main entrance.',
      rating: 4.5,
      isRecommended: true,
      operatingArea: 'Main Gate & South Gate',
    ),
    TaxiModel(
      id: 't3',
      name: 'City Taxi Premium',
      phoneNumber: '+91 87654 32109',
      serviceType: TaxiServiceType.taxi,
      status: 'On Call',
      description: 'Verified airport and city-wide drops.',
      rating: 4.6,
      operatingArea: 'Citywide & Airport Drops',
    ),
    TaxiModel(
      id: 't4',
      name: 'Emergency Auto Service',
      phoneNumber: '+91 99887 76655',
      serviceType: TaxiServiceType.auto,
      status: '24/7 Active',
      description: 'Priority service for late-night campus returns.',
      rating: 4.9,
      isRecommended: true,
      operatingArea: 'Back Gate & Hostel Area',
    ),
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TaxiProvider() {
    fetchTrustedServices();
  }

  List<TaxiModel> get trustedServices => _trustedServices;

  List<TaxiModel> get recommendedServices =>
      _trustedServices.where((s) => s.isRecommended).toList();

  Future<void> fetchTrustedServices() async {
    _isLoading = true;
    try {
      final res = await ApiService().get('/users/trusted-contacts');
      if (res is Map && res['contacts'] is List) {
        final list = List<Map<String, dynamic>>.from(res['contacts'] as List);
        final transitContacts = list.where((c) {
          final cat = (c['category'] ?? '').toString().toLowerCase();
          return cat == 'auto' || cat == 'taxi';
        }).toList();

        if (transitContacts.isNotEmpty) {
          _trustedServices = transitContacts.map((c) {
            final cat = (c['category'] ?? '').toString().toLowerCase();
            return TaxiModel(
              id: c['id']?.toString() ?? '',
              name: c['name']?.toString() ?? 'Transit Stand',
              phoneNumber: c['phone']?.toString() ?? '+91 98765 43210',
              serviceType: cat == 'auto' ? TaxiServiceType.auto : TaxiServiceType.taxi,
              status: 'Available',
              description: c['description']?.toString().isNotEmpty == true
                  ? c['description'].toString()
                  : 'Campus verified ${cat == 'auto' ? 'auto' : 'taxi'} service',
              rating: 4.8,
              isRecommended: true,
              operatingArea: c['location']?.toString() ?? 'Campus Area',
            );
          }).toList();
        }
      }
    } catch (_) {
      // Retain fallback list on network errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
