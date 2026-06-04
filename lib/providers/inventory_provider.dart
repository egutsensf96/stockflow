import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class InventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  String? _activeWarehouseId;

  // ✅ AGREGAR ESTO: Permite leer el filtro actual desde la UI
  String? get activeWarehouseId => _activeWarehouseId;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ApiService.getInventory(warehouseId: _activeWarehouseId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    // ✅ Recarga respetando el filtro activo
    state = await AsyncValue.guard(
      () => ApiService.getInventory(warehouseId: _activeWarehouseId),
    );
  }

  // ✅ NUEVO: Método para filtrar por almacén
  Future<void> filterByWarehouse(String? warehouseId) async {
    _activeWarehouseId = warehouseId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ApiService.getInventory(warehouseId: _activeWarehouseId),
    );
  }

  Future<void> addProduct({
    required String name,
    required String sku,
    required int quantity,
    required String categoryId,
    required String warehouseId,
    String? supplierId,
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
      // ✅ Refresca respetando el filtro activo
      return ApiService.getInventory(warehouseId: _activeWarehouseId);
    });
  }

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
      // ✅ Refresca respetando el filtro activo
      return ApiService.getInventory(warehouseId: _activeWarehouseId);
    });
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<Map<String, dynamic>>>(
      InventoryNotifier.new,
    );
