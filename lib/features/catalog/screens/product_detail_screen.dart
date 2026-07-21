import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/features/catalog/models/review.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/catalog/widgets/product_detail_widgets.dart';
import 'package:prm393/features/catalog/widgets/product_reviews_section.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/core/utils/error_translator.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  int _quantity = 1;
  late Product _product;
  List<Product> _relatedProducts = [];
  bool _isLoadingDetail = true;
  String? _detailError;
  ProductReviewsSummary? _reviewsSummary;
  bool _isLoadingReviews = true;
  String? _reviewsError;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadBackendDetail();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final summary = await _apiService.getProductReviews(widget.product.id);
      if (!mounted) return;
      setState(() {
        _reviewsSummary = summary;
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewsError = ErrorTranslator.userMessage(e);
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _writeReview() async {
    final result = await showWriteReviewSheet(context);
    if (result == null) return;
    try {
      await _apiService.submitProductReview(
        widget.product.id,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cảm ơn bạn đã đánh giá sản phẩm!"),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      await _loadReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorTranslator.userMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loadBackendDetail() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    try {
      final detail = await productProvider.loadProductDetail(widget.product.id);
      final related = await productProvider.loadRelatedProducts(
        widget.product.id,
      );
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

    final added = await cartProv.addToCart(_product, _quantity);
    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cartProv.errorMessage ?? AppMessage.addToCartFailed.text,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppMessage.addedToCart.format([_quantity, _product.name]),
          ),
          backgroundColor: AppTheme.primaryColor,
          action: SnackBarAction(
            label: "Xem giỏ",
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(
                context,
              ); // Go back to Home and switch to Cart tab manually (or just return)
            },
          ),
        ),
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
        bottom: _isLoadingDetail
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.primaryColor,
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductHeroImage(product: product),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_detailError != null) ...[
                    Text(
                      _detailError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Product Name
                  Text(
                    product.name,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price (Promo price and Original price side by side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatVnd(dispPrice),
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPromo) ...[
                        const SizedBox(width: 12),
                        Text(
                          formatVnd(product.price),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stock check
                  Text(
                    product.stock > 0
                        ? "Còn hàng"
                        : "Tạm hết hàng",
                    style: TextStyle(
                      color: product.stock > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text("Thông tin sản phẩm", style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ProductDescriptionView(description: product.description),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  ProductReviewsSection(
                    summary: _reviewsSummary,
                    isLoading: _isLoadingReviews,
                    errorMessage: _reviewsError,
                    onWriteReview: _writeReview,
                  ),

                  const SizedBox(height: 24),

                  if (_relatedProducts.isNotEmpty) const SizedBox(height: 24),
                  RelatedProductsSection(
                    products: _relatedProducts,
                    onProductTap: (related) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: related),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 100,
                  ), // Spacing for floating checkout buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: product.stock > 0
          ? ProductPurchaseBar(
              quantity: _quantity,
              onDecrease: _decreaseQty,
              onIncrease: _increaseQty,
              onAddToCart: _addToCart,
            )
          : null,
    );
  }
}
