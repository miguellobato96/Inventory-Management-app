import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminUserService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/admin/users',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final _storage = const FlutterSecureStorage();

  // Inject token from secure storage before each request
  Future<void> _setAuthHeader() async {
    final token = await _storage.read(key: 'jwt');
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    await _setAuthHeader();
    final response = await _dio.get('/');
    return response.data;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    await _setAuthHeader();
    final response = await _dio.post('/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    await _setAuthHeader();
    final response = await _dio.put('/$userId', data: data);
    return response.data;
  }

  Future<void> deleteUser(int userId) async {
    await _setAuthHeader();
    await _dio.delete('/$userId');
  }

  Future<List<dynamic>> getUserHistory(int userId) async {
    await _setAuthHeader();
    final response = await _dio.get('/$userId/history');
    return response.data;
  }
}
