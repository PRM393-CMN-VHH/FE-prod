import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/cart/screens/checkout_screen.dart';
import 'package:prm393/features/cart/widgets/cart_item_card.dart';
import 'package:prm393/features/cart/widgets/cart_summary.dart';
import 'package:prm393/core/theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;
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
              AppMessage.cartEmptyTitle.text,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppMessage.cartEmptyHint.text,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
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
              return CartItemCard(
                item: item,
                onRemove: () => _removeItem(context, cartProvider, item.id),
                onDecrease: () => _updateQuantity(
                  context,
                  cartProvider,
                  item.id,
                  item.quantity - 1,
                ),
                onIncrease: () {
                  if (item.quantity >= product.stock) {
                    _showMessage(context, AppMessage.stockLimitReached.text);
                    return;
                  }
                  _updateQuantity(
                    context,
                    cartProvider,
                    item.id,
                    item.quantity + 1,
                  );
                },
              );
            },
          ),
        ),
        CartSummary(
          subtotal: cartProvider.subtotalAmount,
          shippingFee: cartProvider.shippingFee,
          total: cartProvider.totalAmount,
          onCheckout: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          ),
        ),
      ],
    );
  }

  Future<void> _removeItem(
    BuildContext context,
    CartProvider provider,
    int itemId,
  ) async {
    final success = await provider.removeFromCart(itemId);
    if (!success && context.mounted) {
      _showMessage(
        context,
        provider.errorMessage ?? AppMessage.removeFromCartFailed.text,
        isError: true,
      );
    }
  }

  Future<void> _updateQuantity(
    BuildContext context,
    CartProvider provider,
    int itemId,
    int quantity,
  ) async {
    final success = await provider.updateQuantity(itemId, quantity);
    if (!success && context.mounted) {
      _showMessage(
        context,
        provider.errorMessage ?? AppMessage.updateQuantityFailed.text,
        isError: true,
      );
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }
}
