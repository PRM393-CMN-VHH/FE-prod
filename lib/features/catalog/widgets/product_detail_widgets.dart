import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/catalog/models/product.dart';

class ProductHeroImage extends StatelessWidget {
  const ProductHeroImage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'product_image_${product.id}',
      child: AspectRatio(
        aspectRatio: 1.1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(product.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: product.stock <= 0
              ? ColoredBox(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Text(
                      'Hết hàng',
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
    );
  }
}

// Product descriptions follow a consistent admin-authored convention:
// "**Section title**" on its own line, followed by either a paragraph or a
// "- item" bullet list, with blank lines separating sections. This renders
// that structure with real visual hierarchy instead of showing raw "**".
class ProductDescriptionView extends StatelessWidget {
  const ProductDescriptionView({super.key, required this.description});

  final String description;

  static final RegExp _headingPattern = RegExp(r'^\*\*(.+)\*\*$');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lines = description.split('\n');

    final blocks = <Widget>[];
    List<String>? bulletBuffer;

    void flushBullets() {
      if (bulletBuffer == null) return;
      for (final item in bulletBuffer!) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      bulletBuffer = null;
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushBullets();
        continue;
      }

      final headingMatch = _headingPattern.firstMatch(line);
      if (headingMatch != null) {
        flushBullets();
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: blocks.isEmpty ? 0 : 16, bottom: 6),
            child: Text(
              headingMatch.group(1)!,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('- ')) {
        (bulletBuffer ??= []).add(line.substring(2).trim());
        continue;
      }

      flushBullets();
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      );
    }
    flushBullets();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }
}

class ProductSpecifications extends StatelessWidget {
  const ProductSpecifications({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SpecificationCard(label: 'Màu sắc', value: product.color),
        _SpecificationCard(label: 'Kích thước', value: product.size),
        _SpecificationCard(label: 'Độ tươi', value: product.freshness),
      ],
    );
  }
}

class RelatedProductsSection extends StatelessWidget {
  const RelatedProductsSection({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sản phẩm liên quan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 130,
                child: InkWell(
                  onTap: () => onProductTap(product),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.imageUrl,
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
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatVnd(product.promoPrice ?? product.price),
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
    );
  }
}

class ProductPurchaseBar extends StatelessWidget {
  const ProductPurchaseBar({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: onDecrease,
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: onIncrease,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: onAddToCart,
                child: const Text('Thêm vào giỏ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecificationCard extends StatelessWidget {
  const _SpecificationCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
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
