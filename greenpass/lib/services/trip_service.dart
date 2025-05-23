import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/trip_model.dart';
import '../../models/user_model.dart';

class TripService {
  static const String _tripsKey = 'user_trips';
  static const String _userKey = 'user_profile';

  // Carbon savings calculation constants (kg CO2 saved per km vs private car)
  static const Map<String, double> _carbonSavingsPerKm = {
    'mrt': 0.08,
    'bus': 0.06,
    'walk': 0.12,
    'bike': 0.12,
    'youbike': 0.11,
  };

  // Get all trips from storage
  Future<List<TripModel>> getAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripsKey) ?? [];

    if (tripsJson.isEmpty) {
      // Initialize with sample data if no trips exist
      await _initializeSampleData();
      return getAllTrips();
    }

    return tripsJson
        .map((tripJson) => TripModel.fromJson(json.decode(tripJson)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get trips for a specific date range
  Future<List<TripModel>> getTripsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final trips = await getAllTrips();
    return trips.where((trip) {
      return trip.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          trip.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get today's trips
  Future<List<TripModel>> getTodaysTrips() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getTripsForDateRange(startOfDay, endOfDay);
  }

  // Get this week's trips
  Future<List<TripModel>> getThisWeeksTrips() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getTripsForDateRange(startOfWeek, now);
  }

  // Add a new trip
  Future<void> addTrip(TripModel trip) async {
    final prefs = await SharedPreferences.getInstance();
    final trips = await getAllTrips();
    trips.add(trip);

    final tripsJson = trips.map((trip) => json.encode(trip.toJson())).toList();
    await prefs.setStringList(_tripsKey, tripsJson);

    // Update user stats
    await _updateUserStats(trip.carbonSavedKg, trip.creditsEarned);
  }

  // Create a new trip with automatic carbon calculation
  Future<TripModel> createTrip({
    required String transportType,
    required double distanceKm,
    String? route,
    String? fromLocation,
    String? toLocation,
  }) async {
    final carbonSaved = _calculateCarbonSaved(transportType, distanceKm);
    final credits = _calculateCredits(carbonSaved);

    return TripModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      transportType: transportType,
      distanceKm: distanceKm,
      carbonSavedKg: carbonSaved,
      creditsEarned: credits,
      route: route,
      fromLocation: fromLocation,
      toLocation: toLocation,
    );
  }

  // Calculate carbon saved based on transport type and distance
  double _calculateCarbonSaved(String transportType, double distanceKm) {
    final savingsPerKm = _carbonSavingsPerKm[transportType] ?? 0.0;
    return savingsPerKm * distanceKm;
  }

  // Calculate credits earned (1 credit per 0.1 kg CO2 saved)
  int _calculateCredits(double carbonSavedKg) {
    return (carbonSavedKg * 10).round();
  }

  // Update user statistics
  Future<void> _updateUserStats(double carbonSaved, int credits) async {
    final user = await getUserProfile();
    final updatedUser = user.copyWith(
      totalCarbonSavedKg: user.totalCarbonSavedKg + carbonSaved,
      totalCredits: user.totalCredits + credits,
    );
    await _saveUserProfile(updatedUser);
  }

  // Get user profile
  Future<UserModel> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) {
      // Create default user if none exists
      final defaultUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Eco Commuter',
        email: 'user@greenpass.app',
        totalCarbonSavedKg: 0,
        totalCredits: 0,
        achievements: [],
        joinDate: DateTime.now(),
        consecutiveGreenDays: 0,
      );
      await _saveUserProfile(defaultUser);
      return defaultUser;
    }

    return UserModel.fromJson(json.decode(userJson));
  }

  // Save user profile
  Future<void> _saveUserProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // Initialize sample data for demonstration
  Future<void> _initializeSampleData() async {
    final Random random = Random();
    final List<TripModel> sampleTrips = [];

    // Create sample trips for the past 2 weeks
    for (int i = 14; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));

      // Add 2-4 trips per day
      final numTrips = 2 + random.nextInt(3);
      for (int j = 0; j < numTrips; j++) {
        final transportTypes = ['mrt', 'bus', 'walk', 'youbike'];
        final transportType =
            transportTypes[random.nextInt(transportTypes.length)];
        final distance = 0.5 + random.nextDouble() * 4.5; // 0.5-5 km

        final tripTime = date.add(
          Duration(hours: 8 + random.nextInt(12), minutes: random.nextInt(60)),
        );

        final carbonSaved = _calculateCarbonSaved(transportType, distance);
        final credits = _calculateCredits(carbonSaved);

        sampleTrips.add(
          TripModel(
            id: '${tripTime.millisecondsSinceEpoch}_$j',
            timestamp: tripTime,
            transportType: transportType,
            distanceKm: double.parse(distance.toStringAsFixed(1)),
            carbonSavedKg: double.parse(carbonSaved.toStringAsFixed(3)),
            creditsEarned: credits,
            route: _getSampleRoute(transportType),
            fromLocation: _getSampleLocation(),
            toLocation: _getSampleLocation(),
          ),
        );
      }
    }

    // Save sample trips
    final prefs = await SharedPreferences.getInstance();
    final tripsJson =
        sampleTrips.map((trip) => json.encode(trip.toJson())).toList();
    await prefs.setStringList(_tripsKey, tripsJson);

    // Update user stats with sample data totals
    final totalCarbon = sampleTrips.fold(
      0.0,
      (sum, trip) => sum + trip.carbonSavedKg,
    );
    final totalCredits = sampleTrips.fold(
      0,
      (sum, trip) => sum + trip.creditsEarned,
    );

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Eco Commuter',
      email: 'user@greenpass.app',
      totalCarbonSavedKg: totalCarbon,
      totalCredits: totalCredits,
      achievements: ['First Trip', 'Week Warrior', 'Carbon Saver'],
      joinDate: DateTime.now().subtract(const Duration(days: 14)),
      consecutiveGreenDays: 7,
    );

    await _saveUserProfile(user);
  }

  String _getSampleRoute(String transportType) {
    final routes = {
      'mrt': [
        'Taipei Main → Xinyi',
        'Banqiao → Zhongshan',
        'Tamsui → Beitou',
        'Songshan Airport → Nanjing Fuxing',
      ],
      'bus': ['Red 30', 'Blue 7', '266', '307'],
      'walk': ['Morning Walk', 'Lunch Break', 'Evening Stroll'],
      'youbike': ['Park Circuit', 'River Path', 'Campus Route'],
    };

    final routeList = routes[transportType] ?? ['Unknown Route'];
    return routeList[Random().nextInt(routeList.length)];
  }

  String _getSampleLocation() {
    final locations = [
      'Taipei Main Station',
      'Xinyi District',
      'Zhongshan Station',
      'Banqiao Station',
      'Da\\\'an Park',
      'Shilin Night Market',
      'Ximending',
      'Songshan Airport',
      'Taipei 101',
      'National Taiwan University',
    ];
    return locations[Random().nextInt(locations.length)];
  }

  // Get carbon savings summary for dashboard
  Future<Map<String, double>> getCarbonSavingsSummary() async {
    final todaysTrips = await getTodaysTrips();
    final weeksTrips = await getThisWeeksTrips();
    final user = await getUserProfile();

    final todaysCarbon = todaysTrips.fold(
      0.0,
      (sum, trip) => sum + trip.carbonSavedKg,
    );
    final weeksCarbon = weeksTrips.fold(
      0.0,
      (sum, trip) => sum + trip.carbonSavedKg,
    );

    return {
      'today': todaysCarbon,
      'week': weeksCarbon,
      'total': user.totalCarbonSavedKg,
    };
  }
}
