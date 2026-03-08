import '../../models/product.dart';

abstract class ProductEvent {}

class LoadProducts extends ProductEvent {}

class FilterByCategory extends ProductEvent {
  final ProductCategory? category;
  FilterByCategory(this.category);
}

class SearchProducts extends ProductEvent {
  final String query;
  SearchProducts(this.query);
}