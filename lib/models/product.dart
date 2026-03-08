enum ProductCategory { classic, fruitTea, premium, addOns }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final ProductCategory category;
}