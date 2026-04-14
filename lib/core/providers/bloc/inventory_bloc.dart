// lib/core/providers/bloc/inventory_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/services/api_services.dart';

// ==================== EVENTS ====================
abstract class InventoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchInventory extends InventoryEvent {}

class AddProduct extends InventoryEvent {
  final Map<String, dynamic> productData;
  AddProduct(this.productData);
  @override
  List<Object?> get props => [productData];
}

class RefreshAfterMutation extends InventoryEvent {} // Generic refresh trigger

// ==================== STATES ====================
abstract class InventoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<dynamic> products;
  InventoryLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);

  @override
  List<Object?> get props => [message]; // ✅ FIXED: Was missing!
}

// ==================== BLOC ====================
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiService apiService;

  InventoryBloc(this.apiService) : super(InventoryInitial()) {
    // 📦 Fetch products
    on<FetchInventory>((event, emit) async {
      emit(InventoryLoading());
      try {
        final data = await apiService.fetchProducts();
        emit(InventoryLoaded(data));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });

    // ➕ Add product + auto-refresh
    on<AddProduct>((event, emit) async {
      // Optional: emit a temporary "optimistic" state here if you want instant UI feedback
      try {
        final success = await apiService.addProduct(event.productData);
        if (success) {
          // ✅ Auto-refresh the list after successful add
          add(FetchInventory());
        } else {
          emit(InventoryError('Failed to add product'));
        }
      } catch (e) {
        emit(InventoryError('Error: $e'));
      }
    });

    // 🔄 Generic refresh trigger (useful after update/delete)
    on<RefreshAfterMutation>((event, emit) async {
      add(FetchInventory());
    });
  }

  // Helper method for external calls (e.g., from AddItemPage)
  Future<bool> addProductAndRefresh(Map<String, dynamic> productData) async {
    add(AddProduct(productData));
    return true; // The actual success/failure is handled internally via state emission
  }
}
