// User model for the GreenPass application

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int totalCarbonSavedKg;
  final int totalCreditsEarned;
  final int availableCredits;
  final List<String> achievements;
  final Map<String, dynamic> preferences;
  final List<Map<String, dynamic>> tripHistory;
  final int monthlyGreenPoints;
  final DateTime? lastGreenPointsReset;
  final DateTime? lastRedemptionDate;
  final Map<String, dynamic>? vehicleInfo;
  final List<RedemptionModel> redemptions;
  final int personalVehicleUsageCount;
  final bool hasUsedPublicTransportThisMonth;
  final DateTime? joinDate;
  final int consecutiveGreenDays;

  UserModel({
    required String id,
    required String name,
    required String email,
    String? photoUrl,
    int totalCarbonSavedKg = 0,
    int totalCreditsEarned = 0,
    int availableCredits = 0,
    List<String>? achievements,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? tripHistory,
    int? monthlyGreenPoints,
    DateTime? lastGreenPointsReset,
    Map<String, dynamic>? vehicleInfo,
    DateTime? lastRedemptionDate,
    List<RedemptionModel>? redemptions,
    int personalVehicleUsageCount = 0,
    bool hasUsedPublicTransportThisMonth = false,
    DateTime? joinDate,
    int consecutiveGreenDays = 0,
  })  : id = id,
        name = name,
        email = email,
        photoUrl = photoUrl,
        totalCarbonSavedKg = totalCarbonSavedKg,
        totalCreditsEarned = totalCreditsEarned,
        availableCredits = availableCredits,
        monthlyGreenPoints = monthlyGreenPoints ?? 100,
        lastGreenPointsReset = lastGreenPointsReset,
        vehicleInfo = vehicleInfo,
        lastRedemptionDate = lastRedemptionDate,
        personalVehicleUsageCount = personalVehicleUsageCount,
        hasUsedPublicTransportThisMonth = hasUsedPublicTransportThisMonth,
        joinDate = joinDate,
        consecutiveGreenDays = consecutiveGreenDays,
        achievements = achievements ?? [],
        preferences = preferences ?? {},
        tripHistory = tripHistory ?? [],
        redemptions = redemptions ?? [];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      totalCarbonSavedKg: json['totalCarbonSavedKg'] ?? 0,
      totalCreditsEarned: json['totalCreditsEarned'] ?? 0,
      availableCredits: json['availableCredits'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      tripHistory: List<Map<String, dynamic>>.from(json['tripHistory'] ?? []),
      monthlyGreenPoints: json['monthlyGreenPoints'] ?? 100,
      lastGreenPointsReset: json['lastGreenPointsReset'] != null
          ? DateTime.parse(json['lastGreenPointsReset'] as String)
          : null,
      lastRedemptionDate: json['lastRedemptionDate'] != null
          ? DateTime.parse(json['lastRedemptionDate'] as String)
          : null,
      vehicleInfo: json['vehicleInfo'] != null
          ? Map<String, dynamic>.from(json['vehicleInfo'])
          : null,
      redemptions: json['redemptions'] != null
          ? (json['redemptions'] as List)
              .map((e) => RedemptionModel.fromJson(e))
              .toList()
          : [],
      personalVehicleUsageCount: json['personalVehicleUsageCount'] ?? 0,
      hasUsedPublicTransportThisMonth:
          json['hasUsedPublicTransportThisMonth'] ?? false,
      consecutiveGreenDays: json['consecutiveGreenDays'] ?? 0,
    );
  }

  /// Returns the total credits earned by the user
  int get totalCredits => totalCreditsEarned;

  /// Returns the join date of the user
  DateTime? get userJoinDate => joinDate;

  /// Returns the number of consecutive green days
  int get userConsecutiveGreenDays => consecutiveGreenDays;

  /// Checks if user can redeem points (every 3 months)
  bool get canRedeemPoints {
    if (lastRedemptionDate == null) return true;
    final now = DateTime.now();
    final nextRedemptionDate = DateTime(
      lastRedemptionDate!.year,
      lastRedemptionDate!.month + 3,
      lastRedemptionDate!.day,
    );
    return now.isAfter(nextRedemptionDate);
  }

  /// Resets monthly green points to 100 if it's a new month
  UserModel checkAndResetMonthlyPoints() {
    final now = DateTime.now();
    if (lastGreenPointsReset == null || 
        now.month != lastGreenPointsReset!.month || 
        now.year != lastGreenPointsReset!.year) {
      return copyWith(
        monthlyGreenPoints: 100,
        lastGreenPointsReset: now,
        // If user didn't use public transport but also didn't use personal vehicle,
        // give them 20 bonus points
        hasUsedPublicTransportThisMonth: false,
        personalVehicleUsageCount: 0,
      );
    }
    return this;
  }

  /// Deducts green points for personal vehicle usage
  UserModel deductPointsForVehicleUsage() {
    // Deduct 5 points for each personal vehicle usage
    final pointsToDeduct = 5;
    final newPoints = (monthlyGreenPoints - pointsToDeduct).clamp(0, 100);
    
    return copyWith(
      monthlyGreenPoints: newPoints,
      personalVehicleUsageCount: (personalVehicleUsageCount + 1).clamp(0, 1000),
    );
  }

  /// Rewards points for not using personal vehicle
  UserModel rewardPointsForNoVehicleUsage() {
    // If no personal vehicle was used this month, add 20 points
    if (personalVehicleUsageCount == 0 && !hasUsedPublicTransportThisMonth) {
      return copyWith(
        monthlyGreenPoints: (monthlyGreenPoints + 20).clamp(0, 100),
      );
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'totalCarbonSavedKg': totalCarbonSavedKg,
      'totalCreditsEarned': totalCreditsEarned,
      'availableCredits': availableCredits,
      'achievements': achievements,
      'preferences': preferences,
      'tripHistory': tripHistory,
      'monthlyGreenPoints': monthlyGreenPoints,
      'lastGreenPointsReset': lastGreenPointsReset?.toIso8601String(),
      'lastRedemptionDate': lastRedemptionDate?.toIso8601String(),
      'vehicleInfo': vehicleInfo,
      'redemptions': redemptions.map((e) => e.toJson()).toList(),
      'personalVehicleUsageCount': personalVehicleUsageCount,
      'hasUsedPublicTransportThisMonth': hasUsedPublicTransportThisMonth,
    };
  }

  // Method to update monthly green points
  UserModel updateMonthlyPoints(int points) {
    return copyWith(monthlyGreenPoints: points);
  }

  // Method to register/update vehicle info
  UserModel updateVehicleInfo(Map<String, dynamic> vehicleData) {
    return copyWith(vehicleInfo: vehicleData);
  }

  // Method to add a redemption
  UserModel addRedemption(RedemptionModel redemption) {
    final updatedRedemptions = List<RedemptionModel>.from(redemptions)
      ..add(redemption);
    return copyWith(redemptions: updatedRedemptions);
  }

  // Method to update redemption status
  UserModel updateRedemptionStatus(String redemptionId, String newStatus) {
    final updatedRedemptions = redemptions.map((redemption) {
      if (redemption.id == redemptionId) {
        return redemption.copyWith(status: newStatus);
      }
      return redemption;
    }).toList();

    return copyWith(redemptions: updatedRedemptions);
  }

  // Helper method to create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    int? totalCarbonSavedKg,
    int? totalCreditsEarned,
    int? availableCredits,
    List<String>? achievements,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? tripHistory,
    int? monthlyGreenPoints,
    DateTime? lastGreenPointsReset,
    DateTime? lastRedemptionDate,
    Map<String, dynamic>? vehicleInfo,
    List<RedemptionModel>? redemptions,
    int? personalVehicleUsageCount,
    bool? hasUsedPublicTransportThisMonth,
    DateTime? joinDate,
    int? consecutiveGreenDays,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl,
      totalCarbonSavedKg: totalCarbonSavedKg ?? this.totalCarbonSavedKg,
      totalCreditsEarned: totalCreditsEarned ?? this.totalCreditsEarned,
      availableCredits: availableCredits ?? this.availableCredits,
      achievements: achievements ?? this.achievements,
      preferences: preferences ?? this.preferences,
      tripHistory: tripHistory ?? this.tripHistory,
      monthlyGreenPoints: monthlyGreenPoints ?? this.monthlyGreenPoints,
      lastGreenPointsReset: lastGreenPointsReset,
      lastRedemptionDate: lastRedemptionDate,
      vehicleInfo: vehicleInfo,
      redemptions: redemptions ?? this.redemptions,
      personalVehicleUsageCount: personalVehicleUsageCount ?? this.personalVehicleUsageCount,
      hasUsedPublicTransportThisMonth: hasUsedPublicTransportThisMonth ?? this.hasUsedPublicTransportThisMonth,
      joinDate: joinDate,
      consecutiveGreenDays: consecutiveGreenDays ?? this.consecutiveGreenDays,
    );
  }
}

