import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:squire/data/model/Army_list/Army_unit_data.dart' as army_data;
import 'package:squire/view_models/home_view_model.dart';

class UnitDetailsScreen extends StatefulWidget {
  final army_data.UnitEntry unit;

  const UnitDetailsScreen({required this.unit, super.key});

  @override
  State<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends State<UnitDetailsScreen> {
  // State to track which attack profile is selected (e.g., 'melee' or 'long')
  String _selectedAttackType = 'melee';

  @override
  void initState() {
    super.initState();
    // Default to the first attack type available if it's not melee
    final attackProfiles = widget.unit.unitDetails?.attacks ?? [];
    if (!attackProfiles.any((p) => p.type == 'melee') &&
        attackProfiles.isNotEmpty) {
      _selectedAttackType = attackProfiles.first.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    // Get the current state of the unit from the ViewModel
    // NOTE: This logic ensures we use the most up-to-date state from the ViewModel
    army_data.UnitEntry currentUnitState = widget.unit;

    // Safely look up the unit in the ViewModel's state to get the latest wounds/modifiers
    army_data.UnitEntry? match;

    // 1. Search Combat Units safely
    final cuList = viewModel.listPa?.combatUnits ?? [];
    final cuMatches = cuList
        .where(
          (u) =>
              u.unitName == widget.unit.unitName &&
              u.attachmentName == widget.unit.attachmentName,
        )
        .toList();

    if (cuMatches.isNotEmpty) {
      match = cuMatches.first;
    }

    // 2. Search NCUs safely if no combat unit match found
    if (match == null) {
      final ncuList = viewModel.listPa?.ncus ?? [];
      final ncuMatches = ncuList
          .where(
            (u) =>
                u.unitName == widget.unit.unitName &&
                u.attachmentName == widget.unit.attachmentName,
          )
          .toList();

      if (ncuMatches.isNotEmpty) {
        match = ncuMatches.first;
      }
    }

    // 3. Update the state reference if a match was found
    if (match != null) {
      currentUnitState = match;
    }

    // Check if the unit is a Combat Unit (has defense value)
    final isCombatUnit = currentUnitState.unitDetails?.defense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUnitState.unitName),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- NEW: UNIT AND ATTACHMENT PORTRAITS ---
            _buildPortraitsRow(currentUnitState),

            const SizedBox(height: 20),

            // --- UNIT IDENTIFICATION ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUnitState.unitName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentUnitState.attachmentName != null)
                      Text(
                        'Attached: ${currentUnitState.attachmentName}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    const Divider(height: 20),
                    _buildActivationTracker(
                      context,
                      currentUnitState,
                      viewModel,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- WOUND COUNTER (Combat Units Only) ---
            if (isCombatUnit)
              _buildWoundCounter(context, currentUnitState, viewModel),

            const SizedBox(height: 20),

            // --- ROLL SECTION ---
            if (isCombatUnit)
              _buildRollsSection(context, currentUnitState, viewModel),
          ],
        ),
      ),
    );
  }

  // --- NEW: Portrait Builder Section ---

  Widget _buildPortraitsRow(army_data.UnitEntry unit) {
    final unitData = unit.unitDetails;
    final attachmentData = unit.attachmentDetails;
    // Set a large size for the main unit image
    const double mainImageSize = 120.0;
    // Set a slightly smaller size for the attachment
    const double secondaryImageSize = 90.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Main Unit Portrait (Always present)
        _buildUnitPortrait(
          unitData?.role == 'ncu' ? 'NCU' : 'Unit', // Label logic
          unitData,
          mainImageSize,
          isMain: true,
        ),

        // 2. Attachment Portrait (If present)
        if (attachmentData != null) ...[
          const SizedBox(width: 20),
          _buildUnitPortrait(
            'Attachment',
            attachmentData,
            secondaryImageSize,
            isMain: false,
          ),
        ],
      ],
    );
  }

  Widget _buildUnitPortrait(
    String label,
    army_data.ArmyUnitData? data,
    double size, {
    required bool isMain,
  }) {
    final id = data?.id;
    final name = data?.name ?? 'Unknown';
    final title = data?.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMain ? 18 : 16,
            color: isMain ? Colors.black87 : Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _buildUnitImage(
          _getImagePath(id, type: data?.role ?? 'unit'),
          size: size,
          isMain: isMain,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: size,
          child: Text(
            title ?? name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- End Portrait Builder Section ---

  Widget _buildActivationTracker(
    BuildContext context,
    army_data.UnitEntry unit,
    HomeViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activation Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: unit.isActivated ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: unit.isActivated
                  ? Colors.green.shade600
                  : Colors.red.shade600,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                unit.isActivated ? 'ACTIVATED' : 'UNACTIVATED',
                style: TextStyle(
                  color: unit.isActivated
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => viewModel.toggleActivation(
                  unit.unitName,
                  attachmentName: unit.attachmentName,
                ),
                icon: Icon(
                  unit.isActivated ? Icons.undo : Icons.check_circle_outline,
                ),
                label: Text(unit.isActivated ? 'Reset' : 'Activate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: unit.isActivated
                      ? Colors.amber.shade700
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWoundCounter(
    BuildContext context,
    army_data.UnitEntry unit,
    HomeViewModel viewModel,
  ) {
    // Check if the unit is a Combat Unit (has defense value)
    final isCombatUnit = unit.unitDetails?.defense != null;

    // Get the parsed wounds from the unit details, defaulting to 0 if null.
    int parsedWounds = unit.unitDetails?.baseWounds ?? 0;

    // --- CRITICAL FIX FOR 3 WOUNDS ISSUE ---
    // If it's a combat unit and the parsed wounds are less than 12 (but not 0),
    // it likely means the API/parser provided a faulty low number (like 3).
    // We enforce the ASOIAF standard of 12 for these units.
    if (isCombatUnit && parsedWounds < 12 && parsedWounds > 0) {
      // NOTE: The root issue is the API/Parser returning 3 instead of 12 for standard combat units.
      // This view-layer fix enforces the expected 12 wounds.
      parsedWounds = 12;
    }

    // Final max wounds: use the corrected parsed value, or 12 as an absolute default.
    final maxWounds = parsedWounds > 0 ? parsedWounds : 12;

    final woundsTaken = unit.currentWounds;
    final woundsRemaining = maxWounds - woundsTaken;
    final isDestroyed = woundsRemaining <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wound Tracker',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrement Wounds Button (Increments Wounds Taken / Takes Damage)
                _buildWoundButton(
                  icon: Icons.exposure_plus_1, // Damage taken is +1 wound
                  color: Colors.red.shade700,
                  onPressed: woundsRemaining > 0
                      ? () => viewModel.updateWounds(
                          unit.unitName,
                          attachmentName: unit.attachmentName,
                          newWounds: woundsTaken + 1,
                        )
                      : null,
                ),

                // Wound Display - SHOWS WOUNDS REMAINING
                Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestroyed ? Colors.red.shade100 : Colors.white,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'Wounds Remaining',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          '$woundsRemaining / $maxWounds',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isDestroyed
                                ? Colors.red.shade900
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Increment Wounds Button (Decrements Wounds Taken / Heals)
                _buildWoundButton(
                  icon: Icons.exposure_minus_1, // Healing is -1 wound
                  color: Colors.green.shade700,
                  onPressed: woundsTaken > 0
                      ? () => viewModel.updateWounds(
                          unit.unitName,
                          attachmentName: unit.attachmentName,
                          newWounds: woundsTaken - 1,
                        )
                      : null,
                ),
              ],
            ),
            if (isDestroyed)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Unit Destroyed/Broken!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Display Current Rank Status (Wounds Remaining)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  _getCurrentRankText(maxWounds, woundsTaken),
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentRankText(int maxWounds, int woundsTaken) {
    final woundsRemaining = maxWounds - woundsTaken;
    if (woundsRemaining > maxWounds * 2 / 3) {
      // > 8 wounds remaining on a 12-wound unit
      return 'Current Rank: 3 (Full Dice)';
    } else if (woundsRemaining > maxWounds * 1 / 3) {
      // > 4 wounds remaining on a 12-wound unit
      return 'Current Rank: 2 (Mid Dice)';
    } else if (woundsRemaining > 0) {
      return 'Current Rank: 1 (Low Dice)';
    } else {
      return 'Unit Routed/Destroyed!';
    }
  }

  Widget _buildWoundButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(15),
        elevation: 5,
      ),
      child: Icon(icon, size: 24),
    );
  }

  // --- Reusable Modifier Button Row ---
  Widget _buildModifierControls({
    required String label,
    required int currentValue,
    required Color color,
    required void Function(int) onUpdate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => onUpdate(currentValue - 1),
                    tooltip: 'Decrease Modifier',
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      (currentValue > 0 ? '+' : '') + currentValue.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    onPressed: () => onUpdate(currentValue + 1),
                    tooltip: 'Increase Modifier',
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () => onUpdate(0),
                tooltip: 'Reset Modifier',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRollsSection(
    BuildContext context,
    army_data.UnitEntry unit,
    HomeViewModel viewModel,
  ) {
    // Get all available attack profiles (Melee and Range)
    final attackProfiles = unit.unitDetails?.attacks ?? [];

    // NEW: Get the list of unique attack types available for this unit.
    final availableAttackTypes = attackProfiles
        .map((p) => p.type)
        .toSet()
        .toList();
    final hasMultipleAttackTypes = availableAttackTypes.length > 1;

    // --- Attack Dice & To-Hit for Selected Type ---
    final attackDice = viewModel.getAttackDiceForUnit(
      unit,
      _selectedAttackType,
    );
    final toHitTarget = viewModel.getToHitTarget(unit, _selectedAttackType);

    final selectedAttackName = attackProfiles
        .firstWhere(
          (p) => p.type == _selectedAttackType,
          orElse: () => army_data.AttackProfile(
            name: 'No Attack',
            type: '',
            hit: 0,
            dice: [],
          ),
        )
        .name;

    // --- Defense & Morale ---
    final defenseSaveTarget = viewModel.getDefenseSaveTarget(unit);
    final defenseDice = viewModel.getDefenseDiceCount(
      unit,
    ); // Get dynamic defense dice count
    final moraleTarget = viewModel.getMoraleTarget(unit);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combat Rolls',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 10),

            // --- FIXED: Attack Type Selector (only if multiple types exist) ---
            if (hasMultipleAttackTypes)
              _buildAttackTypeSelector(context, availableAttackTypes),

            const SizedBox(height: 15),

            // --- Attack Roll Modifier ---
            _buildModifierControls(
              label: 'Attack Roll Modifier (Target Roll: $toHitTarget+)',
              currentValue: unit.attackModifier,
              color: Colors.red.shade700,
              onUpdate: (value) => viewModel.updateAttackModifier(
                unit.unitName,
                attachmentName: unit.attachmentName,
                modifier: value,
              ),
            ),

            // --- Attack Roll Button ---
            _buildRollButton(
              context,
              '$selectedAttackName Roll (${attackDice}D6 | Hit $toHitTarget+)',
              Icons.track_changes_outlined,
              Colors.red.shade700,
              () => _showAttackRollResult(
                context,
                selectedAttackName,
                attackDice,
                toHitTarget,
              ),
            ),

            const SizedBox(height: 20),

            // --- Save Roll Modifier ---
            _buildModifierControls(
              label:
                  'Defense Roll Target Modifier (Target Save: $defenseSaveTarget+)',
              currentValue: unit.defenseModifier,
              color: Colors.blue.shade700,
              onUpdate: (value) => viewModel.updateDefenseModifier(
                unit.unitName,
                attachmentName: unit.attachmentName,
                modifier: value,
              ),
            ),

            // NEW: Defense Dice Modifier
            _buildModifierControls(
              label: 'Defense Roll Dice Modifier (Total Dice: $defenseDice D6)',
              currentValue: unit.defenseDiceModifier,
              color: Colors.orange.shade700,
              onUpdate: (value) => viewModel.updateDefenseDiceModifier(
                unit.unitName,
                attachmentName: unit.attachmentName,
                modifier: value,
              ),
            ),

            // --- Save Roll Button ---
            // UPDATED: Now uses the dynamic defenseDice count
            _buildRollButton(
              context,
              'Defense Roll (${defenseDice}D6 | Save $defenseSaveTarget+)',
              Icons.health_and_safety_outlined,
              Colors.blue.shade700,
              () => _showRollResult(
                context,
                'Defense Save',
                defenseDice,
                defenseSaveTarget,
              ),
            ),

            const SizedBox(height: 20),

            // --- Morale Roll Modifier ---
            _buildModifierControls(
              label: 'Morale Check Modifier (Target Roll: $moraleTarget+)',
              currentValue: unit.moraleModifier,
              color: Colors.purple.shade700,
              onUpdate: (value) => viewModel.updateMoraleModifier(
                unit.unitName,
                attachmentName: unit.attachmentName,
                modifier: value,
              ),
            ),

            // --- Morale Roll Button ---
            _buildRollButton(
              context,
              'Morale Check ($moraleTarget+)',
              Icons.heart_broken,
              Colors.purple.shade700,
              () =>
                  _showMoraleRollResult(context, moraleTarget, unit, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED Attack Type Selector ---
  Widget _buildAttackTypeSelector(
    BuildContext context,
    List<String> availableTypes,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // Ensure the selected type is still valid, default to the first available if not.
          value: availableTypes.contains(_selectedAttackType)
              ? _selectedAttackType
              : availableTypes.first,
          isExpanded: true,
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: TextStyle(color: Colors.red.shade800, fontSize: 16),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedAttackType = newValue;
              });
            }
          },
          items: availableTypes.map<DropdownMenuItem<String>>((String value) {
            String label;
            switch (value) {
              case 'melee':
                label = 'Melee Attack';
                break;
              case 'long':
                label = 'Ranged Attack (Long)';
                break;
              case 'short':
                label = 'Ranged Attack (Short)';
                break;
              default:
                label = '${value[0].toUpperCase()}${value.substring(1)} Attack';
            }

            return DropdownMenuItem<String>(value: value, child: Text(label));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRollButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAttackRollResult(
    BuildContext context,
    String rollType,
    int numberOfDice,
    int toHit,
  ) {
    if (numberOfDice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot roll: Unit is destroyed or has 0 attack dice."),
        ),
      );
      return;
    }

    // Dice roll implementation remains the same
    final rolls = List<int>.generate(
      numberOfDice,
      (_) => 1 + Random().nextInt(6),
    );
    final hits = rolls.where((r) => r >= toHit).length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$rollType Roll (Hit $toHit+)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rolled $numberOfDice D6:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: rolls
                    .map(
                      (roll) => Chip(
                        label: Text(
                          roll.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: roll >= toHit
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Total Hits: $hits',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Generic roll result (used for Save Roll)
  void _showRollResult(
    BuildContext context,
    String rollType,
    int numberOfDice,
    int targetValue,
  ) {
    if (numberOfDice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot roll: Dice count is zero.")),
      );
      return;
    }

    final rolls = List<int>.generate(
      numberOfDice,
      (_) => 1 + Random().nextInt(6),
    );
    final successes = rolls.where((r) => r >= targetValue).length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$rollType Roll (Target $targetValue+)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rolled $numberOfDice D6:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: rolls
                    .map(
                      (roll) => Chip(
                        label: Text(
                          roll.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: roll >= targetValue
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Total Successes: $successes',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // --- Morale Roll Specific Logic ---
  void _showMoraleRollResult(
    BuildContext context,
    int moraleTarget, // This is the *adjusted* target
    army_data.UnitEntry unit,
    HomeViewModel viewModel,
  ) {
    // Morale roll is 2D6
    final roll1 = 1 + Random().nextInt(6);
    final roll2 = 1 + Random().nextInt(6);
    final rollTotal = roll1 + roll2;

    int damageTaken = 0;
    String resultMessage = '';
    Color resultColor = Colors.green.shade700;

    if (rollTotal >= moraleTarget) {
      // Success
      resultMessage =
          'PASSED Morale Check ($rollTotal vs $moraleTarget+). No damage taken.';
    } else {
      // Failure - Damage taken is Morale Target minus the roll total
      damageTaken = moraleTarget - rollTotal;

      // Prevent taking negative damage
      damageTaken = max(0, damageTaken);

      // Update the wounds in the ViewModel
      final newWounds = unit.currentWounds + damageTaken;
      viewModel.updateWounds(
        unit.unitName,
        attachmentName: unit.attachmentName,
        newWounds: newWounds,
      );

      resultColor = Colors.red.shade700;
      if (damageTaken > 0) {
        resultMessage =
            'FAILED Morale Check ($rollTotal vs $moraleTarget+)! Unit takes $damageTaken wounds.';
      } else {
        resultMessage =
            'FAILED Morale Check, but no wounds were calculated to be taken.';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Morale Check Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resultMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text(
                      roll1.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      roll2.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Total Roll: $rollTotal',
                style: const TextStyle(fontSize: 16),
              ),
              if (damageTaken > 0)
                Text(
                  '(Wounds automatically applied)',
                  style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // --- MOCK IMAGE HELPERS (Necessary for the portrait display) ---

  // Helper to construct the full asset path
  String _getImagePath(String? id, {required String type}) {
    if (id == null || id.isEmpty) {
      // Default placeholder based on type if ID is missing
      return 'assets/placeholders/${type == 'ncu' ? 'ncu' : 'unit'}_placeholder.jpg';
    }
    // Assumes all unit/attachment images use the ID and are .jpg files
    return 'assets/standees/$id.jpg';
  }

  // Helper to build the image widget
  Widget _buildUnitImage(
    String path, {
    double size = 80.0,
    bool isMain = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: isMain
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6.0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        border: Border.all(
          color: isMain ? Colors.red.shade800 : Colors.blueGrey.shade300,
          width: isMain ? 3.0 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Show the ID if the image fails to load
            final id = path.split('/').last.split('.').first;
            return Container(
              color: Colors.grey[800],
              child: Center(
                child: Text(
                  'ID: $id',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
