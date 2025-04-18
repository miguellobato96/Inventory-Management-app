import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inventory_flutter/models/user_model.dart';
import 'package:inventory_flutter/models/unit_model.dart';

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

  Future<List<UnitModel>> getUserUnits() async {
    final jwt = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('http://localhost:3000/units/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UnitModel.fromJson(json)).toList();
    } else {
      print("Failed to fetch user units: ${response.statusCode}");
      return [];
    }
  }

  Future<UnitModel?> createUnit(String name) async {
    final jwt = await storage.read(key: 'jwt');
    final response = await http.post(
      Uri.parse('http://localhost:3000/units'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UnitModel.fromJson(data);
    } else {
      print("Failed to create unit: ${response.statusCode}");
      return null;
    }
  }

  Future<UnitModel?> updateUnit(int id, String name) async {
    final jwt = await storage.read(key: 'jwt');
    final response = await http.put(
      Uri.parse('http://localhost:3000/units/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UnitModel.fromJson(data);
    } else {
      print("Failed to update unit: ${response.statusCode}");
      return null;
    }
  }

  Future<void> deleteUnit(int id) async {
    final jwt = await storage.read(key: 'jwt');
    final response = await http.delete(
      Uri.parse('http://localhost:3000/units/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode != 200) {
      print("Failed to delete unit: ${response.statusCode}");
    }
  }

  Future<List<dynamic>> getUnitLiftHistory(int unitId) async {
    final jwt = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('http://localhost:3000/units/$unitId/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch lift history: ${response.statusCode}');
      return [];
    }
  }
}
