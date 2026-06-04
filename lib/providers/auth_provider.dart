import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';

class AuthState {
  final String token, userId, tenantId, email, name, role;
  final String? warehouseId;

  bool get isAdmin => role.toLowerCase().contains('admin');

  const AuthState({
    required this.token,
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.name,
    this.role = 'user',
    this.warehouseId,
  });
}

class AuthNotifier extends Notifier<AuthState?> {
  @override
  AuthState? build() => null; // Estado inicial: sin sesión

  // 🔄 Restaurar desde storage (llamado por SplashScreen)
  Future<void> initFromStorage() async {
    final userData = await SessionService.getSession();

    // Si no hay datos, no hacemos nada (estado permanece null)
    if (userData == null) return;

    // ✅ Extracción SEGURA con casts opcionales (as String?)
    final token = userData['token'] as String?;
    final userId = userData['id'] as String?;
    final tenantId = userData['tenant_id'] as String?;
    final email = userData['email'] as String?;
    final name = userData['name'] as String? ?? email ?? 'Usuario';
    final role = userData['role'] as String? ?? 'user';

    // 🔒 Si falta algún dato CRÍTICO, la sesión se considera inválida y se limpia
    if (token == null || userId == null || tenantId == null || email == null) {
      await SessionService.clearSession();
      return;
    }

    // ✅ Solo asignamos estado si todos los datos son válidos
    state = AuthState(
      token: token,
      userId: userId,
      tenantId: tenantId,
      email: email,
      name: name,
      role: role,
    );
  }

  // 🔑 Login
  Future<void> login({required String email, required String password}) async {
    final res = await ApiService.login(email: email, password: password);
    final user = res['user'] as Map<String, dynamic>;
    final token = res['token'] as String;

    state = AuthState(
      token: token,
      userId: user['id'] as String,
      tenantId: user['tenant_id'] as String,
      email: user['email'] as String,
      name: user['name'] as String? ?? user['email'] as String,
      role: user['role'] as String? ?? 'user',
    );
    await SessionService.saveSession(token: token, user: user);
  }

  // 🚪 Logout
  Future<void> logout() async {
    state = null;
    await SessionService.clearSession();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState?>(
  AuthNotifier.new,
);
