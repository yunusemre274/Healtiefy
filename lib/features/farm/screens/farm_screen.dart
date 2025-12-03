import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/farm_models.dart';
import '../../../services/farm_service.dart';
import '../../../services/storage_service.dart';
import '../bloc/farm_bloc.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FarmBloc(
        farmService: context.read<FarmService>(),
        storageService: context.read<StorageService>(),
      )..add(FarmLoadRequested()),
      child: const _FarmView(),
    );
  }
}

class _FarmView extends StatelessWidget {
  const _FarmView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FarmBloc, FarmStateBase>(
      listener: (context, state) {
        if (state is FarmLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor:
                  state.isError ? Colors.red.shade400 : AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is FarmLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your farm...'),
                ],
              ),
            ),
          );
        }

        if (state is FarmError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FarmBloc>().add(FarmLoadRequested());
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is FarmLoaded) {
          return _FarmGameView(state: state);
        }

        return const Scaffold(body: SizedBox());
      },
    );
  }
}

class _FarmGameView extends StatelessWidget {
  final FarmLoaded state;

  const _FarmGameView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with stats
            _FarmTopBar(state: state),

            // Main farm grid
            Expanded(
              child: _FarmGrid(state: state),
            ),

            // Tool bar
            _FarmToolbar(state: state),

            // Bottom action panel
            _FarmActionPanel(state: state),
          ],
        ),
      ),
    );
  }
}

class _FarmTopBar extends StatelessWidget {
  final FarmLoaded state;

  const _FarmTopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Farm name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Farm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _PixelBadge(
                      icon: '⭐',
                      text: 'Lvl ${state.farmState.level}',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _XPProgressBar(
                        progress: state.farmState.levelProgress,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Coins (steps)
          _CoinDisplay(coins: state.farmState.coins),
        ],
      ),
    );
  }
}

class _PixelBadge extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _PixelBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _XPProgressBar extends StatelessWidget {
  final double progress;

