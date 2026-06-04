import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class WarehousesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ApiService.getWarehouses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(ApiService.getWarehouses);
  }

  Future<void> create({required String name, String? location}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.createWarehouse(name: name, location: location);
      return ApiService.getWarehouses();
    });
  }

  // ✅ Nombre cambiado para evitar colisión con AsyncNotifier.update()
  Future<void> updateWarehouse(
    String id, {
    String? name,
    String? location,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.updateWarehouse(id, name: name, location: location);
      return ApiService.getWarehouses();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.deleteWarehouse(id);
      return ApiService.getWarehouses();
    });
  }
}

// ✅ CRÍTICO: AsyncNotifierProvider, NO FutureProvider
final warehousesProvider =
    AsyncNotifierProvider<WarehousesNotifier, List<Map<String, dynamic>>>(
      WarehousesNotifier.new,
    );
