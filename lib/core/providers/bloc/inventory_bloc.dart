import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stockflow/core/services/api_services.dart';

// --- EVENTS ---
abstract class InventoryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchInventory extends InventoryEvent {}

// --- STATE ---
abstract class InventoryState extends Equatable {
  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}
class InventoryLoaded extends InventoryState {
  final List<dynamic> products;
  InventoryLoaded(this.products);
  @override
  List<Object> get props => [products];
}
class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
}

// --- BLOC ---
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiService apiService;

  InventoryBloc(this.apiService) : super(InventoryInitial()) {
    on<FetchInventory>((event, emit) async {
      emit(InventoryLoading());
      try {
        final data = await apiService.fetchProducts();
        emit(InventoryLoaded(data));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });
  }
}