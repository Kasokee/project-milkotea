import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../presenters/app_presenter.dart';
import '../widgets/price_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  static const route = '/details';
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  DrinkSize size = DrinkSize.small;
  SugarLevel sugar = SugarLevel.fifty;
  final Set<AddOn> addOns = {};
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  // 🔥 Dynamic price calculator based on selected size
  double _calculatedPrice() {
    double basePrice = widget.product.price;

    switch (size) {
      case DrinkSize.small:
        return basePrice;
      case DrinkSize.medium:
        return basePrice + 20;
      case DrinkSize.large:
        return basePrice + 35;
    }
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.read<AppPresenter>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.product.image,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        // 🔥 Dynamic price here
                        PriceText(
                          _calculatedPrice(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    _buildSectionTitle('Size'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: DrinkSize.values.map((e) {
                        final isSelected = size == e;
                        return ChoiceChip(
                          label: Text(
                            _sizeLabel(e),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => size = e),
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Sugar Level'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SugarLevel.values.map((e) {
                        final isSelected = sugar == e;
                        return ChoiceChip(
                          label: Text(
                            _sugarLabel(e),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => sugar = e),
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Add-ons (+₱20 each)'),
                    const SizedBox(height: 8),
                    ...AddOn.values.map((a) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: addOns.contains(a)
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: addOns.contains(a) ? 2 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: addOns.contains(a),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            title: Text(
                              a.name,
                              style: TextStyle(
                                fontWeight: addOns.contains(a) ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: const Text('+₱20'),
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (_) => setState(() {
                              addOns.contains(a) ? addOns.remove(a) : addOns.add(a);
                            }),
                          ),
                        )),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Note to Store'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. Less ice, no pearls',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                presenter.addToCart(
                  product: widget.product,
                  size: size,
                  sugarLevel: sugar,
                  addOns: addOns.toList(),
                  note: noteController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Added to cart'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text(
                'Add to Cart',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _sizeLabel(DrinkSize size) => switch (size) {
        DrinkSize.small => 'Small (16oz)',
        DrinkSize.medium => 'Medium (22oz)',
        DrinkSize.large => 'Large (32oz)',
      };

  String _sugarLabel(SugarLevel level) => switch (level) {
        SugarLevel.zero => '0%',
        SugarLevel.twentyFive => '25%',
        SugarLevel.fifty => '50%',
        SugarLevel.seventyFive => '75%',
        SugarLevel.full => '100%',
      };
}
