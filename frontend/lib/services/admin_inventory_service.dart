import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminInventoryService {
  final storage = const FlutterSecureStorage();
  static final Dio _dio = Dio();
  static const _baseUrl = 'http://localhost:3000'; // Change if needed

  // Get JWT token from secure storage
  static Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt');
  }

  // ========================================
  //                 ITEMS
  // ========================================

  static Future<void> createItem({
    required String name,
    required int quantity,
    required int lowStockThreshold,
    int? categoryId,
    int? locationId,
  }) async {
    final token = await _getToken();
    final response = await _dio.post(
      '$_baseUrl/admin/items',
      data: {
        'name': name,
        'quantity': quantity,
        'low_stock_threshold': lowStockThreshold,
        'category_id': categoryId,
        'location_id': locationId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 201) {
      throw Exception("Erro ao criar item");
    }
  }

  static Future<void> updateItem({
    required int id,
    required String name,
    required int quantity,
    required int lowStockThreshold,
    int? categoryId,
    int? locationId,
  }) async {
    final token = await _getToken();
    final response = await _dio.put(
      '$_baseUrl/admin/items/$id',
      data: {
        'name': name,
        'quantity': quantity,
        'low_stock_threshold': lowStockThreshold,
        'category_id': categoryId,
        'location_id': locationId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar item");
    }
  }

  static Future<void> deleteItem(int id) async {
    final token = await _getToken();
    final response = await _dio.delete(
      '$_baseUrl/admin/items/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao eliminar item");
    }
  }

  // ========================================
  //               CATEGORIES
  // ========================================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final token = await _getToken();
    final response = await _dio.get(
      '$_baseUrl/categories/main',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200 && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else {
      throw Exception("Erro ao carregar categorias");
    }
  }

  static Future<List<Map<String, dynamic>>> getSubcategories(
    int parentId,
  ) async {
    final token = await _getToken();
    final response = await _dio.get(
      '$_baseUrl/categories/$parentId/subcategories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200 && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else {
      throw Exception("Erro ao carregar subcategorias");
    }
  }

  static Future<void> createCategory(String name, {int? parentId}) async {
    final token = await _getToken();
    final response = await _dio.post(
      '$_baseUrl/categories',
      data: {'name': name, 'parent_id': parentId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 201) {
      throw Exception("Erro ao criar categoria");
    }
  }

  static Future<void> updateCategory(int id, String newName) async {
    final token = await _getToken();
    final response = await _dio.put(
      '$_baseUrl/categories/$id',
      data: {'name': newName},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar categoria");
    }
  }

  static Future<void> deleteCategory(int id) async {
    final token = await _getToken();
    final response = await _dio.delete(
      '$_baseUrl/categories/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao eliminar categoria");
    }
  }

  // ========================================
  //                LOCATIONS
  // ========================================

  static Future<List<Map<String, dynamic>>> getLocations() async {
    final token = await _getToken();
    final response = await _dio.get(
      '$_baseUrl/locations',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200 && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else {
      throw Exception("Erro ao carregar localizações");
    }
  }

  static Future<void> createLocation(String name) async {
    final token = await _getToken();
    final response = await _dio.post(
      '$_baseUrl/locations',
      data: {'name': name},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 201) {
      throw Exception("Erro ao criar localização");
    }
  }

  static Future<void> updateLocation(int id, String newName) async {
    final token = await _getToken();
    final response = await _dio.put(
      '$_baseUrl/locations/$id',
      data: {'name': newName},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar localização");
    }
  }

  static Future<void> deleteLocation(int id) async {
    final token = await _getToken();
    final response = await _dio.delete(
      '$_baseUrl/locations/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao eliminar localização");
    }
  }
}
