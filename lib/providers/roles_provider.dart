import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class RolesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() => ApiService.getRoles();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(ApiService.getRoles);
  }

  Future<void> createRole({required String name, String? description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.createRole(name: name, description: description);
      return ApiService.getRoles();
    });
  }

  Future<void> updateRole({
    required String id,
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.updateRole(id: id, name: name, description: description);
      return ApiService.getRoles();
    });
  }

  Future<void> deleteRole(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.deleteRole(id);
      return ApiService.getRoles();
    });
  }
}

final rolesProvider =
    AsyncNotifierProvider<RolesNotifier, List<Map<String, dynamic>>>(
      RolesNotifier.new,
    );
