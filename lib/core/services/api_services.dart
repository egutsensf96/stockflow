import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.101:8080/api/v1";
  final AuthService _authService = AuthService();

  // Method to get the Tenant ID from the stored token
  Future<String?> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // This matches the key you set in your Go backend JWT claims
      return decodedToken['tenant_id'];
    }
    return null;
  }

  Future<List<dynamic>> fetchProducts() async {
    try {
      final String? token = await _authService.getToken();
      final String? tenantId = await getTenantId();

      if (token == null || tenantId == null) {
        throw Exception('Auth or Tenant data missing');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/inventory/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId.trim(), // Ensure no whitespace
        },
      );


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }
  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      final String? token = await _authService.getToken();
      final String? tenantId = await getTenantId();

      final response = await http.post(
        Uri.parse('$baseUrl/inventory/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId!,
        },
        body: json.encode(productData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Error adding product: $e");
      return false;
    }
  }
  Future<List<dynamic>> fetchWarehouses() async {
    try {
      final String? token = await _authService.getToken();
      final String? tenantId = await getTenantId();

      // Pointing to your specific admin endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/admin/warehouses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId!,
        },
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

  // You'll also need this to populate the dropdown
    Future<List<dynamic>> fetchCategories() async {
      final String? token = await _authService.getToken();
      final String? tenantId = await getTenantId();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId!,
        },
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    }

  Future<List<dynamic>> fetchDraws() async {
    try {
      final String? token = await _authService.getToken();
      final String? tenantId = await getTenantId();

      final response = await http.get(
        Uri.parse('$baseUrl/inventory/draws'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId!,
        },
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

