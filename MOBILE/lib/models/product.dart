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
    final int prodId = json['productId'] ?? json['id'] ?? 0;
    
    int catId = 0;
    if (json['category'] != null && json['category'] is Map) {
      catId = json['category']['categoryId'] ?? 0;
    } else if (json['category_id'] != null) {
      catId = json['category_id'] is int 
          ? json['category_id'] 
          : int.parse(json['category_id'].toString());
    } else if (json['categoryId'] != null) {
      catId = json['categoryId'] is int 
          ? json['categoryId'] 
          : int.parse(json['categoryId'].toString());
    }

    final String prodName = json['productName'] ?? json['name'] ?? '';
    final String prodImgUrl = json['imageUrl'] ?? json['image_url'] ?? '';
    final double prodPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    final double? prodPromoPrice = json['promo_price'] != null 
        ? (json['promo_price'] as num).toDouble() 
        : (json['promoPrice'] != null ? (json['promoPrice'] as num).toDouble() : null);

    return Product(
      id: prodId,
      name: prodName,
      categoryId: catId,
      imageUrl: prodImgUrl,
      price: prodPrice,
      promoPrice: prodPromoPrice,
      description: json['description'] as String? ?? '',
      careInstructions: json['care_instructions'] ?? json['careInstructions'] ?? '',
      stock: json['stock'] is int ? json['stock'] : int.parse((json['stock'] ?? 0).toString()),
      isAvailable: json['is_available'] == true || json['is_available'] == 1 || (json['stock'] != null && (json['stock'] as num) > 0),
      flowerType: json['flower_type'] ?? json['flowerType'] ?? 'Rose',
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

  Map<String, dynamic> toBackendJson() {
    return {
      'productId': id,
      'productName': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'category': {'categoryId': categoryId},
    };
  }
}
