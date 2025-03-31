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

  // Adjust item quantity by adding or taking stock
  Future<Map<String, dynamic>?> adjustItemQuantity(
    int itemId,
    int quantityChange,
  ) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.post(
      Uri.parse('$baseUrl/inventory/adjust-quantity'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'itemId': itemId, 'quantityChange': quantityChange}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['item']; // Return updated item including location
    } else {
      print('Error adjusting item quantity: ${response.body}');
      return null;
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
}
