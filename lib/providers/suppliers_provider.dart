import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class SuppliersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async => ApiService.getSuppliers();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(ApiService.getSuppliers);
  }

  Future<void> create({
    required String name,
    String? contact,
    String? email,
    String? phone,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.createSupplier(
        name: name,
        contact: contact,
        email: email,
        phone: phone,
        address: address,
      );
      return ApiService.getSuppliers();
    });
  }

  // ✅ Nombre cambiado para evitar colisión con AsyncNotifier.update()
  Future<void> updateSupplier(
    String id, {
    String? name,
    String? contact,
    String? email,
    String? phone,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.updateSupplier(
        id,
        name: name,
        contact: contact,
        email: email,
        phone: phone,
        address: address,
      );
      return ApiService.getSuppliers();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiService.deleteSupplier(id);
      return ApiService.getSuppliers();
    });
  }
}

// ✅ CRÍTICO: AsyncNotifierProvider, NO FutureProvider
final suppliersProvider =
    AsyncNotifierProvider<SuppliersNotifier, List<Map<String, dynamic>>>(
      SuppliersNotifier.new,
    );
