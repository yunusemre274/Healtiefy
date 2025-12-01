import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class CityBuilderScreen extends StatefulWidget {
  const CityBuilderScreen({super.key});

  @override
  State<CityBuilderScreen> createState() => _CityBuilderScreenState();
}

class _CityBuilderScreenState extends State<CityBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBuildingIndex = -1;
  int _availableSteps = 15000;

  final List<_BuildingType> _buildingTypes = [
    _BuildingType(
      name: 'House',
      icon: Icons.home_rounded,
      cost: 1000,
      color: AppColors.secondary,
      description: 'A cozy home for your citizens',
    ),
    _BuildingType(
      name: 'Shop',
      icon: Icons.storefront_rounded,
      cost: 2000,
      color: AppColors.accent,
      description: 'Commerce brings prosperity',
    ),
    _BuildingType(
      name: 'Park',
      icon: Icons.park_rounded,
      cost: 1500,
      color: AppColors.primary,
      description: 'Green spaces for relaxation',
    ),
    _BuildingType(
      name: 'Factory',
      icon: Icons.factory_rounded,
      cost: 3000,
      color: AppColors.purple,
      description: 'Industrial powerhouse',
    ),
    _BuildingType(
      name: 'School',
      icon: Icons.school_rounded,
      cost: 2500,
      color: AppColors.error,
      description: 'Education for the future',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('My City'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatNumber(_availableSteps),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Build'),
                Tab(text: 'My Buildings'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBuildTab(),
                _buildMyBuildingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildTab() {
    return Column(
      children: [
        // City preview
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400',
                ),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            child: Stack(
              children: [
                // Grid overlay
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (_selectedBuildingIndex != -1) {
                          _placeBuilding(index);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Instruction overlay
                if (_selectedBuildingIndex == -1)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Select a building below to place',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(),
        ),
        const SizedBox(height: 16),
        // Building selector
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buildings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _buildingTypes.length,
                    itemBuilder: (context, index) {
                      final building = _buildingTypes[index];
                      final isSelected = _selectedBuildingIndex == index;
                      final canAfford = _availableSteps >= building.cost;

                      return GestureDetector(
                        onTap: canAfford
                            ? () => setState(() {
                                  _selectedBuildingIndex =
                                      isSelected ? -1 : index;
                                })
                            : null,
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? building.color.withValues(alpha: 0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? building.color
                                  : AppColors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: canAfford ? 1 : 0.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        building.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    building.icon,
                                    color: building.color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  building.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: isSelected
                                        ? building.color
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatNumber(building.cost)} steps',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyBuildingsTab() {
    // Mock data for existing buildings
    final myBuildings = [
      _PlacedBuilding(
          type: _buildingTypes[0],
          placedAt: DateTime.now().subtract(const Duration(days: 3))),
      _PlacedBuilding(
          type: _buildingTypes[2],
          placedAt: DateTime.now().subtract(const Duration(days: 2))),
      _PlacedBuilding(
          type: _buildingTypes[1],
          placedAt: DateTime.now().subtract(const Duration(days: 1))),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.location_city_rounded,
                  value: '${myBuildings.length}',
                  label: 'Buildings',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.stars_rounded,
                  value: '${myBuildings.length * 100}',
                  label: 'City Score',
                  color: AppColors.accent,
                ),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          // Buildings list
          Expanded(
            child: myBuildings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No buildings yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Walk more to earn steps and build your city!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: myBuildings.length,
                    itemBuilder: (context, index) {
                      final building = myBuildings[index];
                      return _BuildingListItem(building: building)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _placeBuilding(int gridIndex) {
    final building = _buildingTypes[_selectedBuildingIndex];
    if (_availableSteps >= building.cost) {
      setState(() {
        _availableSteps -= building.cost;
        _selectedBuildingIndex = -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${building.name} placed successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _BuildingType {
  final String name;
  final IconData icon;
  final int cost;
  final Color color;
  final String description;

  const _BuildingType({
    required this.name,
    required this.icon,
    required this.cost,
    required this.color,
    required this.description,
  });
}

class _PlacedBuilding {
  final _BuildingType type;
  final DateTime placedAt;

  const _PlacedBuilding({
    required this.type,
    required this.placedAt,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildingListItem extends StatelessWidget {
  final _PlacedBuilding building;

  const _BuildingListItem({required this.building});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: building.type.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              building.type.icon,
              color: building.type.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.type.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  building.type.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(building.placedAt),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${building.type.cost} steps',
                style: TextStyle(
                  color: building.type.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
