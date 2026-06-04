import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class CategoriesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ApiService.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(ApiService.getCategories);
  }

  Future<void> create({required String name, String? description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.createCategory(name: name, description: description);
      return ApiService.getCategories();
    });
  }

  // ✅ Nombre cambiado para evitar colisión con AsyncNotifier.update()
  Future<void> updateCategory(
    String id, {
    String? name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.updateCategory(id, name: name, description: description);
      return ApiService.getCategories();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.deleteCategory(id);
      return ApiService.getCategories();
    });
  }
}

// ✅ CRÍTICO: AsyncNotifierProvider, NO FutureProvider
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Map<String, dynamic>>>(
      CategoriesNotifier.new,
    );
