import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/notification_provider.dart';
import 'package:prm393/theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _increaseQty() {
    if (_quantity < widget.product.stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decreaseQty() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() async {
    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);

    await cartProv.addToCart(widget.product, _quantity);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added $_quantity x ${widget.product.name} to cart!"),
          backgroundColor: AppTheme.primaryColor,
          action: SnackBarAction(
            label: "View Cart",
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context); // Go back to Home and switch to Cart tab manually (or just return)
            },
          ),
        ),
      );
      
      // Trigger a brief notification milestone
      await notifProv.triggerNotification(
        "Item added to Cart",
        "${widget.product.name} (Qty: $_quantity) was successfully added to your shopping cart."
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isPromo = product.promoPrice != null;
    final dispPrice = product.promoPrice ?? product.price;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image card
            Hero(
              tag: 'product_image_${product.id}',
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: product.stock <= 0
                      ? Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Text(
                              "Out of Stock",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                              product.flowerType,
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${dispPrice.toStringAsFixed(2)}",
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPromo) ...[
                            const SizedBox(height: 2),
                            Text(
                              "\$${product.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Product Specification Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _specCard("Color", product.color),
                      _specCard("Size", product.size),
                      _specCard("Freshness", product.freshness),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Stock check
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: product.stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.stock > 0 
                            ? "In Stock (${product.stock} items remaining)" 
                            : "Temporarily unavailable",
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Text("About this flower boutique", style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Care Instructions Card
                  Card(
                    color: Colors.grey.shade100,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.spa, color: AppTheme.primaryColor, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Care Instructions",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.careInstructions,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.5,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Spacing for floating checkout buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: product.stock > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity adjust widget
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _decreaseQty,
                        ),
                        Text(
                          _quantity.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: _increaseQty,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      child: const Text("Add to Cart"),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _specCard(String label, String value) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
