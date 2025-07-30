import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InventoryService {
  final storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000'; // Change if needed

  // Fetch all inventory items
  Future<List<dynamic>> getInventoryItems() async {
    final token = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/inventory'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> items = jsonDecode(response.body);
      items.sort(
        (a, b) => a['name'].compareTo(b['name']),
      ); // Sort alphabetically
      return items;
    } else {
      throw Exception('Failed to load inventory');
    }
  }

  // Fetch main categories
  Future<List<dynamic>> getMainCategories() async {
    final token = await storage.read(key: 'jwt');
    print(
      "Using Token in Flutter: $token",
    ); // Debug: Check if Flutter is using a token

    final response = await http.get(
      Uri.parse('$baseUrl/categories/main'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("API Response Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> categories = jsonDecode(response.body);
      categories.sort((a, b) => a['name'].compareTo(b['name']));
      return categories;
    } else {
      throw Exception('Failed to load main categories');
    }
  }

  // Fetch subcategories of a selected category
  Future<List<dynamic>> getSubcategories(int categoryId) async {
    final token = await storage.read(key: 'jwt');
    print("Fetching subcategories for categoryId: $categoryId");
    print("Using Token for Subcategories: $token");

    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId/subcategories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("Subcategories API Response Status: ${response.statusCode}");
    print("Subcategories API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        data.sort(
          (a, b) => a['name'].compareTo(b['name']),
        ); // Sort alphabetically
        print("Sorted subcategories: $data");
        return data;
      } else {
        print("No subcategories found for categoryId: $categoryId");
        return []; // Return an empty list if no subcategories exist
      }
    } else {
      print("Error fetching subcategories: ${response.statusCode}");
      throw Exception('Failed to load subcategories');
    }
  }

  // Fetch inventory history
  Future<List<dynamic>> getInventoryHistory() async {
    final token = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/inventory/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load inventory history');
    }
  }

  // Get current lift for a specific unit (UC)
  Future<List<dynamic>> getUnitLift(int unitId) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/inventory/lift/$unitId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load unit lift');
    }
  }

  // Clear the current lift for a specific unit (UC)
  Future<void> clearUnitLift(int unitId) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.delete(
      Uri.parse('$baseUrl/inventory/lift/$unitId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear unit lift');
    }
  }

  // Confirm item lift for a unit (UC)
  Future<bool> confirmItemLift({
    int? unitId,
    required int userId,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await storage.read(key: 'jwt');

    Map<String, dynamic> requestBody = {
      if (unitId != null) 'unitId': unitId,
      'userId': userId,
      'items': items,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/inventory/lift'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      print("Error confirming lift: ${response.body}");
      return false;
    }
  }

  // Mark selected items as damaged for a specific unit
  Future<void> markItemsAsDamaged({
    required int unitId,
    required List<Map<String, dynamic>> damagedItems,
  }) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.post(
      Uri.parse('$baseUrl/inventory/damaged'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'unitId': unitId,
        'items': damagedItems,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark items as damaged');
    }
  }

  // Get the last lift for a specific unit (UC)
  Future<List<dynamic>> getLastLiftForUnit(int unitId) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/inventory/last-lift/$unitId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch last lift for unit');
    }
  }

  // Return lift and mark damaged items
  Future<void> returnLift({
    required int liftId,
    required List<Map<String, dynamic>> damagedItems,
    required int userId,
    required int unitId,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.post(
      Uri.parse('$baseUrl/inventory/lifts/$liftId/return'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'items': items,
        'damagedItems': damagedItems,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to return lift');
    }
  }

  Future<List<Map<String, dynamic>>> getLiftItemsByLiftId(int liftId) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/inventory/lifts/$liftId/items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      print('❌ API error: ${response.body}');
      throw Exception('Failed to fetch lift items');
    }
  }

  Future<List<Map<String, dynamic>>> getAllDamagedItems() async {
    final token = await storage.read(key: 'jwt');
    
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/damaged-items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao obter itens danificados');
    }
  }
}
