import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

enum BookingFlowStep { selectVehicle, confirmTrip, payment, tracking }

class BookingProvider extends ChangeNotifier {
  BookingFlowStep _step = BookingFlowStep.selectVehicle;
  String _serviceType = 'self_drive';
  String _pickupAddress = '';
  String _dropoffAddress = '';
  double _distanceKm = 0.0;
  List<BookingModel> _myBookings = [];
  BookingModel? _activeBooking;
  bool _isLoading = false;
  String? _errorMessage;

  BookingFlowStep get step => _step;
  String get serviceType => _serviceType;
  String get pickupAddress => _pickupAddress;
  String get dropoffAddress => _dropoffAddress;
  double get distanceKm => _distanceKm;
  List<BookingModel> get myBookings => _myBookings;
  BookingModel? get activeBooking => _activeBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setServiceType(String type) {
    _serviceType = type;
    notifyListeners();
  }

  void setPickupLocation(String address, double lat, double lng) {
    _pickupAddress = address;
    notifyListeners();
  }

  void setDropoffLocation(String address, double lat, double lng) {
    _dropoffAddress = address;
    notifyListeners();
  }

  void setStep(BookingFlowStep step) {
    _step = step;
    notifyListeners();
  }

  Future<void> loadMyBookings() async {
    if (_myBookings.isNotEmpty) {
      // Keep existing added bookings, just refresh if needed
      return;
    }
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    _myBookings = [
      BookingModel(
        id: 1001,
        bookingRef: 'BK-78210',
        serviceType: 'Rental Service',
        pickupAddress: 'Chennai Central Railway Station',
        dropoffAddress: 'Tidel Park, OMR',
        estimatedFare: 680,
        status: 'completed',
        distanceKm: 14.8,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      BookingModel(
        id: 1002,
        bookingRef: 'BK-78294',
        serviceType: 'Self-Drive Rental',
        pickupAddress: 'Anna Nagar West',
        dropoffAddress: 'Chennai Airport T1',
        estimatedFare: 850,
        status: 'completed',
        distanceKm: 18.2,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    _isLoading = false;
    notifyListeners();
  }

  void addBooking({
    required String serviceType,
    required String vehicleOrDriver,
    required String pickup,
    required String dropoff,
    required double fare,
    required double distanceKm,
    required String txnId,
  }) {
    final newBooking = BookingModel(
      id: DateTime.now().millisecondsSinceEpoch,
      bookingRef: txnId.isNotEmpty ? txnId : 'BK-${DateTime.now().millisecondsSinceEpoch % 100000}',
      serviceType: serviceType,
      pickupAddress: pickup,
      dropoffAddress: dropoff,
      estimatedFare: fare,
      status: 'confirmed',
      distanceKm: distanceKm,
      createdAt: DateTime.now(),
    );

    _myBookings.insert(0, newBooking);
    _activeBooking = newBooking;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetBookingFlow() {
    _step = BookingFlowStep.selectVehicle;
    _serviceType = 'self_drive';
    _pickupAddress = '';
    _dropoffAddress = '';
    _distanceKm = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
