import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final ProductCategory? selectedCategory;

  ProductLoaded({
    required this.products,
    this.selectedCategory,
  });

  List<Product> get filteredProducts {
    if (selectedCategory == null) return products;
    return products.where((p) => p.category == selectedCategory).toList();
  }

  @override
  List<Object?> get props => [products, selectedCategory];
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);

  @override
  List<Object?> get props => [message];
}