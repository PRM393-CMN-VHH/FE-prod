import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/catalog/models/review.dart';

// Star rating rendered from a double (supports halves via a simple round-to-nearest-star).
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final full = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < full ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        ),
      ),
    );
  }
}

// Below-the-description reviews block: average rating summary, "write a
// review" entry point (only shown when the backend says the viewer is
// eligible), and the list of existing reviews.
class ProductReviewsSection extends StatelessWidget {
  const ProductReviewsSection({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.errorMessage,
    required this.onWriteReview,
  });

  final ProductReviewsSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isLoading && summary == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (errorMessage != null && summary == null) {
      return Text(errorMessage!, style: const TextStyle(color: Colors.redAccent));
    }

    final data = summary;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Đánh giá sản phẩm", style: textTheme.titleMedium),
            const Spacer(),
            if (data.canReview)
              TextButton.icon(
                onPressed: onWriteReview,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text("Viết đánh giá"),
              )
            else if (data.alreadyReviewed)
              const Text(
                "Bạn đã đánh giá",
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (data.reviewCount > 0)
          Row(
            children: [
              StarRatingDisplay(rating: data.averageRating, size: 18),
              const SizedBox(width: 8),
              Text(
                "${data.averageRating.toStringAsFixed(1)}/5 (${data.reviewCount} đánh giá)",
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              "Chưa có đánh giá nào cho sản phẩm này.",
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        const SizedBox(height: 12),
        for (final review in data.reviews) ...[
          _ReviewTile(review: review),
          const Divider(height: 24),
        ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              review.userName.isEmpty ? "Khách hàng" : review.userName,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}",
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        StarRatingDisplay(rating: review.rating.toDouble()),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(review.comment, style: textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ],
    );
  }
}

// Star picker + comment field, shown as a modal bottom sheet from the product
// detail screen. Returns the submitted {rating, comment}, or null if cancelled.
Future<({int rating, String comment})?> showWriteReviewSheet(
  BuildContext context,
) {
  int rating = 5;
  final commentController = TextEditingController();

  return showModalBottomSheet<({int rating, String comment})>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Viết đánh giá",
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return IconButton(
                      onPressed: () =>
                          setSheetState(() => rating = starIndex),
                      icon: Icon(
                        starIndex <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Chia sẻ cảm nhận của bạn về sản phẩm...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, (
                    rating: rating,
                    comment: commentController.text.trim(),
                  )),
                  child: const Text("Gửi đánh giá"),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
