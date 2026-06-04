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
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data[key] ?? []);
      }
    }
    throw Exception('Error al cargar $key');
  }

  static Future<List<Map<String, dynamic>>> getInventory({
    String? warehouseId,
  }) async {
    // ✅ Construye la URL con query param si hay filtro
    final uri = Uri.parse(AppConfig.endpointInventory).replace(
      queryParameters: warehouseId != null ? {'warehouse_id': warehouseId} : {},
    );

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      }
    }
    throw Exception('Error al obtener inventario');
  }

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

  // ✅ ROLES - CRUD completo alineado con roleController.go
  static Future<List<Map<String, dynamic>>> getRoles() async {
    final res = await http.get(
      Uri.parse(AppConfig.endpointRoles),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['roles'] ?? []);
      }
    }
    throw Exception('Error al cargar roles');
  }

  static Future<Map<String, dynamic>> createRole({
    required String name,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse(AppConfig.endpointRoles),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'description': description?.trim() ?? '',
      }),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['role'] as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al crear rol');
  }

  static Future<Map<String, dynamic>> updateRole({
    required String id,
    required String name,
    String? description,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConfig.endpointRoles}/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'description': description?.trim() ?? '',
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['role'] as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al actualizar rol');
  }

  static Future<void> deleteRole(String id) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.endpointRoles}/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      // Manejar error 409: rol en uso por usuarios
      if (res.statusCode == 409) {
        throw Exception(
          'No se puede eliminar: el rol está asignado a usuarios',
        );
      }
      throw Exception(err['error'] ?? 'Error al eliminar rol');
    }
  }

  static Future<void> createSupplier({
    required String name,
    String? contact,
    String? email,
    String? phone,
    String? address,
  }) async {
    final res = await http.post(
      Uri.parse(AppConfig.endpointSuppliers),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'contact': contact?.trim(),
        'email': email?.trim().toLowerCase(),
        'phone': phone?.trim(),
        'address': address?.trim(),
      }),
    );
    if (res.statusCode != 201) {
      throw _parseError(res.body, 'Error al crear proveedor');
    }
  }

  static Future<void> updateSupplier(
    String id, {
    String? name,
    String? contact,
    String? email,
    String? phone,
    String? address,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConfig.endpointSuppliers}/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name?.trim(),
        'contact': contact?.trim(),
        'email': email?.trim().toLowerCase(),
        'phone': phone?.trim(),
        'address': address?.trim(),
      }),
    );
    if (res.statusCode != 200) {
      throw _parseError(res.body, 'Error al actualizar proveedor');
    }
  }

  static Future<void> deleteSupplier(String id) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.endpointSuppliers}/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      // ✅ Manejo explícito del error 409: proveedor con productos asociados
      if (res.statusCode == 409) {
        throw Exception(
          err['error'] ?? 'No se puede eliminar: tiene productos asociados',
        );
      }
      throw _parseError(res.body, 'Error al eliminar proveedor');
    }
  }

  // 🛡️ Helper seguro para parsear errores (evita FormatException)
  static Exception _parseError(String body, String defaultMsg) {
    if (body.isEmpty) return Exception('$defaultMsg (respuesta vacía)');
    try {
      final data = jsonDecode(body);
      return Exception(data['error'] ?? data['message'] ?? defaultMsg);
    } catch (_) {
      return Exception(
        '$defaultMsg: ${body.length > 100 ? '${body.substring(0, 100)}...' : body}',
      );
    }
  }

  static Future<void> createCategory({
    required String name,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse(AppConfig.endpointCategories),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'description': description?.trim() ?? '',
      }),
    );
    if (res.statusCode != 201) {
      throw _parseError(res.body, 'Error al crear categoría');
    }
  }

  static Future<void> updateCategory(
    String id, {
    String? name,
    String? description,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConfig.endpointCategories}/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name?.trim(),
        'description': description?.trim(),
      }),
    );
    if (res.statusCode != 200) {
      throw _parseError(res.body, 'Error al actualizar categoría');
    }
  }

  static Future<void> deleteCategory(String id) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.endpointCategories}/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      // Manejar error 409: categoría con productos asociados
      if (res.statusCode == 409)
        throw Exception('No se puede eliminar: existen productos asociados');
      throw _parseError(res.body, 'Error al eliminar categoría');
    }
  }

  static Future<void> createWarehouse({
    required String name,
    String? location,
  }) async {
    final res = await http.post(
      Uri.parse(AppConfig.endpointWarehouses),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'location': location?.trim() ?? '',
      }),
    );
    if (res.statusCode != 201) {
      throw _parseError(res.body, 'Error al crear almacén');
    }
  }

  static Future<void> updateWarehouse(
    String id, {
    String? name,
    String? location,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConfig.endpointWarehouses}/$id'),
      headers: _headers,
      body: jsonEncode({'name': name?.trim(), 'location': location?.trim()}),
    );
    if (res.statusCode != 200) {
      throw _parseError(res.body, 'Error al actualizar almacén');
    }
  }

  static Future<void> deleteWarehouse(String id) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.endpointWarehouses}/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      // ✅ Manejo específico del error 409: almacén con stock activo
      if (res.statusCode == 409 ||
          (err['error'] as String?).toString().contains('stock')) {
        throw Exception(
          'No se puede eliminar: el almacén contiene productos con stock activo',
        );
      }
      throw _parseError(res.body, 'Error al eliminar almacén');
    }
  }
}
