class Product {
  final int id;
  final String name;
  final int categoryId;
  final String imageUrl;
  final double price;
  final double? promoPrice;
  final String description;
  final String careInstructions;
  final int stock;
  final bool isAvailable;
  final String flowerType;
  final String color;
  final String size;
  final String freshness;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.imageUrl,
    required this.price,
    this.promoPrice,
    required this.description,
    required this.careInstructions,
    required this.stock,
    required this.isAvailable,
    required this.flowerType,
    required this.color,
    required this.size,
    required this.freshness,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] as String,
      categoryId: json['category_id'] is int ? json['category_id'] : int.parse(json['category_id'].toString()),
      imageUrl: json['image_url'] as String,
      price: (json['price'] as num).toDouble(),
      promoPrice: json['promo_price'] != null ? (json['promo_price'] as num).toDouble() : null,
      description: json['description'] as String,
      careInstructions: json['care_instructions'] as String,
      stock: json['stock'] is int ? json['stock'] : int.parse(json['stock'].toString()),
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      flowerType: json['flower_type'] as String? ?? 'Rose',
      color: json['color'] as String? ?? 'Red',
      size: json['size'] as String? ?? 'Medium',
      freshness: json['freshness'] as String? ?? 'Fresh',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'image_url': imageUrl,
      'price': price,
      'promo_price': promoPrice,
      'description': description,
      'care_instructions': careInstructions,
      'stock': stock,
      'is_available': isAvailable ? 1 : 0,
      'flower_type': flowerType,
      'color': color,
      'size': size,
      'freshness': freshness,
    };
  }
}
