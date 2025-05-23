import 'package:flutter/material.dart';
import '../../services/rewards_service.dart';
import '../../services/trip_service.dart';
import '../../models/user_model.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with TickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  final TripService _tripService = TripService();

  List<RewardModel> _allRewards = [];
  List<RewardModel> _filteredRewards = [];
  List<RedemptionModel> _redemptions = [];
  UserModel? _user;
  String _selectedCategory = 'all';
  bool _isLoading = true;

  late AnimationController _headerAnimationController;
  late Animation<double> _headerScaleAnimation;

  final List<String> _categories = ['all', 'food', 'transport', 'environment'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final rewards = await _rewardsService.getAvailableRewards();
      final redemptions = await _rewardsService.getRedemptionHistory();
      final user = await _tripService.getUserProfile();

      setState(() {
        _allRewards = rewards;
        _filteredRewards = rewards;
        _redemptions = redemptions;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRewards(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'all') {
        _filteredRewards = _allRewards;
      } else {
        _filteredRewards =
            _allRewards.where((reward) => reward.category == category).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCreditsHeader(context),
                  const SizedBox(height: 24),
                  _buildCategoryFilter(context),
                  const SizedBox(height: 24),
                  _buildRecentRedemptions(context),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
            _buildRewardsList(context),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Bottom padding
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.secondary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'Rewards Shop',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondary,
                colorScheme.secondary.withOpacity(0.8),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '🎁',
                style: TextStyle(
                  fontSize: 48,
                  color: colorScheme.onSecondary.withOpacity(1),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, color: colorScheme.onSecondary),
          onPressed: () => _showRedemptionHistory(),
        ),
      ],
    );
  }

  Widget _buildCreditsHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerScaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.secondaryContainer,
                  colorScheme.tertiaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.stars,
                        color: colorScheme.secondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Credits',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_user?.totalCredits ?? 0}',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Earn more credits by taking green trips!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  final displayName =
                      category == 'all'
                          ? 'All Rewards'
                          : _rewardsService.getCategoryDisplayName(category);
                  final icon =
                      category == 'all'
                          ? '🎁'
                          : _rewardsService.getCategoryIcon(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icon),
                          const SizedBox(width: 8),
                          Text(displayName),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) => _filterRewards(category),
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRedemptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_redemptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentRedemptions = _redemptions.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Redemptions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showRedemptionHistory(),
              child: Text(
                'View All',
                style: TextStyle(color: colorScheme.secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentRedemptions.map(
          (redemption) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        redemption.rewardTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${redemption.creditsSpent} credits used',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  redemption.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsList(BuildContext context) {
    if (_filteredRewards.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎁',
                style: TextStyle(
                  fontSize: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No rewards in this category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildRewardCard(_filteredRewards[index]),
          childCount: _filteredRewards.length,
        ),
      ),
    );
  }

  Widget _buildRewardCard(RewardModel reward) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userCredits = _user?.totalCredits ?? 0;
    final canAfford = userCredits >= reward.creditsRequired;

    return GestureDetector(
      onTap: () => _showRewardDetails(reward),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                canAfford
                    ? colorScheme.primary.withOpacity(0.2)
                    : colorScheme.outline.withOpacity(0.1),
            width: canAfford ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(reward.iconEmoji, style: const TextStyle(fontSize: 32)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        canAfford
                            ? colorScheme.primary.withOpacity(0.1)
                            : colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${reward.creditsRequired}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          canAfford
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reward.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    canAfford
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                reward.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? () => _redeemReward(reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canAfford
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                  foregroundColor:
                      canAfford
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  canAfford ? 'Redeem' : 'Insufficient Credits',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDetails(RewardModel reward) {
    showDialog(
      context: context,
      builder:
          (context) => RewardDetailsDialog(
            reward: reward,
            userCredits: _user?.totalCredits ?? 0,
            onRedeem: () => _redeemReward(reward),
          ),
    );
  }

  Future<void> _redeemReward(RewardModel reward) async {
    final success = await _rewardsService.redeemReward(reward);

    if (success) {
      await _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully redeemed ${reward.title}!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insufficient credits to redeem this reward.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showRedemptionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => RedemptionHistoryBottomSheet(redemptions: _redemptions),
    );
  }
}

class RewardDetailsDialog extends StatelessWidget {
  final RewardModel reward;
  final int userCredits;
  final VoidCallback onRedeem;

  const RewardDetailsDialog({
    super.key,
    required this.reward,
    required this.userCredits,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAfford = userCredits >= reward.creditsRequired;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reward.iconEmoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            reward.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            reward.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Required Credits:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${reward.creditsRequired}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Credits:', style: theme.textTheme.bodyMedium),
              Text(
                '$userCredits',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: canAfford ? colorScheme.secondary : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              canAfford
                  ? () {
                    Navigator.of(context).pop();
                    onRedeem();
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Redeem'),
        ),
      ],
    );
  }
}

class RedemptionHistoryBottomSheet extends StatelessWidget {
  final List<RedemptionModel> redemptions;

  const RedemptionHistoryBottomSheet({super.key, required this.redemptions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Redemption History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (redemptions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🏆',
                      style: TextStyle(
                        fontSize: 64,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No redemptions yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start earning credits to redeem rewards!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: redemptions.length,
                itemBuilder: (context, index) {
                  final redemption = redemptions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                redemption.rewardTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                redemption.status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${redemption.creditsSpent} credits used',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${redemption.redeemedAt.day}/${redemption.redeemedAt.month}/${redemption.redeemedAt.year}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
