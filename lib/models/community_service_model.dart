enum CommunityServiceType { shuttle, auto, taxi, bike }

class CommunityServiceModel {
  final String id;
  final String name;
  final String description;
  final String status; // e.g., "All Campus Zones", "Active", "Free"
  final CommunityServiceType type;
  final String? phoneNumber;
  final String actionLabel;

  CommunityServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.type,
    this.phoneNumber,
    required this.actionLabel,
  });
}
