import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class TransactionsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  int _page = 1;
  Map<String, dynamic> _pagination = {};
  bool get hasMore => _pagination['has_next'] == true;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _page = 1;
    final data = await ApiService.getTransactions(page: 1);
    _pagination = data['pagination'] ?? {};
    return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    _page++;
    final data = await ApiService.getTransactions(page: _page);
    final newTx = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    _pagination = data['pagination'] ?? {};
    state = AsyncData([...state.value ?? [], ...newTx]);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _page = 1;
    state = await AsyncValue.guard(() async {
      final data = await ApiService.getTransactions(page: 1);
      _pagination = data['pagination'] ?? {};
      return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    });
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Map<String, dynamic>>>(
      TransactionsNotifier.new,
    );
