import 'package:flutter/foundation.dart';
import 'package:squire/data/model/Army_list/Army_unit_data.dart';
import 'package:squire/data/services/unit_details_service.dart';
import 'package:squire/data/services/army_list_parser.dart';

class UnitRepository {
  final UnitDetailsService _detailsService;
  final ArmyListParser _parserService;

  UnitRepository(this._detailsService, this._parserService);

  // Helper: Aggressively normalizes a name (removes all non-alphanumeric chars)
  String _normalizeNameForBackend(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  // Helper: Safely generate the unit's full name for comparison
  String _getUnitFullName(ArmyUnitData data) {
    final name = (data.name ?? '').trim();
    final title = (data.title ?? '').trim();

    if (name.isEmpty) {
      return title;
    }

    if (title.isNotEmpty) {
      return '$name - $title';
    }

    return name;
  }

  Future<ListPa> parseListAndFetchDetails(String rawArmyListText) async {
    // 1. Parse the raw text to get unit names and faction
    final ListPa parsedList = _parserService.parseArmyList(rawArmyListText);

    if (parsedList.commanderName.isEmpty &&
        parsedList.combatUnits.isEmpty &&
        parsedList.ncus.isEmpty) {
      throw Exception(
        'Parser failed to identify any units or commanders. Check list format.',
      );
    }

    // 2. Extract all names needed for the backend lookup
    final List<String> namesToFetch = [];

    // Use commanderName from the updated ListPa structure
    if (parsedList.commanderName.isNotEmpty) {
      namesToFetch.add(parsedList.commanderName);
    }
    for (final unit in parsedList.combatUnits) {
      namesToFetch.add(unit.unitName);
      if (unit.attachmentName != null) {
        namesToFetch.add(unit.attachmentName!);
      }
    }
    for (final ncu in parsedList.ncus) {
      namesToFetch.add(ncu.unitName);
    }
    final uniqueNamesToFetch = namesToFetch.toSet().toList();

    try {
      // 3. Fetch details for the extracted unit names
      List<ArmyUnitData> unitDetails = await _detailsService.fetchUnitDetails(
        parsedList.faction,
        uniqueNamesToFetch,
      );

      // Filter out any null elements returned in the list array
      unitDetails = unitDetails.where((data) => data != null).toList();

      if (kDebugMode) {
        print('Total API details fetched: ${unitDetails.length}');
        for (var detail in unitDetails) {
          print(
            '  -> Available API Name: ${_getUnitFullName(detail)} (ID: ${detail.id})',
          );
        }
      }

      // 4. Map fetched details back into the ListPa structure
      List<UnitEntry> detailedCombatUnits = [];
      List<UnitEntry> detailedNCUs = [];

      ArmyUnitData? findDetails(String name) {
        final normalizedSearchName = name.trim();
        // This is the normalized key from the user's parsed list (e.g., 'starkswornswords')
        final normalizedSearchKey = _normalizeNameForBackend(
          normalizedSearchName,
        );

        if (kDebugMode) {
          print(
            '\n--- Searching for unit: "$normalizedSearchName" (Key: $normalizedSearchKey) ---',
          );
        }

        for (final data in unitDetails) {
          final dataFullName = _getUnitFullName(data);
          final dataBaseName = (data.name ?? '').trim();
          final dataTitle = (data.title ?? '').trim();

          // Get the normalized keys from the API data
          final normalizedDataFullName = _normalizeNameForBackend(dataFullName);
          final normalizedDataBaseName = _normalizeNameForBackend(dataBaseName);

          // 1. BEST MATCH: Exact match on the FULL normalized name
          if (normalizedDataFullName == normalizedSearchKey) {
            if (kDebugMode) {
              print(
                '✅ Matched by FULL Normalized Name: $dataFullName (ID: ${data.id})',
              );
            }
            return data;
          }

          // 2. SECOND BEST MATCH: Exact match on the BASE normalized name
          if (normalizedDataBaseName == normalizedSearchKey) {
            if (kDebugMode) {
              print(
                '✅ Matched by BASE Normalized Name: $dataBaseName (ID: ${data.id})',
              );
            }
            return data;
          }

          // 3. Fallback/Substring Match (For complex names where the parser might grab too much/little)
          // Checks if the search key contains the API unit's base name and (if applicable) its title.
          if (dataBaseName.isNotEmpty &&
              normalizedSearchKey.contains(normalizedDataBaseName)) {
            bool titleMatches = true;
            if (dataTitle.isNotEmpty) {
              final normalizedDataTitle = _normalizeNameForBackend(dataTitle);
              if (!normalizedSearchKey.contains(normalizedDataTitle)) {
                titleMatches = false;
              }
            }
            if (titleMatches) {
              if (kDebugMode) {
                print(
                  '✅ Matched by SUBSTRING (Fallback): $dataFullName (ID: ${data.id})',
                );
              }
              return data;
            }
          }
        }

        if (kDebugMode) {
          print(
            '❌ FAILED to find details for: "$normalizedSearchName". Unit will show no image/details.',
          );
        }
        return null;
      }

      // 4.1. Get Commander Details
      ArmyUnitData? commanderDetail;
      if (parsedList.commanderName.isNotEmpty) {
        commanderDetail = findDetails(parsedList.commanderName);
      }

      // 4.2. Map Combat Units
      for (final unit in parsedList.combatUnits) {
        final unitDetail = findDetails(unit.unitName);
        ArmyUnitData? attachDetail;

        // Find the detail for the commander/attachment name
        if (unit.attachmentName != null) {
          attachDetail = findDetails(unit.attachmentName!);
        }

        detailedCombatUnits.add(
          unit.copyWith(
            unitDetails: unitDetail,
            attachmentDetails: attachDetail,
          ),
        );
      }

      // 4.3. Map NCUs
      for (final ncu in parsedList.ncus) {
        final ncuDetail = findDetails(ncu.unitName);
        detailedNCUs.add(ncu.copyWith(unitDetails: ncuDetail));
      }

      // 5. Final check and return
      return parsedList.copyWith(
        // NOW assigning the commander details
        commanderDetails: commanderDetail,
        combatUnits: detailedCombatUnits,
        ncus: detailedNCUs,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching unit details in repository: $e');
      }
      rethrow;
    }
  }
}
