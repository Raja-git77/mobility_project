class PaymentModel {
  final int id;
  final int bookingId;
  final double amount;
  final String status;
  final String method;
  final String? transactionId;
  final DateTime? paidAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionId,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingId: (json['booking_id'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      method: json['method']?.toString() ?? 'upi',
      transactionId: json['transaction_id']?.toString(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
    );
  }
}
