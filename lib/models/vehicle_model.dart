class VehicleModel {
  final int id;
  final String name;
  final String category;
  final int seats;
  final double pricePerKm;
  final double baseFare;
  final String fuelType;
  final double rating;
  final bool available;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.category,
    required this.seats,
    required this.pricePerKm,
    required this.baseFare,
    this.fuelType = 'Petrol',
    this.rating = 4.5,
    this.available = true,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 4,
      pricePerKm: (json['price_per_km'] as num?)?.toDouble() ?? 14.0,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 50.0,
      fuelType: json['fuel_type']?.toString() ?? 'Petrol',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      available: json['available'] as bool? ?? true,
    );
  }
}
