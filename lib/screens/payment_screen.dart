import 'dart:math';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import 'dashboard_screen.dart';

@JS('redirectToWhatsApp')
external void _jsRedirect(String url);

@JS('openWhatsAppUrl')
external void _jsOpen(String url);

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentArgs;
  const PaymentScreen({super.key, required this.paymentArgs});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PayState { form, processing, success }

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  _PayState _state = _PayState.form;
  String _payMethod = 'upi';
  String _upiApp = 'gpay';
  final _upiIdCtrl = TextEditingController(text: 'rajavel@okhdfcbank');
  final _cardNameCtrl = TextEditingController(text: 'Rajavel Kumar');
  final _cardNumCtrl = TextEditingController(text: '4532 8921 7654 3210');
  final _cardExpCtrl = TextEditingController(text: '08/28');
  final _cardCvvCtrl = TextEditingController(text: '789');

  late AnimationController _tickCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  String? _txnId;

  Map<String, dynamic> get _a => widget.paymentArgs;
  double get _fare => (_a['totalFare'] as num?)?.toDouble() ?? 750.0;
  String get _pickup => _a['pickupAddress']?.toString() ?? 'Anna Nagar, Chennai';
  String get _drop => _a['dropoffAddress']?.toString() ?? 'Chennai Airport T1';
  double get _distKm => (_a['distanceKm'] as num?)?.toDouble() ?? 15.0;
  String get _vehicle => _a['vehicleName']?.toString() ?? 'Honda City (Executive Sedan)';
  String get _svcType => _a['serviceType']?.toString() ?? 'Rental Service';
  String get _custName => _a['customerName']?.toString() ?? 'Rajavel Kumar';

  String get _payLabel {
    if (_payMethod == 'card') return 'Credit / Debit Card';
    switch (_upiApp) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      case 'bhim':
        return 'BHIM UPI';
      default:
        return 'UPI Payment';
    }
  }

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _scaleCtrl.dispose();
    _upiIdCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardNumCtrl.dispose();
    _cardExpCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  String _genTxnId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return 'TXN' +
        List.generate(9, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _pay() async {
    setState(() => _state = _PayState.processing);
    await Future.delayed(const Duration(milliseconds: 1300));

    _txnId = _genTxnId();

    // Save booking to state / history
    if (mounted) {
      context.read<BookingProvider>().addBooking(
            serviceType: _svcType,
            vehicleOrDriver: _vehicle,
            pickup: _pickup,
            dropoff: _drop,
            fare: _fare,
            distanceKm: _distKm,
            txnId: _txnId!,
          );
    }

    setState(() => _state = _PayState.success);
    _scaleCtrl.forward();
    _tickCtrl.forward();

    // Automatically redirect to WhatsApp after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), _triggerWhatsApp);
  }

  String _buildMsg() => Uri.encodeComponent(
        'Mobility App — Booking Confirmed ✅\n\n'
        'Customer: $_custName\n'
        'Service: $_svcType\n'
        'Vehicle / Driver: $_vehicle\n\n'
        '📍 Pickup: $_pickup\n'
        '🏁 Drop-off: $_drop\n'
        '📏 Exact Distance: ${_distKm > 0 ? '${_distKm.toStringAsFixed(1)} KM' : 'Direct Booking'}\n\n'
        '💳 Payment Method: $_payLabel\n'
        '💰 Amount Paid: ₹${_fare.toStringAsFixed(0)}\n'
        '🔖 Transaction ID: $_txnId\n'
        '✅ Status: CONFIRMED & PAID\n\n'
        'Powered by Mobility App 🚗',
      );

  void _triggerWhatsApp() {
    final url = 'https://wa.me/918807861577?text=${_buildMsg()}';
    try {
      _jsRedirect(url);
    } catch (_) {
      try {
        _jsOpen(url);
      } catch (_) {}
    }
  }

  // Post-payment navigation: Resets booking flow and returns smoothly to Dashboard
  void _backToServices() {
    context.read<BookingProvider>().resetBookingFlow();
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_state == _PayState.success) {
              _backToServices();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _state == _PayState.success
                  ? 'Payment Receipt'
                  : 'Pay ₹${_fare.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              _state == _PayState.success
                  ? 'Booking Confirmed • WhatsApp Receipt'
                  : 'Step 3 of 3 — 100% Secure Checkout',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: _state == _PayState.form
          ? _buildForm()
          : _state == _PayState.processing
              ? _buildProcessing()
              : _buildSuccess(),
    );
  }

  // ── 1. PAYMENT CHECKOUT FORM ──
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER SUMMARY',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                _summaryRow('Service Mode', _svcType),
                _summaryRow('Vehicle / Driver', _vehicle),
                _summaryRow('Pickup Location', _pickup),
                _summaryRow('Drop Location', _drop),
                if (_distKm > 0)
                  _summaryRow(
                      'Road Distance', '${_distKm.toStringAsFixed(1)} KM'),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYABLE',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '₹${_fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payment Method Selector
          const Text(
            'SELECT PAYMENT METHOD',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _methodTab(
                  id: 'upi',
                  label: 'UPI Apps / QR',
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _methodTab(
                  id: 'card',
                  label: 'Debit / Credit Card',
                  icon: Icons.credit_card_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_payMethod == 'upi') _buildUpiSection(),
          if (_payMethod == 'card') _buildCardSection(),

          const SizedBox(height: 24),

          // PAY NOW BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${_fare.toStringAsFixed(0)} Now',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 5),
                Text(
                  '256-bit SSL Encrypted • RBI & NPCI Compliant',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _methodTab({required String id, required String label, required IconData icon}) {
    final sel = _payMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _payMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: sel ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: sel ? const Color(0x1810B981) : const Color(0x060F172A),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: sel ? const Color(0xFF10B981) : const Color(0xFF64748B),
                size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: sel ? const Color(0xFF065F46) : const Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPI APPS SELECTION (NO HEART SYMBOLS) ──
  Widget _buildUpiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Instant UPI App',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _upiTile('gpay', _GPayBadge())),
                  const SizedBox(width: 8),
                  Expanded(child: _upiTile('phonepe', _PhonePeBadge())),
                  const SizedBox(width: 8),
                  Expanded(child: _upiTile('paytm', _PaytmBadge())),
                  const SizedBox(width: 8),
                  Expanded(child: _upiTile('bhim', _BhimBadge())),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Or Pay using VPA / UPI ID',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _upiIdCtrl,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: 'yourname@upi',
                  prefixIcon: Icon(Icons.alternate_email_rounded,
                      color: Color(0xFF10B981), size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _upiTile(String id, Widget badge) {
    final sel = _upiApp == id;
    return GestureDetector(
      onTap: () => setState(() => _upiApp = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            badge,
            const SizedBox(height: 6),
            Text(
              id.toUpperCase(),
              style: TextStyle(
                color: sel ? const Color(0xFF065F46) : const Color(0xFF64748B),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CARD PAYMENT SECTION ──
  Widget _buildCardSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card preview badge strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _CardChipBadge(),
                const SizedBox(width: 10),
                const Text(
                  'Debit / Credit Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _VisaBadge(),
                const SizedBox(width: 8),
                _MastercardBadge(),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _cardNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardNumCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              prefixIcon: Icon(Icons.credit_card_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardExpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'MM / YY',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cardCvvCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. PROCESSING SPINNER ──
  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              color: Color(0xFF10B981),
              strokeWidth: 3.5,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Confirming Payment...',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Please do not close or refresh this screen',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── 3. SUCCESS RECEIPT VIEW (ANIMATED GREEN TICK + WHATSAPP REDIRECT) ──
  Widget _buildSuccess() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Animated Green Tick Checkmark
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _tickCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _CheckPainter(_tickCtrl.value),
                    child: const SizedBox(width: 110, height: 110),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transaction ID: $_txnId',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),

            // Receipt Breakdown Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BOOKING RECEIPT DETAILS',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CONFIRMED & PAID ✅',
                          style: TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailRow(Icons.apps_rounded, 'Service Mode', _svcType),
                  _detailRow(Icons.directions_car_rounded, 'Vehicle / Driver',
                      _vehicle),
                  _detailRow(Icons.trip_origin_rounded, 'Pickup Location',
                      _pickup,
                      color: const Color(0xFF10B981)),
                  _detailRow(
                      Icons.location_on_rounded, 'Drop-off Location', _drop,
                      color: const Color(0xFFEF4444)),
                  if (_distKm > 0)
                    _detailRow(Icons.alt_route_rounded, 'Exact Road KM',
                        '${_distKm.toStringAsFixed(1)} KM',
                        color: const Color(0xFF2563EB)),
                  _detailRow(Icons.payment_rounded, 'Payment Method', _payLabel),
                  const Divider(height: 22, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AMOUNT PAID',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_fare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // WhatsApp Direct Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _triggerWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📱', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'Send Receipt to WhatsApp (8807861577)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // BACK TO SERVICES BUTTON (Requirement 10)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.home_rounded, color: Color(0xFF0F172A)),
                label: const Text(
                  'Back to Services / Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _backToServices,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color color = const Color(0xFF64748B)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ORIGINAL PAYMENT BRAND LOGOS (NO HEART ICONS) ──
class _GPayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            'Pay',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonePeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF5F259F),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Text(
        'पे PhonePe',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 8,
        ),
      ),
    );
  }
}

class _PaytmBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF002E6E),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Text(
        'paytm',
        style: TextStyle(
          color: Color(0xFF00BAF2),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BhimBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 26,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF138808), Color(0xFFFF9933)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Text(
        'BHIM',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CardChipBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
              height: 1,
              color: Colors.brown.withOpacity(0.5),
              margin: const EdgeInsets.symmetric(horizontal: 2)),
          Container(
              height: 1,
              color: Colors.brown.withOpacity(0.5),
              margin: const EdgeInsets.symmetric(horizontal: 2)),
        ],
      ),
    );
  }
}

class _VisaBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'VISA',
        style: TextStyle(
          color: Color(0xFF1A1F71),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MastercardBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 18,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withOpacity(0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ANIMATED GREEN CHECKMARK PAINTER ──
class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.72)
      ..lineTo(size.width * 0.76, size.height * 0.32);

    final m = path.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * progress), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
