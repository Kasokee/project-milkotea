import '../models/product.dart';


class MockDataService {
  const MockDataService();

  List<Product> products() => const [
    // CLASSIC TEA
        Product(
          id: 'c1',
          name: 'Wintermelon Classic',
          description: 'Creamy wintermelon milk tea with a mellow finish.',
          price: 85,
          image: 'https://images.unsplash.com/photo-1577805947697-89e18249d767',
          category: ProductCategory.classic,
        ),
        Product(
          id: 'c2',
          name: 'Okinawa Brown Sugar',
          description: 'Signature Okinawa with rich caramel notes.',
          price: 95,
          image: 'https://images.unsplash.com/photo-1558857563-b371033873b8',
          category: ProductCategory.classic,
        ),
        Product(
          id: 'c3',
          name: 'Chocolate w/ Oreo',
          description: 'Sweet Chocolate with oreo at the top.',
          price: 95,
          image: '',
          category: ProductCategory.classic,
        ),
    
    // FRUIT TEA
        Product(
          id: 'f1',
          name: 'Lychee Fruit Tea',
          description: 'Refreshing tea infused with lychee sweetness.',
          price: 90,
          image: 'https://images.unsplash.com/photo-1497534446932-c925b458314e',
          category: ProductCategory.fruitTea,
        ),

    // PREMIUM TEA
        Product(
          id: 'p1',
          name: 'Cheesecake Supreme',
          description: 'Premium creamy milk tea topped with cheesecake foam.',
          price: 130,
          image: 'https://images.unsplash.com/photo-1464306076886-da185f6a9d05',
          category: ProductCategory.premium,
        ),
        
      ];
}
