import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/trip_service.dart';
import '../models/trip_model.dart';
import '../widgets/stat_card.dart';

class TripTrackerPage extends StatefulWidget {
  const TripTrackerPage({super.key});

  @override
  State<TripTrackerPage> createState() => _TripTrackerPageState();
}

class _TripTrackerPageState extends State<TripTrackerPage>
    with TickerProviderStateMixin {
  final TripService _tripService = TripService();
  List<TripModel> _trips = [];
  bool _isLoading = true;
  
  late AnimationController _listAnimationController;
  final List<AnimationController> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTrips();
  }

  void _setupAnimations() {
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await _tripService.getAllTrips();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
      _animateItems();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _animateItems() {
    // Clear existing controllers
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();

    // Create new controllers for visible items
    for (int i = 0; i < _trips.length.clamp(0, 10); i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 100)),
        vsync: this,
      );
      _itemControllers.add(controller);
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Trip Tracker',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: colorScheme.primary,
            ),
            onPressed: () => _showAddTripDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        color: colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTodaysStats(),
                  const SizedBox(height: 24),
                  _buildTransportTypeBreakdown(),
                  const SizedBox(height: 24),
                  _buildRecentTripsHeader(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            _buildTripsList(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Bottom padding
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTripDialog(),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_road),
        label: const Text('Add Trip'),
      ),
    );
  }

  Widget _buildTodaysStats() {
    final today = DateTime.now();
    final todaysTrips = _trips.where((trip) {
      return trip.timestamp.day == today.day &&
             trip.timestamp.month == today.month &&
             trip.timestamp.year == today.year;
    }).toList();

    final todaysCarbon = todaysTrips.fold(0.0, (sum, trip) => sum + trip.carbonSavedKg);
    final todaysCredits = todaysTrips.fold(0, (sum, trip) => sum + trip.creditsEarned);
    final todaysDistance = todaysTrips.fold(0.0, (sum, trip) => sum + trip.distanceKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Impact',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Trips',
                value: '${todaysTrips.length}',
                subtitle: 'green journeys',
                icon: Icons.route,
                showAnimation: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Distance',
                value: '${todaysDistance.toStringAsFixed(1)} km',
                subtitle: 'traveled green',
                icon: Icons.straighten,
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
                title: 'CO₂ Saved',
                value: '${todaysCarbon.toStringAsFixed(2)} kg',
                subtitle: 'vs driving',
                icon: Icons.eco,
                iconColor: Theme.of(context).colorScheme.secondary,
                showAnimation: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Credits',
                value: '$todaysCredits',
                subtitle: 'earned today',
                icon: Icons.stars,
                iconColor: Theme.of(context).colorScheme.tertiary,
                showAnimation: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransportTypeBreakdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get transport type counts for this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeeksTrips = _trips.where((trip) => 
      trip.timestamp.isAfter(weekStart)
    ).toList();

    final transportCounts = <String, int>{};
    final transportCarbon = <String, double>{};
    
    for (final trip in thisWeeksTrips) {
      transportCounts[trip.transportType] = 
          (transportCounts[trip.transportType] ?? 0) + 1;
      transportCarbon[trip.transportType] = 
          (transportCarbon[trip.transportType] ?? 0) + trip.carbonSavedKg;
    }

    final sortedTransports = transportCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Transport Mix',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedTransports.isEmpty)
            Center(
              child: Text(
                'No trips this week yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            ...sortedTransports.take(4).map((entry) {
              final trip = TripModel(
                id: '',
                timestamp: DateTime.now(),
                transportType: entry.key,
                distanceKm: 0,
                carbonSavedKg: 0,
                creditsEarned: 0,
              );
              final carbon = transportCarbon[entry.key] ?? 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      trip.transportIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.transportDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${carbon.toStringAsFixed(2)} kg CO₂ saved',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.value} trips',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentTripsHeader() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Trips',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            // Filter or sort functionality
          },
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Filter'),
        ),
      ],
    );
  }

  Widget _buildTripsList() {
    if (_trips.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No trips recorded yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your green journeys!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final trip = _trips[index];
            final animationController = index < _itemControllers.length 
                ? _itemControllers[index] 
                : null;

            return _buildTripItem(trip, animationController, index);
          },
          childCount: _trips.length,
        ),
      ),
    );
  }

  Widget _buildTripItem(TripModel trip, AnimationController? controller, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget tripCard = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trip.transportIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.transportDisplayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trip.route != null)
                      Text(
                        trip.route!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(trip.timestamp),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${trip.creditsEarned}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetric(
                '${trip.distanceKm} km',
                Icons.straighten,
                colorScheme.primary,
                theme,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                '${trip.carbonSavedKg.toStringAsFixed(2)} kg CO₂',
                Icons.eco,
                colorScheme.secondary,
                theme,
              ),
            ],
          ),
          if (trip.fromLocation != null && trip.toLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${trip.fromLocation} → ${trip.toLocation}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - controller.value)),
            child: Opacity(
              opacity: controller.value,
              child: tripCard,
            ),
          );
        },
      );
    }

    return tripCard;
  }

  Widget _buildMetric(String value, IconData icon, Color color, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAddTripDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTripBottomSheet(),
    ).then((result) {
      if (result == true) {
        _loadTrips(); // Refresh trips list
      }
    });
  }
}

class AddTripBottomSheet extends StatefulWidget {
  const AddTripBottomSheet({super.key});

  @override
  State<AddTripBottomSheet> createState() => _AddTripBottomSheetState();
}

class _AddTripBottomSheetState extends State<AddTripBottomSheet> {
  final TripService _tripService = TripService();
  String? _selectedTransport;
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _transportOptions = [
    {'type': 'mrt', 'name': 'MRT', 'icon': '🚇'},
    {'type': 'bus', 'name': 'Bus', 'icon': '🚌'},
    {'type': 'walk', 'name': 'Walking', 'icon': '🚶'},
    {'type': 'bike', 'name': 'Bicycle', 'icon': '🚴'},
    {'type': 'youbike', 'name': 'YouBike', 'icon': '🚲'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add New Trip',
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
          const SizedBox(height: 24),
          Text(
            'Transport Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _transportOptions.map((option) {
              final isSelected = _selectedTransport == option['type'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option['icon']),
                    const SizedBox(width: 8),
                    Text(option['name']),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTransport = selected ? option['type'] : null;
                  });
                },
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer 
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _distanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Distance (km)',
              hintText: 'e.g., 2.5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.straighten),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _routeController,
            decoration: InputDecoration(
              labelText: 'Route (optional)',
              hintText: 'e.g., Red Line, Bus 266',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.route),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    labelText: 'From (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.my_location),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    labelText: 'To (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submitTrip : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Add Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return !_isSubmitting &&
           _selectedTransport != null &&
           _distanceController.text.isNotEmpty &&
           double.tryParse(_distanceController.text) != null;
  }

  Future<void> _submitTrip() async {
    if (!_canSubmit()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final distance = double.parse(_distanceController.text);
      final trip = await _tripService.createTrip(
        transportType: _selectedTransport!,
        distanceKm: distance,
        route: _routeController.text.isEmpty ? null : _routeController.text,
        fromLocation: _fromController.text.isEmpty ? null : _fromController.text,
        toLocation: _toController.text.isEmpty ? null : _toController.text,
      );

      await _tripService.addTrip(trip);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trip added! You earned ${trip.creditsEarned} credits.',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add trip. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _routeController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}