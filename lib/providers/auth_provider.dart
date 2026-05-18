import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';

class AuthState {
  final String token, userId, tenantId, email, name;
  const AuthState({
    required this.token,
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.name,
  });
}

class AuthNotifier extends Notifier<AuthState?> {
  @override
  AuthState? build() => null; // Estado inicial: sin sesión

  // 🔄 Restaurar desde storage (llamado por SplashScreen)
  Future<void> initFromStorage() async {
    final userData = await SessionService.getSession();
    if (userData == null) return;

    // ✅ Extracción segura (evita el crash por 'Null is not a subtype of String')
    final token = userData['token'] as String?;
    final userId = userData['id'] as String?;
    final tenantId = userData['tenant_id'] as String?;
    final email = userData['email'] as String?;
    final name = userData['name'] as String? ?? email ?? 'Usuario';

    // 🔒 Si falta algún dato crítico, la sesión se considera inválida y se limpia
    if (token == null || userId == null || tenantId == null || email == null) {
      await SessionService.clearSession();
      return;
    }

    state = AuthState(
      token: token,
      userId: userId,
      tenantId: tenantId,
      email: email,
      name: name,
    );
  }

  // 🔑 Login
  Future<void> login({required String email, required String password}) async {
    final res = await ApiService.login(email: email, password: password);
    final user = res['user'] as Map<String, dynamic>;
    final token = res['token'] as String;

    state = AuthState(
      token: token,
      userId: user['id'],
      tenantId: user['tenant_id'],
      email: user['email'],
      name: user['name'],
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
