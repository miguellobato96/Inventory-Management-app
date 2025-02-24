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
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load inventory');
    }
  }
}
