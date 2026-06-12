import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/notification_provider.dart';
import 'package:prm393/providers/product_provider.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/currency_formatter.dart';
import 'package:prm393/utils/error_translator.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late Product _product;
  List<Product> _relatedProducts = [];
  bool _isLoadingDetail = true;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadBackendDetail();
  }

  Future<void> _loadBackendDetail() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    try {
      final detail = await productProvider.loadProductDetail(widget.product.id);
      final related = await productProvider.loadRelatedProducts(widget.product.id);
      if (!mounted) return;
      setState(() {
        _product = detail;
        _relatedProducts = related;
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = ErrorTranslator.userMessage(e);
        _isLoadingDetail = false;
      });
    }
  }

  void _increaseQty() {
    if (_quantity < _product.stock) {
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

    final added = await cartProv.addToCart(_product, _quantity);
    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProv.errorMessage ?? "Không thể thêm sản phẩm vào giỏ. Vui lòng thử lại."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã thêm $_quantity x ${_product.name} vào giỏ hàng"),
          backgroundColor: AppTheme.primaryColor,
          action: SnackBarAction(
            label: "Xem giỏ",
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context); // Go back to Home and switch to Cart tab manually (or just return)
            },
          ),
        ),
      );
      
      // Trigger a brief notification milestone
      await notifProv.triggerNotification(
        "Đã thêm vào giỏ",
        "${_product.name} (SL: $_quantity) đã được thêm vào giỏ hàng."
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
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
                              "Hết hàng",
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
                  if (_isLoadingDetail)
                    const LinearProgressIndicator(color: AppTheme.primaryColor),
                  if (_detailError != null) ...[
                    Text(
                      _detailError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                            formatVnd(dispPrice),
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPromo) ...[
                            const SizedBox(height: 2),
                            Text(
                              formatVnd(product.price),
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
                      _specCard("Màu sắc", product.color),
                      _specCard("Kích thước", product.size),
                      _specCard("Độ tươi", product.freshness),
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
                            ? "Còn hàng (${product.stock} sản phẩm)" 
                            : "Tạm hết hàng",
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
                  
                  Text("Thông tin sản phẩm", style: textTheme.titleMedium),
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
                                "Hướng dẫn chăm sóc",
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

                  if (_relatedProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text("Sản phẩm liên quan", style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _relatedProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final related = _relatedProducts[index];
                          return SizedBox(
                            width: 130,
                            child: InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: related),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        related.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    related.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    formatVnd(related.price),
                                    style: const TextStyle(color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

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
                      child: const Text("Thêm vào giỏ"),
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
