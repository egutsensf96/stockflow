import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

final categoriesProvider = FutureProvider.autoDispose(
  (ref) => ApiService.getCategories(),
);
final suppliersProvider = FutureProvider.autoDispose(
  (ref) => ApiService.getSuppliers(),
);
final warehousesProvider = FutureProvider.autoDispose(
  (ref) => ApiService.getWarehouses(),
);
