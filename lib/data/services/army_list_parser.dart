import 'package:flutter/foundation.dart';
import 'package:squire/data/model/Army_list/Army_unit_data.dart';
import 'package:squire/data/services/unit_details_service.dart';

// Assuming ListPa and UnitEntry are defined in the imported files.

class ArmyListParser {
  ListPa parseArmyList(String rawList) {
    if (kDebugMode) {
      print('\n--- PARSER DEBUG START ---');
      print('Raw List Input:\n$rawList');
    }

    final lines = rawList.split('\n');
    String faction = '';
    String commander = '';
    int totalPoints = 0;
    int totalActivations = 0;
    List<UnitEntry> combatUnits = [];
    List<UnitEntry> ncus = [];

    // State machine variables
    bool inCombatUnits = false;
    bool inNCUs = false;

    // Helper to extract Name and Cost from a line (e.g., "• Unit Name (6)")
    Map<String, dynamic> _extractNameAndCost(String line) {
      // 1. Extract Cost and Name (based on the last parenthetical)
      final costRegex = RegExp(r'\s*\(([^)]+)\)[^\)]*$');
      final match = costRegex.firstMatch(line);

      int cost = 0;
      String namePart = line;

      if (match != null) {
        // Extract cost from the match (remove all non-digits)
        final costString = match.group(1)?.replaceAll(RegExp(r'[^\d]'), '');
        cost = int.tryParse(costString ?? '0') ?? 0;

        // Use everything before the cost parenthetical as the name part
        namePart = line.substring(0, match.start).trim();
      } else {
        // If no cost found, use the whole line
        namePart = line.trim();
      }

      // 2. Clean up common list markers (•, -, with, etc.)
      // Remove starting bullet points and spaces
      namePart = namePart.replaceAll(RegExp(r'^[•\-\s]+', multiLine: true), '');

      // Remove "with " only if it's at the very beginning of the cleaned string
      namePart = namePart.replaceFirst(
        RegExp(r'^with\s*', caseSensitive: false),
        '',
      );

      // CRITICAL FIX: Aggressively trim again to remove any leading/trailing spaces left
      final name = namePart.trim();

      return {'name': name, 'cost': cost};
    }

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 1. Check for Faction, Commander, Points, Activations
      if (line.startsWith('Faction :')) {
        faction = line.split(':').last.trim();
      } else if (line.startsWith('Commander :')) {
        // Commander line often contains extra text like "| Points: X"
        commander = line.split(':').last.split(' |').first.trim();
      } else if (line.startsWith('Points :')) {
        final pointsMatch = RegExp(r'Points : (\d+)').firstMatch(line);
        totalPoints = int.tryParse(pointsMatch?.group(1) ?? '0') ?? 0;
      } else if (line.startsWith('Activations :')) {
        totalActivations = int.tryParse(line.split(':').last.trim()) ?? 0;
      }
      // 2. State Machine Transition
      else if (line.startsWith('Units :')) {
        inCombatUnits = true;
        inNCUs = false;
        continue;
      } else if (line.startsWith('Non-Combat Unit :')) {
        inCombatUnits = false;
        inNCUs = true;
        continue;
      }
      // 3. Unit/NCU Parsing
      else if (line.startsWith('•') || line.startsWith('with ')) {
        final unitData = _extractNameAndCost(line);
        final name = unitData['name'] as String;
        final cost = unitData['cost'] as int;

        if (inCombatUnits) {
          if (line.startsWith('•')) {
            // New Combat Unit entry
            combatUnits.add(
              UnitEntry.combatUnit(unitName: name, unitCost: cost),
            );
          } else if (line.startsWith('with ')) {
            // Attachment for the last combat unit
            if (combatUnits.isNotEmpty) {
              final lastUnit = combatUnits.last;

              // CRITICAL FIX: The name here should be the ATTACHMENT name,
              // and the logic is now cleaner after being processed by _extractNameAndCost
              combatUnits[combatUnits.length - 1] = lastUnit.copyWith(
                attachmentName: name,
                attachmentCost: cost,
              );
            }
          }
        } else if (inNCUs) {
          // NCU entry
          ncus.add(UnitEntry.ncu(unitName: name, unitCost: cost));
        }
      }
    }

    // Sanity check debug logs
    if (kDebugMode) {
      print('Parsed Faction: $faction');
      print('Parsed Commander: $commander');
      print(
        'Parsed Combat Units (${combatUnits.length}): ${combatUnits.map((u) => u.unitName + (u.attachmentName != null ? ' (w/ ' + u.attachmentName! + ')' : '')).toList()}',
      );
      print(
        'Parsed NCUs (${ncus.length}): ${ncus.map((u) => u.unitName).toList()}',
      );
      print('--- PARSER DEBUG END ---\n');
    }

    return ListPa(
      faction: faction,
      commanderName: commander,
      totalPoints: totalPoints,
      totalActivations: totalActivations,
      combatUnits: combatUnits,
      ncus: ncus,
    );
  }
}