  const _XPProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade600, width: 1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _CoinDisplay extends StatelessWidget {
  final int coins;

  const _CoinDisplay({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.amber.shade800],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(
            _formatNumber(coins),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _FarmGrid extends StatelessWidget {
  final FarmLoaded state;

  const _FarmGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final farmState = state.farmState;
    const gridSize = 10;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(100),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF4A7C3F), // Grass base color
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.brown.shade800,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              final x = index % gridSize;
              final y = index ~/ gridSize;
              final tile = farmState.getTileAt(x, y);

              return _FarmTileWidget(
                tile: tile ?? FarmTile(x: x, y: y),
                farmState: farmState,
                isSelected: state.selectedX == x && state.selectedY == y,
                onTap: () {
                  context.read<FarmBloc>().add(FarmSelectTile(x: x, y: y));
                  _handleTileTap(context, state, x, y, tile);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleTileTap(
    BuildContext context,
    FarmLoaded state,
    int x,
    int y,
    FarmTile? tile,
  ) {
    final bloc = context.read<FarmBloc>();

    switch (state.currentTool) {
      case FarmTool.plow:
        if (tile?.type == TileType.grass || tile?.type == TileType.dirt) {
          bloc.add(FarmPlowTile(x: x, y: y));
        }
        break;
      case FarmTool.plant:
        if (tile?.type == TileType.plowed && tile?.cropId == null) {
          _showCropSelector(context, x, y);
        }
        break;
      case FarmTool.harvest:
        if (tile?.cropId != null) {
          final crop = state.farmState.getCrop(tile!.cropId!);
          if (crop?.calculateGrowthStage() == GrowthStage.harvestable) {
            bloc.add(FarmHarvestCrop(cropId: tile.cropId!));
          }
        }
        break;
      case FarmTool.water:
        if (tile?.cropId != null) {
          bloc.add(FarmWaterCrop(cropId: tile!.cropId!));
        }
        break;
      case FarmTool.feed:
        if (tile?.animalId != null) {
          bloc.add(FarmFeedAnimal(animalId: tile!.animalId!));
        }
        break;
      case FarmTool.collect:
        if (tile?.animalId != null) {
          bloc.add(FarmCollectProduct(animalId: tile!.animalId!));
        }
        break;
      case FarmTool.build:
        if (tile?.isEmpty ?? false) {
          _showBuildingSelector(context, x, y);
        }
        break;
      default:
        break;
    }
  }

  void _showCropSelector(BuildContext context, int x, int y) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.brown.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌱 Select Seed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: CropType.values.map((crop) {
                  return _CropSelectorItem(
                    crop: crop,
                    coins: state.farmState.coins,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.read<FarmBloc>().add(
                            FarmPlantCrop(x: x, y: y, cropType: crop),
                          );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBuildingSelector(BuildContext context, int x, int y) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.brown.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏗️ Build',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: FarmBuildingType.values.map((building) {
                  return _BuildingSelectorItem(
                    building: building,
                    coins: state.farmState.coins,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.read<FarmBloc>().add(
                            FarmBuyBuilding(type: building, x: x, y: y),
                          );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _CropSelectorItem extends StatelessWidget {
  final CropType crop;
  final int coins;
  final VoidCallback onTap;

  const _CropSelectorItem({
    required this.crop,
    required this.coins,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= crop.seedCost;

    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.5,
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford ? Colors.green : Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(crop.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(
                crop.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  Text(
                    '${crop.seedCost}',
                    style: TextStyle(
                      color: canAfford ? Colors.amber : Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                '${crop.growthTimeMinutes}m',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildingSelectorItem extends StatelessWidget {
  final FarmBuildingType building;
  final int coins;
  final VoidCallback onTap;

  const _BuildingSelectorItem({
    required this.building,
    required this.coins,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= building.buildCost;

    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.5,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford ? Colors.green : Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(building.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(
                building.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  Text(
                    '${building.buildCost}',
                    style: TextStyle(
                      color: canAfford ? Colors.amber : Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmTileWidget extends StatelessWidget {
  final FarmTile tile;
  final FarmState farmState;
  final bool isSelected;
  final VoidCallback onTap;

  const _FarmTileWidget({
    required this.tile,
    required this.farmState,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getTileColor(),
          borderRadius: BorderRadius.circular(2),
          border:
              isSelected ? Border.all(color: Colors.yellow, width: 2) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _getTileContent(),
        ),
      ),
    );
  }

  Color _getTileColor() {
    switch (tile.type) {
      case TileType.grass:
        return const Color(0xFF5A8F4A); // Dark grass
      case TileType.dirt:
        return const Color(0xFF8B6914); // Brown dirt
      case TileType.plowed:
        return const Color(0xFF654321); // Darker plowed
      case TileType.planted:
        return const Color(0xFF654321);
      case TileType.water:
        return const Color(0xFF4A90A4); // Water blue
      case TileType.path:
        return const Color(0xFFAA8866); // Path
      case TileType.building:
        return const Color(0xFF5A5A5A); // Building base
    }
  }

  Widget? _getTileContent() {
    // Show crop
    if (tile.cropId != null) {
      final crop = farmState.getCrop(tile.cropId!);
      if (crop != null) {
        return _CropWidget(crop: crop);
      }
    }

    // Show animal
    if (tile.animalId != null) {
      final animal = farmState.getAnimal(tile.animalId!);
      if (animal != null) {
        return _AnimalWidget(animal: animal);
      }
    }

    // Show building (only on primary tile)
    if (tile.buildingId != null) {
      final building = farmState.getBuilding(tile.buildingId!);
      if (building != null &&
          tile.x == building.gridX &&
          tile.y == building.gridY) {
        return Text(building.type.emoji, style: const TextStyle(fontSize: 24));
      }
    }

    // Show plowed indicator
    if (tile.type == TileType.plowed) {
      return const Text('▦',
          style: TextStyle(fontSize: 14, color: Colors.brown));
    }

    return null;
  }
}

class _CropWidget extends StatelessWidget {
  final FarmCrop crop;

  const _CropWidget({required this.crop});

  @override
  Widget build(BuildContext context) {
    final stage = crop.calculateGrowthStage();
    final isReady = stage == GrowthStage.harvestable;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          _getCropEmoji(stage),
          style: TextStyle(
            fontSize: isReady ? 22 : 18,
          ),
        ),
        if (isReady)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Text('!',
                  style: TextStyle(fontSize: 8, color: Colors.white)),
            ),
          ),
        if (!isReady)
          Positioned(
            bottom: 0,
            child: Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: crop.growthProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getCropEmoji(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seed:
        return '🫘';
      case GrowthStage.sprout:
        return '🌱';
      case GrowthStage.growing:
        return '🌿';
      case GrowthStage.mature:
        return crop.type.emoji.replaceAll('🎃', '🥒'); // Pre-harvest
      case GrowthStage.harvestable:
        return crop.type.emoji;
      case GrowthStage.withered:
        return '🥀';
    }
  }
}

class _AnimalWidget extends StatelessWidget {
  final FarmAnimal animal;

  const _AnimalWidget({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(animal.type.emoji, style: const TextStyle(fontSize: 20)),
        if (animal.hasProductReady)
          Positioned(
            top: -2,
            right: -2,
            child: Text(animal.type.productEmoji,
                style: const TextStyle(fontSize: 12)),
          ),
        if (animal.isHungry)
          Positioned(
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('🍽️', style: TextStyle(fontSize: 8)),
            ),
          ),
      ],
    );
  }
}

class _FarmToolbar extends StatelessWidget {
  final FarmLoaded state;

  const _FarmToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        border: Border(
          top: BorderSide(color: Colors.brown.shade900, width: 2),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ToolButton(
              tool: FarmTool.none,
              icon: '👆',
              label: 'Select',
              isSelected: state.currentTool == FarmTool.none,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.none)),
            ),
            _ToolButton(
              tool: FarmTool.plow,
              icon: '⛏️',
              label: 'Plow',
              isSelected: state.currentTool == FarmTool.plow,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.plow)),
            ),
            _ToolButton(
              tool: FarmTool.plant,
              icon: '🌱',
              label: 'Plant',
              isSelected: state.currentTool == FarmTool.plant,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.plant)),
            ),
            _ToolButton(
              tool: FarmTool.water,
              icon: '💧',
              label: 'Water',
              isSelected: state.currentTool == FarmTool.water,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.water)),
            ),
            _ToolButton(
              tool: FarmTool.harvest,
              icon: '🌾',
              label: 'Harvest',
              isSelected: state.currentTool == FarmTool.harvest,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.harvest)),
            ),
            _ToolButton(
              tool: FarmTool.feed,
              icon: '🍽️',
              label: 'Feed',
              isSelected: state.currentTool == FarmTool.feed,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.feed)),
            ),
            _ToolButton(
              tool: FarmTool.collect,
              icon: '📦',
              label: 'Collect',
              isSelected: state.currentTool == FarmTool.collect,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.collect)),
            ),
            _ToolButton(
              tool: FarmTool.build,
              icon: '🏗️',
              label: 'Build',
              isSelected: state.currentTool == FarmTool.build,
              onTap: () => context
                  .read<FarmBloc>()
                  .add(FarmSetTool(tool: FarmTool.build)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final FarmTool tool;
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade700 : Colors.brown.shade600,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.brown.shade800,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade300,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmActionPanel extends StatelessWidget {
  final FarmLoaded state;

  const _FarmActionPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStat(
                icon: '🌾',
                value: '${state.farmState.harvestableCropsCount}',
                label: 'Ready',
                color: Colors.green,
              ),
              _QuickStat(
                icon: '🐄',
                value: '${state.farmState.animalsReadyCount}',
                label: 'Products',
                color: Colors.amber,
              ),
              _QuickStat(
                icon: '🍽️',
                value: '${state.farmState.hungryAnimalsCount}',
                label: 'Hungry',
                color: Colors.red,
              ),
              _QuickStat(
                icon: '📦',
                value: '${state.farmState.inventory.length}',
                label: 'Items',
                color: Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: '🛒',
                  label: 'Shop',
                  onTap: () => _showShop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: '🐣',
                  label: 'Animals',
                  onTap: () => _showAnimalShop(context, state),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: '🎒',
                  label: 'Inventory',
                  onTap: () => _showInventory(context, state),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShop(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Shop coming soon! Walk more to earn coins 🚶')),
    );
  }

  void _showAnimalShop(BuildContext context, FarmLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.brown.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🐣 Buy Animal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an animal, then tap an empty tile to place it',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AnimalType.values.map((animal) {
                  final canAfford =
                      state.farmState.coins >= animal.purchaseCost;
                  return GestureDetector(
                    onTap: canAfford
                        ? () {
                            Navigator.pop(sheetContext);
                            _promptAnimalName(context, animal);
                          }
                        : null,
                    child: Opacity(
                      opacity: canAfford ? 1.0 : 0.5,
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade600,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canAfford ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(animal.emoji,
                                style: const TextStyle(fontSize: 32)),
                            Text(
                              animal.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙',
                                    style: TextStyle(fontSize: 12)),
                                Text(
                                  '${animal.purchaseCost}',
                                  style: TextStyle(
                                    color:
                                        canAfford ? Colors.amber : Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _promptAnimalName(BuildContext context, AnimalType type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.brown.shade800,
          title: Text(
            'Name your ${type.emoji} ${type.name}',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.brown.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.amber),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Tap an empty tile to place $name! ${type.emoji}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                // Store the selection for next tile tap
                // This would need additional state management
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showInventory(BuildContext context, FarmLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.brown.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final inventory = state.farmState.inventory;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎒 Inventory',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (inventory.isEmpty)
                const Center(
                  child: Text(
                    'No items yet!\nHarvest crops and collect products to fill your inventory.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: inventory.map((item) {
                    return GestureDetector(
                      onTap: () => _sellItem(context, item),
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade600,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(item.emoji,
                                style: const TextStyle(fontSize: 28)),
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.name,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _sellItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.brown.shade800,
          title: Text(
            'Sell ${item.emoji} ${item.name}?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Sell 1 for 🪙${item.value}?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context); // Close inventory sheet
                context.read<FarmBloc>().add(
                      FarmSellItem(itemId: item.id, quantity: 1),
                    );
              },
              child: const Text('Sell'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
