enum TaxiServiceType { taxi, auto }

class TaxiModel {
  final String id;
  final String name;
  final String phoneNumber;
  final TaxiServiceType serviceType;
  final String status;
  final String description;
  final double rating;
  final bool isRecommended;
  final String? operatingArea;

  TaxiModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.serviceType,
    required this.status,
    required this.description,
    required this.rating,
    this.isRecommended = false,
    this.operatingArea,
  });
}
