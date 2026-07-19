class ReviewModel {
  final int id;
  final int userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime created = DateTime.now();
    try {
      if (json['createdAt'] != null) {
        created = DateTime.parse(json['createdAt'] as String);
      }
    } catch (_) {}

    return ReviewModel(
      id: json['reviewId'] ?? json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      rating: json['rating'] is int
          ? json['rating'] as int
          : int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment'] ?? '',
      createdAt: created,
    );
  }
}

// Summary of a product's reviews plus whether the current viewer may write one.
class ProductReviewsSummary {
  final List<ReviewModel> reviews;
  final double averageRating;
  final int reviewCount;
  final bool canReview;
  final bool alreadyReviewed;

  ProductReviewsSummary({
    required this.reviews,
    required this.averageRating,
    required this.reviewCount,
    required this.canReview,
    required this.alreadyReviewed,
  });

  factory ProductReviewsSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['reviews'] as List<dynamic>? ?? [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProductReviewsSummary(
      reviews: list,
      averageRating: (json['averageRating'] as num? ?? 0).toDouble(),
      reviewCount: json['reviewCount'] is int
          ? json['reviewCount'] as int
          : int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      canReview: json['canReview'] as bool? ?? false,
      alreadyReviewed: json['alreadyReviewed'] as bool? ?? false,
    );
  }
}
