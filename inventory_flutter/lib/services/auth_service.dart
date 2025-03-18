import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://localhost:3000/auth';
  final storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'jwt', value: data['token']); // Store JWT
      await storage.write(
        key: 'user_email',
        value: data['email'],
      ); // Store email
      await storage.write(key: 'user_role', value: data['role']); // Store role

      return true;
    } else {
      return false;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt');
    await storage.delete(key: 'user_email');
    await storage.delete(key: 'user_role');
  }

  static Future<String?> getUserEmail() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: "user_email"); // Read stored email
  }

  Future<String?> getUserRole() async {
    return await storage.read(key: 'user_role');
  }
}
