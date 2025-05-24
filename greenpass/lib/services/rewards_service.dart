import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/trip_service.dart';

class RewardsService {
  static const String _redemptionsKey = 'user_redemptions';
  final TripService _tripService = TripService();

  // Get all available rewards
  Future<List<RewardModel>> getAvailableRewards() async {
    return [
      // Food & Drinks
      RewardModel(
        id: 'drink_711',
        title: 'Free Drink at 7-Eleven',
        description: 'Get any cold drink up to NT\$30',
        creditsRequired: 5,
        category: 'food',
        iconEmoji: '🥤',
        isAvailable: true,
        partnerId: '7eleven',
      ),
      RewardModel(
        id: 'coffee_starbucks',
        title: 'Starbucks Coffee Discount',
        description: '20% off any grande coffee',
        creditsRequired: 8,
        category: 'food',
        iconEmoji: '☕',
        isAvailable: true,
        partnerId: 'starbucks',
      ),
      RewardModel(
        id: 'bubble_tea',
        title: 'Bubble Tea Treat',
        description: 'Free medium bubble tea at participating stores',
        creditsRequired: 12,
        category: 'food',
        iconEmoji: '🧋',
        isAvailable: true,
      ),

      // Transportation
      RewardModel(
        id: 'mrt_discount',
        title: '50% off MRT Monthly Pass',
        description: 'Half-price monthly unlimited MRT pass',
        creditsRequired: 50,
        category: 'transport',
        iconEmoji: '🎫',
        isAvailable: true,
        partnerId: 'taipei_metro',
      ),
      RewardModel(
        id: 'youbike_free',
        title: 'Free YouBike Day Pass',
        description: '24-hour unlimited YouBike access',
        creditsRequired: 15,
        category: 'transport',
        iconEmoji: '🚲',
        isAvailable: true,
        partnerId: 'youbike',
      ),
      RewardModel(
        id: 'bus_credits',
        title: 'Bus Ride Credits',
        description: '5 free bus rides in Taipei',
        creditsRequired: 20,
        category: 'transport',
        iconEmoji: '🚌',
        isAvailable: true,
      ),

      // Environment
      RewardModel(
        id: 'plant_tree',
        title: 'Plant a Tree',
        description: 'Donate to plant one tree in Taiwan mountains',
        creditsRequired: 25,
        category: 'environment',
        iconEmoji: '🌱',
        isAvailable: true,
        partnerId: 'taiwan_forest',
      ),
      RewardModel(
        id: 'ocean_cleanup',
        title: 'Ocean Cleanup Support',
        description: 'Support ocean cleanup efforts around Taiwan',
        creditsRequired: 30,
        category: 'environment',
        iconEmoji: '🌊',
        isAvailable: true,
        partnerId: 'ocean_cleanup',
      ),
      RewardModel(
        id: 'eco_bag',
        title: 'Eco-Friendly Tote Bag',
        description: 'Sustainable bamboo fiber tote bag',
        creditsRequired: 18,
        category: 'environment',
        iconEmoji: '👜',
        isAvailable: true,
      ),
    ];
  }

  // Get rewards by category
  Future<List<RewardModel>> getRewardsByCategory(String category) async {
    final allRewards = await getAvailableRewards();
    return allRewards.where((reward) => reward.category == category).toList();
  }

  // Get user's redemption history
  Future<List<RedemptionModel>> getRedemptionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final redemptionsJson = prefs.getStringList(_redemptionsKey) ?? [];

    return redemptionsJson
        .map(
          (redemptionJson) =>
              RedemptionModel.fromJson(json.decode(redemptionJson)),
        )
        .toList()
      ..sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
  }

  // Redeem a reward
  Future<bool> redeemReward(RewardModel reward) async {
    final user = await _tripService.getUserProfile();

    // Check if user has enough credits
    if (user.totalCredits < reward.creditsRequired) {
      return false;
    }

    // Create redemption record
    final redemption = RedemptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rewardId: reward.id,
      rewardTitle: reward.title,
      creditsSpent: reward.creditsRequired,
      redeemedAt: DateTime.now(),
      status: 'completed',
    );

    // Save redemption
    await _saveRedemption(redemption);

    // Deduct credits from user
    final updatedUser = user.copyWith(
      totalCreditsEarned: user.totalCreditsEarned,
      availableCredits: user.availableCredits - reward.creditsRequired,
    );
    await _saveUserProfile(updatedUser);

    return true;
  }

  // Save redemption to storage
  Future<void> _saveRedemption(RedemptionModel redemption) async {
    final prefs = await SharedPreferences.getInstance();
    final redemptions = await getRedemptionHistory();
    redemptions.add(redemption);

    final redemptionsJson =
        redemptions.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList(_redemptionsKey, redemptionsJson);
  }

  // Save user profile (helper method)
  Future<void> _saveUserProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(user.toJson()));
  }

  // Get reward categories with counts
  Future<Map<String, int>> getRewardCategoryCounts() async {
    final rewards = await getAvailableRewards();
    final categoryCounts = <String, int>{};

    for (final reward in rewards) {
      categoryCounts[reward.category] =
          (categoryCounts[reward.category] ?? 0) + 1;
    }

    return categoryCounts;
  }

  // Get featured rewards (low cost, high value)
  Future<List<RewardModel>> getFeaturedRewards() async {
    final allRewards = await getAvailableRewards();
    return allRewards
        .where((reward) => reward.creditsRequired <= 15)
        .take(3)
        .toList();
  }

  // Get total credits spent this month
  Future<int> getMonthlyCreditsSpent() async {
    final redemptions = await getRedemptionHistory();
    final now = DateTime.now();
    final thisMonth = redemptions.where(
      (redemption) =>
          redemption.redeemedAt.year == now.year &&
          redemption.redeemedAt.month == now.month,
    );

    return thisMonth.fold<int>(
      0,
      (sum, redemption) => sum + redemption.creditsSpent,
    );
  }

  // Check if user can afford reward
  Future<bool> canAffordReward(RewardModel reward) async {
    final user = await _tripService.getUserProfile();
    return user.totalCredits >= reward.creditsRequired;
  }

  // Get reward category display name
  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'food':
        return 'Food & Drinks';
      case 'transport':
        return 'Transportation';
      case 'environment':
        return 'Environment';
      default:
        return 'Other';
    }
  }

  // Get category icon
  String getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return '🍽️';
      case 'transport':
        return '🚇';
      case 'environment':
        return '🌿';
      default:
        return '🎁';
    }
  }
}
