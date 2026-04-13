import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  // ⚠️ For Android emulator use 10.0.2.2, for physical device use your PC IP
  final String baseUrl = "http://192.168.1.101:8080/api/v1";
  final AuthService _authService = AuthService();

  // Method to get the Tenant ID from the stored token
  Future<String?> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['tenant_id'];
    }
    return null;
  }

  // Helper to build auth headers (reduces duplication)
  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _authService.getToken();
    final String? tenantId = await getTenantId();

    if (token == null || tenantId == null) {
      throw Exception('Authentication required');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Tenant-ID': tenantId.trim(),
    };
  }

  // ==================== PRODUCTS ====================
  Future<List<dynamic>> fetchProducts() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/products'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/products'),
        headers: headers,
        body: json.encode(productData),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding product: $e");
      return false;
    }
  }

  // ==================== STOCK TRANSACTIONS (Audit Trail) ====================
  // 🆕 NEW: Fetches immutable history from /admin/tracker (StockTransaction)
  Future<List<dynamic>> fetchStockTransactions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/tracker'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both {result: [...]} wrapper and direct array responses
        if (data is List) return data;
        if (data is Map && data['result'] is List) return data['result'];
        return [];
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      rethrow;
    }
  }

  // ==================== SUPPLIERS ====================
  // 🆕 NEW: Fetch list of suppliers for dropdowns
  Future<List<dynamic>> fetchSuppliers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both {suppliers: [...]} wrapper and direct array
        if (data is List) return data;
        if (data is Map && data['suppliers'] is List) return data['suppliers'];
        return [];
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching suppliers: $e");
      return [];
    }
  }

  // 🆕 NEW: Create a new supplier
  Future<bool> addSupplier(Map<String, dynamic> supplierData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/suppliers'),
        headers: headers,
        body: json.encode(supplierData),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding supplier: $e");
      return false;
    }
  }

  // ==================== SUPPORTING DATA ====================
  Future<List<dynamic>> fetchWarehouses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/warehouses'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("Error fetching warehouses: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Connection error: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/categories'),
        headers: headers,
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }

  // ==================== DRAWS (Legacy/Specific Flow) ====================
  Future<List<dynamic>> fetchDraws() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/draws'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
