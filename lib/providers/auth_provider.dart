import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.authenticated; // Start authenticated for demo or unauthenticated
  UserModel? _user = const UserModel(
    id: 1,
    name: 'Rajavel Kumar',
    email: 'rajavel@mobilityapp.in',
    phone: '+91 88078 61577',
    memberStatus: 'Gold Verified Member',
    licenseStatus: 'Verified',
    identityStatus: 'Verified',
    totalTrips: 14,
    walletBalance: 450.0,
  );
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    if (email.contains('@') && password.length >= 6) {
      final displayName = email.contains('rajavel')
          ? 'Rajavel Kumar'
          : email
              .split('@')
              .first
              .replaceAll('.', ' ')
              .split(' ')
              .map((w) =>
                  w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
              .join(' ');

      _user = UserModel(
        id: 1,
        name: displayName.isNotEmpty ? displayName : 'Rajavel Kumar',
        email: email,
        phone: '+91 88078 61577',
        memberStatus: 'Gold Verified Member',
        licenseStatus: 'Verified',
        identityStatus: 'Verified',
        totalTrips: 14,
        walletBalance: 450.0,
      );
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Please enter a valid email and password (min 6 characters).';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _user = UserModel(
      id: 1,
      name: name,
      email: email,
      phone: phone.isNotEmpty ? phone : '+91 88078 61577',
      memberStatus: 'Gold Verified Member',
      licenseStatus: 'Verified',
      identityStatus: 'Verified',
      totalTrips: 0,
      walletBalance: 250.0,
    );
    _status = AuthStatus.authenticated;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void updateProfile({String? name, String? phone, String? email}) {
    if (_user != null) {
      _user = _user!.copyWith(
        name: name,
        phone: phone,
        email: email,
      );
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
