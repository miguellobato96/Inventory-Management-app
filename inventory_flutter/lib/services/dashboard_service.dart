import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardService {
  final String baseUrl = "http://localhost:3000";
  final storage = const FlutterSecureStorage();

  // Retrieve JWT Token
  static Future<String?> getToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt');
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      String? token =
          await getToken();

      if (token == null || token.isEmpty) {
        print("No token found in storage");
        throw Exception("Unauthorized: No token available");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/inventory/dashboard"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Failed response: ${response.body}");
        throw Exception(
          "Failed to load dashboard data: ${response.statusCode}",
        );
      }
    } catch (error) {
      print("Dashboard API Error: $error");
      throw Exception("Error fetching dashboard data: $error");
    }
  }
}
