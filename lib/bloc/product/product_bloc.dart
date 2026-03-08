import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import '../../services/mock_data_service.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final FirestoreService _firestoreService;
  final MockDataService _mockDataService;

  ProductBloc({
    FirestoreService? firestoreService,
    MockDataService? mockDataService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _mockDataService = mockDataService ?? const MockDataService(),
        super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchProducts>(_onSearchProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final firestoreProducts = await _firestoreService.getProducts();
      final products = firestoreProducts.isNotEmpty
          ? firestoreProducts
          : _mockDataService.products();
      emit(ProductLoaded(products: products));
    } catch (e) {
      final products = _mockDataService.products();
      emit(ProductLoaded(products: products));
    }
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<ProductState> emit,
  ) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(ProductLoaded(
        products: currentState.products,
        selectedCategory: event.category,
      ));
    }
  }

  void _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      // Implement search logic here if needed
      emit(currentState);
    }
  }
}