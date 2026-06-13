class StoreLocation {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String hours;
  final double latitude;
  final double longitude;

  StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    required this.latitude,
    required this.longitude,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      hours: json['hours'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'hours': hours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
