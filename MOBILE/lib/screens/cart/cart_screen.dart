import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/screens/cart/checkout_screen.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/currency_formatter.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;
    final textTheme = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Giỏ hàng đang trống",
              style: textTheme.headlineSmall?.copyWith(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 8),
            const Text(
              "Hãy chọn hoa bạn thích để thêm vào giỏ",
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final product = item.product;
              final itemPrice = product.promoPrice ?? product.price;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${formatVnd(itemPrice)} / sản phẩm",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatVnd(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Controls
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final ok = await cartProvider.removeFromCart(item.id);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(cartProvider.errorMessage ?? "Không thể xóa sản phẩm. Vui lòng thử lại."),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove, size: 14),
                                  onPressed: () async {
                                    final ok = await cartProvider.updateQuantity(item.id, item.quantity - 1);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(cartProvider.errorMessage ?? "Không thể cập nhật số lượng. Vui lòng thử lại."),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add, size: 14),
                                  onPressed: () async {
                                    if (item.quantity < product.stock) {
                                      final ok = await cartProvider.updateQuantity(item.id, item.quantity + 1);
                                      if (!ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(cartProvider.errorMessage ?? "Không thể cập nhật số lượng. Vui lòng thử lại."),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Không thể vượt quá số lượng tồn kho"),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Summary checkout panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              )
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tạm tính", style: TextStyle(color: AppTheme.textSecondaryColor)),
                    Text(formatVnd(cartProvider.subtotalAmount), style: textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Phí giao hàng", style: TextStyle(color: AppTheme.textSecondaryColor)),
                    Text(
                      cartProvider.shippingFee == 0.0 ? "Miễn phí" : formatVnd(cartProvider.shippingFee),
                      style: TextStyle(
                        color: cartProvider.shippingFee == 0.0 ? Colors.green : AppTheme.textPrimaryColor,
                        fontWeight: cartProvider.shippingFee == 0.0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      formatVnd(cartProvider.totalAmount),
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutScreen(),
                      ),
                    );
                  },
                  child: const Text("Tiến hành thanh toán"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
