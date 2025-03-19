import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExportService {
  static const String _baseUrl = "http://localhost:3000";

  // Retrieve JWT Token
  static Future<String?> getToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt'); // Retrieve stored JWT
  }

  // Fetch the logged-in user's email
  static Future<String?> getUserEmail() async {
    final String? token = await getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final response = await http.get(
      Uri.parse("$_baseUrl/auth/user"), // Ensure correct backend route
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["email"];
    } else {
      throw Exception("Failed to fetch user email: ${response.body}");
    }
  }

  // Export inventory using logged-in user's email
  static Future<Map<String, dynamic>> exportInventory({
    required String format,
    int? categoryId,
    required String sortBy,
    required String order,
    bool lowStockOnly = false,
  }) async {
    final String? token = await getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final String? email = await getUserEmail(); // Auto-fetch email
    if (email == null) throw Exception("User email not found");

    final response = await http.post(
      Uri.parse("$_baseUrl/inventory/export"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "format": format,
        "email": email,
        "category_id": categoryId,
        "sort_by": sortBy,
        "order": order,
        "low_stock_only": lowStockOnly,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to export: ${response.body}");
    }
  }
}
