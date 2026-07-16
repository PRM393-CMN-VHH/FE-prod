class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String address;
  final bool isActive;
  final String roleName;
  final int? roleId;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    this.isActive = true,
    this.roleName = 'user',
    this.roleId,
  });

  bool get isAdmin => roleName.toLowerCase() == 'admin' || roleId == 1;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final String parsedId = (json['userId'] ?? json['id'] ?? '').toString();
    final String parsedEmail = json['email'] as String? ?? '';
    final String parsedName = json['fullName'] ?? json['name'] ?? '';
    final String parsedPhone = json['phoneNumber'] ?? json['phone'] ?? '';
    final String parsedAddress = json['address'] as String? ?? '';
    final bool parsedStatus = json['status'] is bool
        ? json['status'] as bool
        : json['isActive'] is bool
        ? json['isActive'] as bool
        : true;

    String parsedRoleName =
        json['roleName'] ?? json['role']?.toString() ?? 'user';
    int? parsedRoleId;
    if (json['role'] is Map) {
      final role = json['role'] as Map<String, dynamic>;
      parsedRoleName = role['roleName'] ?? parsedRoleName;
      parsedRoleId = role['roleId'] is int
          ? role['roleId'] as int
          : int.tryParse(role['roleId']?.toString() ?? '');
    } else {
      parsedRoleId = json['roleId'] is int
          ? json['roleId'] as int
          : int.tryParse(json['roleId']?.toString() ?? '');
    }

    return UserModel(
      id: parsedId,
      email: parsedEmail,
      name: parsedName,
      phone: parsedPhone,
      address: parsedAddress,
      isActive: parsedStatus,
      roleName: parsedRoleName,
      roleId: parsedRoleId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'status': isActive,
      'roleName': roleName,
      'roleId': roleId,
    };
  }
}
