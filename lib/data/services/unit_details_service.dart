import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:squire/data/model/Army_list/Army_unit_data.dart';

class UnitDetailsService {
  // Keeping 127.0.0.1 for web, but be aware of mobile limitations.
  final String _baseUrl = 'http://127.0.0.1:8080';

  /// Fetches detailed stat blocks for a list of unit/attachment names from the backend.
  Future<List<ArmyUnitData>> fetchUnitDetails(
    String faction,
    List<String> unitNames,
  ) async {
    final url = Uri.parse('$_baseUrl/api/units/details');

    final body = jsonEncode({'faction': faction, 'names': unitNames});

    if (kDebugMode) {
      print('--- NETWORK REQUEST START ---');
      print('Attempting POST to: $url');
      print('Request Body: $body');
      print('---------------------------');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Successful parsing logic...
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<ArmyUnitData> results = [];
        // ... (remaining parsing logic for 200 remains the same)
        data.forEach((role, list) {
          if (list is List) {
            for (final json in list) {
              try {
                results.add(ArmyUnitData.fromJson(json));
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing ArmyUnitData for $role: $e');
                }
              }
            }
          }
        });

        if (kDebugMode) {
          print(
            'Successfully fetched and parsed ${results.length} unit details.',
          );
        }

        return results;
      } else {
        final errorBody = response.body;
        // Logs a non-200 response from the server
        if (kDebugMode) {
          print(
            'Server responded with non-200 status: ${response.statusCode}. Body: $errorBody',
          );
        }
        throw Exception(
          'Failed to load unit details. Status: ${response.statusCode}. Error: $errorBody',
        );
      }
    } catch (e, stacktrace) {
      // 🛑 CRITICAL DEBUGGING LINE: Catching ALL network errors and rethrowing.
      if (kDebugMode) {
        print(
          '🛑 FATAL NETWORK ERROR: Failed to connect to $_baseUrl. The server is not reachable. Error: $e',
        );
        print('STACKTRACE: $stacktrace');
        print(
          'Check your network connection and ensure the backend is running at http://0.0.0.0:8080.',
        );
      }
      rethrow;
    }
  }
}
