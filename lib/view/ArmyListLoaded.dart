import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squire/data/model/Army_list/Army_unit_data.dart';
import 'package:squire/data/repositories/unit_repository.dart';
import 'package:squire/view_models/home_view_model.dart';
import 'package:squire/view/ArmyListLoaded.dart';
import 'UnitDetailsScreen.dart';

class ArmyListLoadedScreen extends StatelessWidget {
  final ListPa armyList;

  const ArmyListLoadedScreen({required this.armyList, super.key});

  // Helper function to format unit ID into asset paths (e.g., "30123" -> "assets/standees/30123.jpg")
  String _getImagePath(String? id, {String type = 'unit'}) {
    if (id == null || id.isEmpty) {
      // Return a generic placeholder if the ID is missing
      return 'assets/standees/placeholder_$type.jpg';
    }
    // Use the ID directly with the .jpg extension as specified
    return 'assets/standees/$id.jpg';
  }

  // Helper to build an image widget, handling potential errors
  Widget _buildUnitImage(String imagePath, {double size = 150.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback widget if the image asset is not found
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade500),
            ),
            child: Center(
              child: Text(
                '${imagePath.split('/').last.split('.').first}\nNo Image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: size * 0.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tactical Tracker'),
        backgroundColor: Colors.red.shade800,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Commander Portrait (Left Side) ---
              SizedBox(
                width: 130, // Slightly wider for larger image
                child: Column(
                  children: [
                    Text(
                      'Commander',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Use the Commander's ID for the image path
                    _buildUnitImage(
                      _getImagePath(
                        armyList.commanderDetails?.id ?? '',
                        type: 'commander',
                      ),
                      size: 120, // Larger image
                    ),
                    const SizedBox(height: 8),
                    Text(
                      armyList.commanderName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 24, thickness: 2),

              // --- 2. Combat Units (Center, Horizontal Scrollable) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Combat Units (${armyList.combatUnits.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: Consumer<HomeViewModel>(
                        builder: (context, viewModel, child) {
                          final units = viewModel.listPa?.combatUnits ?? [];

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: units
                                  .map(
                                    (unit) => _buildUnitCard(
                                      context,
                                      unit,
                                      isCombat: true,
                                      viewModel: viewModel,
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 24, thickness: 2),

              // --- 3. NCUs (Right Side, Vertical Column) ---
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NCUs (${armyList.ncus.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: Consumer<HomeViewModel>(
                        builder: (context, viewModel, child) {
                          final ncus = viewModel.listPa?.ncus ?? [];

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ncus
                                  .map(
                                    (unit) => _buildNcuCard(
                                      context,
                                      unit,
                                      viewModel: viewModel,
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Provider.of<HomeViewModel>(
            context,
            listen: false,
          ).resetAllActivations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All units reset to unactivated.')),
          );
        },
        label: const Text('Reset Activations'),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.blueGrey.shade700,
      ),
    );
  }

  // --- Widget Builders for Units/NCUs ---

  // Combat Unit Card (Horizontal)
  Widget _buildUnitCard(
    BuildContext context,
    UnitEntry unit, {
    required bool isCombat,
    required HomeViewModel viewModel,
  }) {
    // Retrieve the freshest state from the ViewModel
    final currentUnitState = viewModel.findUnitState(unit);
    final baseWounds = currentUnitState.unitDetails?.baseWounds ?? 1;
    final isDestroyed = currentUnitState.currentWounds >= baseWounds;

    // Get unit IDs for image paths
    final unitId = currentUnitState.unitDetails?.id;
    final attachmentId = currentUnitState.attachmentDetails?.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitDetailsScreen(unit: currentUnitState),
          ),
        );
      },
      child: Container(
        width: 200, // Significantly wider for better visual impact
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: currentUnitState.isActivated
                  ? Colors.green.shade600
                  : isDestroyed
                  ? Colors.black
                  : Colors.red.shade400,
              width: currentUnitState.isActivated ? 4 : 2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Unit Portrait
                    _buildUnitImage(
                      _getImagePath(unitId),
                      size: 150,
                    ), // Larger image
                    const SizedBox(height: 12),

                    // Unit Name
                    Text(
                      unit.unitName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isDestroyed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Status Indicators (Wounds & Activation Toggle)
                    _buildStatusIndicators(
                      context,
                      viewModel,
                      currentUnitState,
                      baseWounds,
                      isCombat,
                    ),
                  ],
                ),
              ),

              // Attachment Image (Top Right Corner)
              if (attachmentId != null)
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.yellow.shade700,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    // Use attachment ID for image path
                    child: _buildUnitImage(
                      _getImagePath(attachmentId, type: 'attachment'),
                      size: 50, // Slightly larger attachment icon
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // NCU Card (Vertical on Right)
  Widget _buildNcuCard(
    BuildContext context,
    UnitEntry unit, {
    required HomeViewModel viewModel,
  }) {
    final currentUnitState = viewModel.findUnitState(unit);
    final unitId = currentUnitState.unitDetails?.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitDetailsScreen(unit: currentUnitState),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 4,
          color: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: currentUnitState.isActivated
                  ? Colors.lightBlue.shade600
                  : Colors.grey.shade400,
              width: currentUnitState.isActivated ? 3 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              children: [
                // Use unit ID for image path
                _buildUnitImage(_getImagePath(unitId, type: 'ncu'), size: 70),
                const SizedBox(height: 4),
                Text(
                  unit.unitName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // NCU Activation Toggle
                _buildActivationToggle(
                  viewModel,
                  currentUnitState,
                  isNcu: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Common Status Indicator Row
  Widget _buildStatusIndicators(
    BuildContext context,
    HomeViewModel viewModel,
    UnitEntry currentUnitState,
    int baseWounds,
    bool isCombat,
  ) {
    final isDestroyed = currentUnitState.currentWounds >= baseWounds;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Wounds Indicator (for Combat Units only)
        if (isCombat)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDestroyed ? Colors.black12 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDestroyed ? Colors.black54 : Colors.red.shade400,
                ),
              ),
              child: Text(
                isDestroyed
                    ? 'DESTROYED'
                    : 'W: ${currentUnitState.currentWounds}/$baseWounds',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isDestroyed ? Colors.black : Colors.red.shade900,
                ),
              ),
            ),
          ),

        if (isCombat) const SizedBox(width: 8),

        // Activation Toggle
        _buildActivationToggle(viewModel, currentUnitState, isNcu: !isCombat),
      ],
    );
  }

  // Common Activation Toggle Widget
  Widget _buildActivationToggle(
    HomeViewModel viewModel,
    UnitEntry currentUnitState, {
    required bool isNcu,
  }) {
    final Color activeColor = isNcu
        ? Colors.lightBlue.shade500
        : Colors.green.shade500;
    final Color inactiveColor = isNcu
        ? Colors.grey.shade400
        : Colors.red.shade500;

    return InkWell(
      onTap: () {
        viewModel.toggleActivation(
          currentUnitState.unitName,
          attachmentName: currentUnitState.attachmentName,
        );
      },
      child: Container(
        width: 30, // Increased size
        height: 30, // Increased size
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: currentUnitState.isActivated ? activeColor : inactiveColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Icon(
          currentUnitState.isActivated ? Icons.check : Icons.close,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// Extension to help ViewModel consumers find the correct state
extension HomeViewModelHelper on HomeViewModel {
  UnitEntry findUnitState(UnitEntry unit) {
    final isCombat =
        listPa?.combatUnits.any(
          (u) =>
              u.unitName == unit.unitName &&
              u.attachmentName == unit.attachmentName,
        ) ??
        false;

    if (isCombat) {
      return listPa?.combatUnits.firstWhere(
            (u) =>
                u.unitName == unit.unitName &&
                u.attachmentName == unit.attachmentName,
            orElse: () => unit,
          ) ??
          unit;
    } else {
      return listPa?.ncus.firstWhere(
            (u) =>
                u.unitName == unit.unitName &&
                u.attachmentName == unit.attachmentName,
            orElse: () => unit,
          ) ??
          unit;
    }
  }
}
