class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String address;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
