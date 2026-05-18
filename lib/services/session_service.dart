import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class SessionService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user_data';

  // ✅ Guarda sesión localmente + sincroniza header API
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, jsonEncode(user));
      ApiService.setToken(token);
    } catch (_) {
      // Fallback seguro: si falla el storage, al menos sincroniza el token en memoria
      ApiService.setToken(token);
    }
  }

  // ✅ Carga sesión. Retorna null si no existe o está corrupta
  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userStr = prefs.getString(_keyUser);

      if (token == null || userStr == null) return null;

      final user = jsonDecode(userStr) as Map<String, dynamic>;
      ApiService.setToken(token);
      return user;
    } catch (_) {
      return null; // Datos corruptos → forzar login limpio
    }
  }

  // ✅ Limpia todo
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } finally {
      ApiService.clearToken();
    }
  }
}
