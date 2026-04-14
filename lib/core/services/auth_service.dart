import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator, or your machine's local IP for physical devices
  final String baseUrl = "http://192.168.1.101:8080/auth";

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];

        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("Login Error: $e");
      }
      return false;
    }
  }

  // Helper to get token for other API calls
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}
