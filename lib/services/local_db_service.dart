import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'milko_tea.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            productId TEXT NOT NULL,
            productName TEXT NOT NULL,
            price REAL NOT NULL,
            size TEXT NOT NULL,
            sugarLevel TEXT NOT NULL,
            addOns TEXT NOT NULL,
            note TEXT,
            quantity INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveCart(String userId, List<CartItem> items) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cart_items', where: 'userId = ?', whereArgs: [userId]);

    for (final item in items) {
      batch.insert(
        'cart_items',
        CartItemLocal(item: item, userId: userId).toMap(),
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<CartItem>> loadCart(String userId) async {
    final db = await database;
    final rows = await db.query(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.map((row) => CartItemLocal.fromMap(row).toCartItem()).toList();
  }

  Future<void> clearCart(String userId) async {
    final db = await database;
    await db.delete('cart_items', where: 'userId = ?', whereArgs: [userId]);
  }
}

class CartItemLocal {
  CartItemLocal({required this.item, required this.userId});

  final CartItem item;
  final String userId;

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'productId': item.product.id,
      'productName': item.product.name,
      'price': item.product.price,
      'size': item.size.name,
      'sugarLevel': item.sugarLevel.name,
      'addOns': jsonEncode(item.addOns.map((e) => e.name).toList()),
      'note': item.note,
      'quantity': item.quantity,
    };
  }

  static CartItemLocal fromMap(Map<String, Object?> map) {
    final product = Product(
      id: map['productId'] as String,
      name: map['productName'] as String,
      description: '',
      price: (map['price'] as num).toDouble(),
      category: ProductCategory.classic,
      image: '',
    );

    final addOnsJson = map['addOns'] as String;
    final decodedAddOns = (jsonDecode(addOnsJson) as List<dynamic>)
        .map(
          (entry) => AddOn.values.firstWhere(
            (addOn) => addOn.name == entry as String,
            orElse: () => AddOn.pearls,
          ),
        )
        .toList();

    final size = DrinkSize.values.firstWhere(
      (e) => e.name == map['size'],
      orElse: () => DrinkSize.small,
    );

    final sugarLevel = SugarLevel.values.firstWhere(
      (e) => e.name == map['sugarLevel'],
      orElse: () => SugarLevel.fifty,
    );

    return CartItemLocal(
      item: CartItem(
        product: product,
        quantity: map['quantity'] as int,
        size: size,
        sugarLevel: sugarLevel,
        addOns: decodedAddOns,
        note: map['note'] as String?,
      ),
      userId: map['userId'] as String,
    );
  }

  CartItem toCartItem() => item;
}
