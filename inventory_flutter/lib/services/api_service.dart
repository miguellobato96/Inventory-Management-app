import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  final String baseUrl = 'http://YOUR_IP_ADDRESS:3000';

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      await storage.write(key: 'jwt', value: token);
      return true;
    }
    return false;
  }
}
