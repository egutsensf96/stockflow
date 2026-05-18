import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class InventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() => ApiService.getInventory();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(ApiService.getInventory);
  }

  Future<void> addProduct({
    required String name,
    required String sku,
    required int quantity,
    required String categoryId,
    required String warehouseId,
    String? supplierId, // ✅ AÑADIDO
    String? imageBase64,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.addProduct(
        name: name,
        sku: sku,
        quantity: quantity,
        categoryId: categoryId,
        warehouseId: warehouseId,
        supplierId: supplierId,
        imageBase64: imageBase64,
      );
      return ApiService.getInventory();
    });
  }

  // ✅ ACTUALIZAR PRODUCTO
  Future<void> updateProduct({
    required String id,
    String? name,
    String? sku,
    int? quantity,
    String? categoryId,
    String? imageBase64,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.updateProduct(
        id: id,
        name: name,
        sku: sku,
        quantity: quantity,
        categoryId: categoryId,
        imageBase64: imageBase64,
      );
      return ApiService.getInventory(); // Refresca lista tras éxito
    });
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<Map<String, dynamic>>>(
      InventoryNotifier.new,
    );
