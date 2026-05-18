import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiService {
  static String? _token;
  static void setToken(String? token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // 🔐 LOGIN (AÑADIDO PARA CORREGIR EL ERROR)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse(AppConfig.endpointLogin),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['token']; // Guarda el JWT para futuras peticiones
      return data; // Retorna { token, user: {...} }
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Credenciales inválidas');
  }

  // ✅ Helper reutilizable para listas
  static Future<List<Map<String, dynamic>>> _fetchList(
    String url,
    String key,
  ) async {
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data[key] ?? []);
    }
    throw Exception('Error al cargar $key');
  }

  static Future<List<Map<String, dynamic>>> getInventory() =>
      _fetchList(AppConfig.endpointInventory, 'products');
  static Future<List<Map<String, dynamic>>> getCategories() =>
      _fetchList(AppConfig.endpointCategories, 'categories');
  static Future<List<Map<String, dynamic>>> getSuppliers() =>
      _fetchList(AppConfig.endpointSuppliers, 'suppliers');
  static Future<List<Map<String, dynamic>>> getWarehouses() =>
      _fetchList(AppConfig.endpointWarehouses, 'warehouses');

  // ✅ CREACIÓN DE PRODUCTO (con supplierId opcional)
  static Future<void> addProduct({
    required String name,
    required String sku,
    required int quantity,
    required String categoryId,
    required String warehouseId,
    String? supplierId, // ✅ AÑADIDO
    String? imageBase64,
  }) async {
    final body = {
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'category_id': categoryId,
      'warehouse_id': warehouseId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (imageBase64 != null) 'image_base64': imageBase64,
    };

    final res = await http.post(
      Uri.parse(AppConfig.endpointInventory),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Error al crear producto');
    }
  }

  // ✅ ACTUALIZAR PRODUCTO CON AUDITORÍA
  static Future<void> updateProduct({
    required String id,
    String? name,
    String? sku,
    int? quantity,
    String? categoryId,
    String? imageBase64,
  }) async {
    // Solo envía campos modificados. Backend ignora nulls gracias a omitempty
    final body = {
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (quantity != null) 'quantity': quantity,
      if (categoryId != null) 'category_id': categoryId,
      if (imageBase64 != null) 'image_base64': imageBase64,
    };

    final res = await http.put(
      Uri.parse('${AppConfig.endpointInventory}/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Error al actualizar producto');
    }
  }

  static Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await http.get(
      Uri.parse('${AppConfig.endpointTransactions}?page=$page&limit=$limit'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al cargar historial de movimientos');
  }
}
