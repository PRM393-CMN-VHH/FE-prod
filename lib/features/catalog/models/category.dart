class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    final int catId = json['categoryId'] ?? json['id'] ?? 0;
    final String catName = json['categoryName'] ?? json['name'] ?? '';
    return Category(id: catId, name: catName);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
