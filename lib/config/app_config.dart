import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  // 🔌 ENDPOINTS (Multi-tenant ready)
  static const String baseUrl = 'http://192.168.1.101:8080/api/v1';
  static String get endpointLogin => '$baseUrl/auth/login';
  static String get endpointInventory => '$baseUrl/inventory/products';
  static String get endpointCategories => '$baseUrl/inventory/categories';
  static String get endpointSuppliers => '$baseUrl/suppliers';
  static String get endpointWarehouses => '$baseUrl/admin/warehouses';
  static String get endpointTransactions => '$baseUrl/admin/tracker';

  // 🎨 TEMA NEO-BRUTALISTA / GLASS
  static const Color _bg = Color(0xFF0A0E17);
  static const Color _surface = Color(0xFF151B2B);
  static const Color _primary = Color(0xFF00F5D4); // Cian neón
  static const Color _secondary = Color(0xFF7B2CBF); // Violeta
  static const Color _text = Color(0xFFE2E8F0);
  static const Color _error = Color(0xFFFF4D4D);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
    primaryColor: _primary,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    colorScheme: ColorScheme.dark(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      onSurface: _text,
      onPrimary: _bg,
      error: _error,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
