class UserModel {
  final String id;
  final String name;
  final String email;
  final double totalCarbonSavedKg;
  final int totalCredits;
  final List<String> achievements;
  final DateTime joinDate;
  final int consecutiveGreenDays;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.totalCarbonSavedKg,
    required this.totalCredits,
    required this.achievements,
    required this.joinDate,
    required this.consecutiveGreenDays,
  });

  // Factory constructor for creating from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      totalCarbonSavedKg: json['totalCarbonSavedKg'].toDouble(),
      totalCredits: json['totalCredits'],
      achievements: List<String>.from(json['achievements']),
      joinDate: DateTime.parse(json['joinDate']),
      consecutiveGreenDays: json['consecutiveGreenDays'],
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'totalCarbonSavedKg': totalCarbonSavedKg,
      'totalCredits': totalCredits,
      'achievements': achievements,
      'joinDate': joinDate.toIso8601String(),
      'consecutiveGreenDays': consecutiveGreenDays,
    };
  }

  // Create a copy with updated values
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? totalCarbonSavedKg,
    int? totalCredits,
    List<String>? achievements,
    DateTime? joinDate,
    int? consecutiveGreenDays,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalCarbonSavedKg: totalCarbonSavedKg ?? this.totalCarbonSavedKg,
      totalCredits: totalCredits ?? this.totalCredits,
      achievements: achievements ?? this.achievements,
      joinDate: joinDate ?? this.joinDate,
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
  final String status; // 'pending', 'completed', 'expired'

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
}