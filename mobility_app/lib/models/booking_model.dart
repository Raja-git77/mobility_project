class BookingModel {
  final int id;
  final String bookingRef;
  final String serviceType;
  final String pickupAddress;
  final String dropoffAddress;
  final double estimatedFare;
  final String status;
  final double? distanceKm;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.bookingRef,
    required this.serviceType,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
    required this.status,
    this.distanceKm,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingRef: json['booking_ref']?.toString() ??
          'BK-${DateTime.now().millisecondsSinceEpoch % 100000}',
      serviceType: json['service_type']?.toString() ?? 'on_demand',
      pickupAddress: json['pickup_address']?.toString() ?? '',
      dropoffAddress: json['dropoff_address']?.toString() ?? '',
      estimatedFare:
          (json['estimated_fare'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
