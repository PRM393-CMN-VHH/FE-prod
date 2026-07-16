import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/catalog/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPromo = product.promoPrice != null;
    final displayPrice = product.promoPrice ?? product.price;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                  if (isPromo)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: _PromotionBadge(),
                    ),
                  if (product.stock <= 0) const _OutOfStockOverlay(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleMedium?.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.flowerType,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          formatVnd(displayPrice),
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 15,
                            color: AppTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPromo) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formatVnd(product.price),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionBadge extends StatelessWidget {
  const _PromotionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'GIẢM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _OutOfStockOverlay extends StatelessWidget {
  const _OutOfStockOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.4),
      child: const Center(
        child: Text(
          'Hết hàng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
