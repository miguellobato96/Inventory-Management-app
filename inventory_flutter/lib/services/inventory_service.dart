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
      ); // ✅ Sort alphabetically
      return items;
    } else {
      throw Exception('Failed to load inventory');
    }
  }

  Future<List<dynamic>> getMainCategories() async {
    final token = await storage.read(key: 'jwt'); // Retrieve stored token
    print(
      "Using Token in Flutter: $token",
    ); // Debug: Check if Flutter is using a token

    final response = await http.get(
      Uri.parse('$baseUrl/categories/main'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Check if token is included
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
    final token = await storage.read(key: 'jwt'); // Retrieve stored token
    print("Fetching subcategories for categoryId: $categoryId");
    print("Using Token for Subcategories: $token");

    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId/subcategories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Ensure token is sent
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

  // Add a new item
  Future<bool> addItem(
    String name,
    int categoryId,
    int quantity,
    int locationId,
  ) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.post(
      Uri.parse('$baseUrl/inventory'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "name": name,
        "category_id": categoryId,
        "quantity": quantity,
        "location_id": locationId,
      }),
    );

    return response.statusCode == 201;
  }

  // Delete an item by ID
  Future<bool> deleteItem(int id) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.delete(
      Uri.parse('$baseUrl/inventory/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 204;
  }

  // Update an existing item
  Future<bool> updateItem(
    int id,
    String name,
    int categoryId,
    int quantity,
    int locationId,
  ) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.put(
      Uri.parse('$baseUrl/inventory/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "name": name,
        "category_id": categoryId,
        "quantity": quantity,
        "location_id": locationId,
      }),
    );

    return response.statusCode == 200;
  }
}
