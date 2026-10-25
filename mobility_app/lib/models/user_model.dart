class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String memberStatus;
  final String licenseStatus;
  final String identityStatus;
  final int totalTrips;
  final double walletBalance;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.memberStatus = 'Gold Verified Member',
    this.licenseStatus = 'Verified',
    this.identityStatus = 'Verified',
    this.totalTrips = 14,
    this.walletBalance = 450.0,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? memberStatus,
    String? licenseStatus,
    String? identityStatus,
    int? totalTrips,
    double? walletBalance,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      memberStatus: memberStatus ?? this.memberStatus,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      identityStatus: identityStatus ?? this.identityStatus,
      totalTrips: totalTrips ?? this.totalTrips,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      name: json['name']?.toString() ?? 'Rajavel Kumar',
      email: json['email']?.toString() ?? 'rajavel@mobilityapp.in',
      phone: json['phone']?.toString() ?? '+91 88078 61577',
      role: json['role']?.toString() ?? 'customer',
      memberStatus: json['member_status']?.toString() ?? 'Gold Verified Member',
      licenseStatus: json['license_status']?.toString() ?? 'Verified',
      identityStatus: json['identity_status']?.toString() ?? 'Verified',
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 14,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 450.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'member_status': memberStatus,
        'license_status': licenseStatus,
        'identity_status': identityStatus,
        'total_trips': totalTrips,
        'wallet_balance': walletBalance,
      };
}
