class TripModel {
  final String id;
  final DateTime timestamp;
  final String transportType; // 'mrt', 'bus', 'walk', 'bike', 'youbike'
  final double distanceKm;
  final double carbonSavedKg;
  final int creditsEarned;
  final String? route; // Optional route description
  final String? fromLocation;
  final String? toLocation;

  TripModel({
    required this.id,
    required this.timestamp,
    required this.transportType,
    required this.distanceKm,
    required this.carbonSavedKg,
    required this.creditsEarned,
    this.route,
    this.fromLocation,
    this.toLocation,
  });

  // Factory constructor for creating from JSON (for shared_preferences)
  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      transportType: json['transportType'],
      distanceKm: json['distanceKm'].toDouble(),
      carbonSavedKg: json['carbonSavedKg'].toDouble(),
      creditsEarned: json['creditsEarned'],
      route: json['route'],
      fromLocation: json['fromLocation'],
      toLocation: json['toLocation'],
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'transportType': transportType,
      'distanceKm': distanceKm,
      'carbonSavedKg': carbonSavedKg,
      'creditsEarned': creditsEarned,
      'route': route,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
    };
  }

  // Helper method to get transport icon
  String get transportIcon {
    switch (transportType) {
      case 'mrt':
        return '🚇';
      case 'bus':
        return '🚌';
      case 'walk':
        return '🚶';
      case 'bike':
        return '🚴';
      case 'youbike':
        return '🚲';
      default:
        return '🚶';
    }
  }

  // Helper method to get transport display name
  String get transportDisplayName {
    switch (transportType) {
      case 'mrt':
        return 'MRT';
      case 'bus':
        return 'Bus';
      case 'walk':
        return 'Walking';
      case 'bike':
        return 'Bicycle';
      case 'youbike':
        return 'YouBike';
      default:
        return 'Unknown';
    }
  }
}
