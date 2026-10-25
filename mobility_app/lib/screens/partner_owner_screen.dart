import 'package:flutter/material.dart';

enum _PartnerPage { registration, success, dashboard }

class PartnerOwnerScreen extends StatefulWidget {
  const PartnerOwnerScreen({super.key});

  @override
  State<PartnerOwnerScreen> createState() => _PartnerOwnerScreenState();
}

class _PartnerOwnerScreenState extends State<PartnerOwnerScreen>
    with SingleTickerProviderStateMixin {
  _PartnerPage _page = _PartnerPage.registration;
  late AnimationController _tickCtrl;
  late Animation<double> _scaleAnim;
  int _step = 0; // 0 = Vehicle Details, 1 = 5 Mandatory Proofs

  // Section A — Vehicle Details
  final _makeCtrl = TextEditingController(text: 'Hyundai Creta SX');
  final _regCtrl = TextEditingController(text: 'TN 09 BX 4512');
  final _yearCtrl = TextEditingController(text: '2023');
  String _vType = 'SUV';
  String _fuel = 'Petrol';

  // Section B — 5 Mandatory Proofs
  final _licCtrl = TextEditingController(text: 'TN-2016-0034891');
  final _aadhaarCtrl = TextEditingController(text: '9845 2314 6789');
  final _addressCtrl = TextEditingController(text: 'Anna Nagar West, Chennai');
  final _policeCtrl = TextEditingController(text: 'PV-CHN-2024-8841');
  final _expCtrl = TextEditingController(text: '7 Years Commercial Exp');

  String? _error;

  // Mock fleet & earnings data (shown only AFTER registration is complete)
  final List<Map<String, dynamic>> _fleet = [
    {
      'reg': 'TN 09 BX 4512',
      'model': 'Hyundai Creta SX',
      'status': 'Active & Earning',
      'trips': 28,
      'earnings': 24800.0,
      'rating': 4.9,
    },
    {
      'reg': 'TN 01 AB 1234',
      'model': 'Maruti Swift Dzire',
      'status': 'On Trip',
      'trips': 142,
      'earnings': 48420.0,
      'rating': 4.8,
    },
    {
      'reg': 'TN 02 CD 5678',
      'model': 'Toyota Innova Crysta',
      'status': 'Available',
      'trips': 89,
      'earnings': 64680.0,
      'rating': 4.9,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _tickCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _makeCtrl.dispose();
    _regCtrl.dispose();
    _yearCtrl.dispose();
    _expCtrl.dispose();
    _licCtrl.dispose();
    _aadhaarCtrl.dispose();
    _addressCtrl.dispose();
    _policeCtrl.dispose();
    super.dispose();
  }

  bool _validateStep0() {
    if (_makeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter vehicle make and model');
      return false;
    }
    if (_regCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter vehicle registration number');
      return false;
    }
    if (_yearCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter manufacturing year');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_licCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Driving License Proof is mandatory');
      return false;
    }
    if (_aadhaarCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Aadhaar Identity Proof is mandatory');
      return false;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Address Proof is mandatory');
      return false;
    }
    if (_policeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Police Clearance Proof is mandatory');
      return false;
    }
    if (_expCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Driving Experience Proof is mandatory');
      return false;
    }
    return true;
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_step == 0 && _validateStep0()) {
      setState(() => _step = 1);
    } else if (_step == 1 && _validateStep1()) {
      setState(() => _page = _PartnerPage.success);
      _tickCtrl.forward();
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _page == _PartnerPage.dashboard
                  ? 'Partner Dashboard'
                  : 'Partner & Car Ownership',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              _page == _PartnerPage.dashboard
                  ? 'Fleet Overview & Weekly Earnings'
                  : 'Vehicle & 5 Proofs Submission First',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: _page == _PartnerPage.registration
          ? _buildRegistrationForm()
          : _page == _PartnerPage.success
              ? _buildSuccessView()
              : _buildDashboardView(),
    );
  }

  // ── 1. REGISTRATION FORM (VEHICLE & PROOFS FIRST) ──
  Widget _buildRegistrationForm() {
    return Column(
      children: [
        // Step progress header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              _stepDot(0, '1. Vehicle Details'),
              Expanded(
                child: Container(
                  height: 2,
                  color: _step > 0
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              _stepDot(1, '2. 5 Mandatory Proofs'),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_step == 0) _buildVehicleSection(),
                if (_step == 1) _buildProofsSection(),

                const SizedBox(height: 24),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _step == 0
                              ? 'Continue to 5 Mandatory Proofs'
                              : 'Submit & Register as Partner',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _step == 0
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_step == 1) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _step = 0),
                      child: const Text(
                        '← Back to Vehicle Details',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepDot(int idx, String label) {
    final active = _step >= idx;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${idx + 1}',
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ── VEHICLE DETAILS FORM ──
  Widget _buildVehicleSection() {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: Color(0xFF7C3AED), size: 22),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Vehicle Details Form',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Attach your car to our certified mobility network',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _inputField(_makeCtrl, 'Vehicle Make & Model', 'e.g. Hyundai Creta, Maruti Swift', Icons.car_repair_rounded),
          const SizedBox(height: 14),
          _inputField(_regCtrl, 'Vehicle Registration Number', 'e.g. TN 09 BX 4512', Icons.pin_rounded),
          const SizedBox(height: 14),
          _inputField(_yearCtrl, 'Manufacturing Year', 'e.g. 2023', Icons.calendar_today_rounded, isNumber: true),
          const SizedBox(height: 14),

          // Vehicle Type selector
          const Text('Vehicle Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['Hatchback', 'Sedan', 'SUV', 'MUV'].map((type) {
              final sel = _vType == type;
              return ChoiceChip(
                label: Text(type),
                selected: sel,
                selectedColor: const Color(0xFFF5F3FF),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: TextStyle(
                  color: sel ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                side: BorderSide(color: sel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                onSelected: (_) => setState(() => _vType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Fuel Type selector
          const Text('Fuel Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['Petrol', 'Diesel', 'CNG', 'EV'].map((fuel) {
              final sel = _fuel == fuel;
              return ChoiceChip(
                label: Text(fuel),
                selected: sel,
                selectedColor: const Color(0xFFF5F3FF),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: TextStyle(
                  color: sel ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                side: BorderSide(color: sel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                onSelected: (_) => setState(() => _fuel = fuel),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 5 MANDATORY PROOFS FORM ──
  Widget _buildProofsSection() {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Color(0xFF7C3AED), size: 22),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 2: 5 Mandatory Proofs Form',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'All 5 verification proofs required before registration',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Proof 1
          _proofInputField(_licCtrl, '1. Driving License Proof', 'Commercial LMV license number', Icons.badge_rounded),
          const SizedBox(height: 14),

          // Proof 2
          _proofInputField(_aadhaarCtrl, '2. Aadhaar Identity Proof', '12-digit UIDAI number', Icons.fingerprint_rounded),
          const SizedBox(height: 14),

          // Proof 3
          _proofInputField(_addressCtrl, '3. Address Proof', 'Current residential address', Icons.home_rounded),
          const SizedBox(height: 14),

          // Proof 4
          _proofInputField(_policeCtrl, '4. Police Verification Proof', 'Police clearance certificate reference', Icons.security_rounded),
          const SizedBox(height: 14),

          // Proof 5
          _proofInputField(_expCtrl, '5. Driving Experience Proof', 'Years of professional driving experience', Icons.workspace_premium_rounded),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, String hint, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _proofInputField(TextEditingController ctrl, String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('MANDATORY', style: TextStyle(color: Color(0xFF065F46), fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            suffixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
          ),
        ),
      ],
    );
  }

  // ── 2. REGISTRATION SUCCESS VIEW WITH ANIMATION ──
  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF10B981), size: 54),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Partner Registration Successful! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your vehicle details and 5 mandatory verification proofs have been approved. Welcome to the Mobility App Partner Network!',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _successRow('Registered Car:', '${_makeCtrl.text} (${_regCtrl.text})'),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _successRow('Category / Fuel:', '$_vType • $_fuel'),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _successRow('Proofs Status:', '5/5 Mandatory Checks Verified ✅'),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _successRow('Payout Schedule:', 'Weekly Guaranteed Direct Deposit'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    setState(() => _page = _PartnerPage.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Open Partner Dashboard ➔',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 12)),
      ],
    );
  }

  // ── 3. PARTNER DASHBOARD (SHOWN ONLY AFTER SUCCESS) ──
  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings banner card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x337C3AED),
                  blurRadius: 18,
                  offset: Offset(0, 8),
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
                      'TOTAL FLEET EARNINGS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '82% REV SHARE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '₹1,37,900',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Weekly payout arriving this Friday • 259 total fleet trips',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Fleet header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR REGISTERED FLEET',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${_fleet.length} Active Vehicles',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fleet cards
          ..._fleet.map(
            (car) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: Color(0xFF7C3AED), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car['model'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${car['reg']} • ${car['trips']} trips completed',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(car['earnings'] as double).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          car['status'] as String,
                          style: const TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add another car button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, color: Color(0xFF7C3AED)),
              label: const Text(
                'Register Another Vehicle',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDD6FE), width: 1.5),
                backgroundColor: const Color(0xFFF5F3FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                setState(() {
                  _page = _PartnerPage.registration;
                  _step = 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
