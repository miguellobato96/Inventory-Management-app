import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inventory_flutter/models/user_model.dart';

class UserService {
  final String baseUrl = 'http://localhost:3000/auth';
  final storage = const FlutterSecureStorage();

  Future<List<UserModel>> fetchAllUsers() async {
    final jwt = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      print("Failed to fetch users: ${response.statusCode}");
      return [];
    }
  }

  Future<String?> getUserEmail() async {
    final jwt = await storage.read(key: 'jwt');
    if (jwt == null) return null;

    final response = await http.get(
      Uri.parse('http://localhost:3000/auth/email'),
      headers: {'Authorization': 'Bearer $jwt'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['email'];
    }

    return null;
  }
}