class RewardModel {
  final String id;
  final String title;
  final String description;
  final int creditsRequired;
  final String category; // 'food', 'transport', 'environment'
  final String iconEmoji;
  final bool isAvailable;
  final String? partnerId;

  RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.creditsRequired,
    required this.category,
    required this.iconEmoji,
    required this.isAvailable,
    this.partnerId,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creditsRequired: json['creditsRequired'],
      category: json['category'],
      iconEmoji: json['iconEmoji'],
      isAvailable: json['isAvailable'],
      partnerId: json['partnerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creditsRequired': creditsRequired,
      'category': category,
      'iconEmoji': iconEmoji,
      'isAvailable': isAvailable,
      'partnerId': partnerId,
    };
  }
}

class RedemptionModel {
  final String id;
  final String rewardId;
  final String rewardTitle;
  final int creditsSpent;
  final DateTime redeemedAt;
  String status; // 'pending', 'completed', 'expired'

  RedemptionModel({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.creditsSpent,
    required this.redeemedAt,
    required this.status,
  });

  factory RedemptionModel.fromJson(Map<String, dynamic> json) {
    return RedemptionModel(
      id: json['id'],
      rewardId: json['rewardId'],
      rewardTitle: json['rewardTitle'],
      creditsSpent: json['creditsSpent'],
      redeemedAt: DateTime.parse(json['redeemedAt']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'creditsSpent': creditsSpent,
      'redeemedAt': redeemedAt.toIso8601String(),
      'status': status,
    };
  }

  // Helper method to create a copy with updated fields
  RedemptionModel copyWith({
    String? id,
    String? rewardId,
    String? rewardTitle,
    int? creditsSpent,
    DateTime? redeemedAt,
    String? status,
  }) {
    return RedemptionModel(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      rewardTitle: rewardTitle ?? this.rewardTitle,
      creditsSpent: creditsSpent ?? this.creditsSpent,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      status: status ?? this.status,
    );
  }
}
