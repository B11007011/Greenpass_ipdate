import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/trip_service.dart';
import '../../services/rewards_service.dart';
import '../../models/user_model.dart';
import '../../models/trip_model.dart';
import '../../widgets/stat_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final TripService _tripService = TripService();
  final RewardsService _rewardsService = RewardsService();

  UserModel? _user;
  List<TripModel> _trips = [];
  List<RedemptionModel> _redemptions = [];
  bool _isLoading = true;

  late AnimationController _profileAnimationController;
  late Animation<double> _profileScaleAnimation;
  late Animation<Offset> _profileSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _profileScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _profileAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _profileAnimationController.forward();
  }

  @override
  void dispose() {
    _profileAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await _tripService.getUserProfile();
      final trips = await _tripService.getAllTrips();
      final redemptions = await _rewardsService.getRedemptionHistory();

      setState(() {
        _user = user;
        _trips = trips;
        _redemptions = redemptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(context),
                  const SizedBox(height: 16),
                  _buildAchievements(context),
                  const SizedBox(height: 16),
                  _buildStatsOverview(context),
                  const SizedBox(height: 16),
                  _buildCarbonChart(context),
                  const SizedBox(height: 16),
                  _buildMonthlyInsights(context),
                  const SizedBox(height: 16),
                  _buildSettings(context),
                  const SizedBox(height: 60),
                ]),
              ),
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
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.primaryContainer,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit, color: colorScheme.onPrimaryContainer),
          onPressed: () {
            // Edit profile functionality
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _profileAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _profileAnimationController,
          child: Transform.scale(
            scale: _profileScaleAnimation.value,
            child: SlideTransition(
              position: _profileSlideAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
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
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        _user?.name.substring(0, 1).toUpperCase() ?? 'E',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user?.name ?? 'Eco Commuter',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Member since ${DateFormat.yMMM().format(_user?.joinDate ?? DateTime.now())}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileStat(
                            'Trips',
                            '${_trips.length}',
                            Icons.directions_walk_outlined,
                            colorScheme.primary,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildProfileStat(
                            'Streak',
                            '${_user?.consecutiveGreenDays ?? 0}',
                            Icons.local_fire_department_outlined,
                            colorScheme.secondary,
                            theme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Badges',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline, size: 20),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              return _buildAchievementBadge(
                context,
                ['🚶', '⚡', '📉'][index],
                ['First Mile', 'Power Week', 'Eco Trend'][index],
                colorScheme.outline,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(
    BuildContext context,
    String emoji,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context) {
    final theme = Theme.of(context);
    final totalCarbon = _user?.totalCarbonSavedKg ?? 0.0;
    final totalCredits = _user?.totalCredits ?? 0;
    final totalDistance = _trips.fold(
      0.0,
      (sum, trip) => sum + trip.distanceKm,
    );
    final creditsSpent = _redemptions.fold(
      0,
      (sum, redemption) => sum + redemption.creditsSpent,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impact Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'CO₂ Saved',
                value: '${totalCarbon.toStringAsFixed(1)} kg',
                subtitle: 'vs driving',
                icon: Icons.eco,
                iconColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(
                  0.3,
                ),
                showAnimation: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Distance',
                value: '${totalDistance.toStringAsFixed(1)} km',
                subtitle: 'green travel',
                icon: Icons.straighten,
                iconColor: theme.colorScheme.secondary,
                backgroundColor:
                    theme.colorScheme.secondaryContainer.withOpacity(0.3),
                showAnimation: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Credits',
                value: '$totalCredits',
                subtitle: 'available',
                icon: Icons.stars,
                iconColor: theme.colorScheme.tertiary,
                backgroundColor:
                    theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                showAnimation: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Rewards',
                value: '$creditsSpent',
                subtitle: 'credits used',
                icon: Icons.redeem,
                iconColor: theme.colorScheme.secondary,
                backgroundColor:
                    theme.colorScheme.secondaryContainer.withOpacity(0.3),
                showAnimation: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarbonChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get last 7 days of carbon savings
    final chartData = _getWeeklyChartData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CO₂ Saved',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outline.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        );
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        if (value >= 0 && value < days.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(days[value.toInt()], style: style),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}kg',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: chartData.isEmpty
                    ? 2
                    : chartData
                            .map((e) => e.y)
                            .reduce((a, b) => a > b ? a : b) +
                        0.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: colorScheme.secondary,
                        strokeWidth: 2,
                        strokeColor: colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.secondary.withOpacity(0.4),
                          colorScheme.secondary.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getWeeklyChartData() {
    final now = DateTime.now();
    final weeklyData = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTrips = _trips.where(
        (trip) =>
            trip.timestamp.day == date.day &&
            trip.timestamp.month == date.month &&
            trip.timestamp.year == date.year,
      );

      final dayCarbon = dayTrips.fold(
        0.0,
        (sum, trip) => sum + trip.carbonSavedKg,
      );
      weeklyData.add(FlSpot((6 - i).toDouble(), dayCarbon));
    }

    return weeklyData;
  }

  Widget _buildMonthlyInsights(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final thisMonth = _trips.where(
      (trip) =>
          trip.timestamp.month == now.month && trip.timestamp.year == now.year,
    );

    final monthlyCarbon = thisMonth.fold(
      0.0,
      (sum, trip) => sum + trip.carbonSavedKg,
    );
    final monthlyCredits = thisMonth.fold(
      0,
      (sum, trip) => sum + trip.creditsEarned,
    );
    final monthlyTrips = thisMonth.length;

    // Calculate progress towards monthly goals
    const monthlyCarbonGoal = 10.0; // 10kg CO2 per month
    const monthlyTripsGoal = 60; // 60 trips per month

    final carbonProgress = (monthlyCarbon / monthlyCarbonGoal).clamp(0.0, 1.0);
    final tripsProgress = (monthlyTrips / monthlyTripsGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month\'s Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ProgressStatCard(
          title: 'Carbon Savings Goal',
          currentValue: '${monthlyCarbon.toStringAsFixed(1)} kg',
          targetValue: '${monthlyCarbonGoal.toStringAsFixed(0)} kg',
          progress: carbonProgress,
          icon: Icons.eco,
          progressColor: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        ProgressStatCard(
          title: 'Monthly Trips Goal',
          currentValue: '$monthlyTrips trips',
          targetValue: '$monthlyTripsGoal trips',
          progress: tripsProgress,
          icon: Icons.route,
          progressColor: colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.tertiary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: colorScheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month\'s Insight',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      monthlyCredits > 0
                          ? 'You\'ve earned $monthlyCredits credits this month! That\'s ${(monthlyCredits / 10).toStringAsFixed(1)}kg of CO₂ saved.'
                          : 'Start taking green trips to save credits and save the planet!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          'Notifications',
          'Get reminders and updates',
          Icons.notifications_outlined,
          () {
            // Notification settings
          },
          colorScheme,
          theme,
        ),
        _buildSettingsTile(
          'Privacy',
          'Manage your data and privacy',
          Icons.privacy_tip_outlined,
          () {
            // Privacy settings
          },
          colorScheme,
          theme,
        ),
        _buildSettingsTile(
          'Export Data',
          'Download your trip history',
          Icons.download_outlined,
          () {
            // Export functionality
          },
          colorScheme,
          theme,
        ),
        _buildSettingsTile(
          'About',
          'App version and information',
          Icons.info_outlined,
          () {
            // About page
          },
          colorScheme,
          theme,
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: colorScheme.surface,
      ),
    );
  }
}
