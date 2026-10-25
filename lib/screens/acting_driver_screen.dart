import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';

class ActingDriverScreen extends StatefulWidget {
  const ActingDriverScreen({super.key});

  @override
  State<ActingDriverScreen> createState() => _ActingDriverScreenState();
}

class _ActingDriverScreenState extends State<ActingDriverScreen> {
  final _pickupCtrl = TextEditingController(text: 'Adyar, Chennai');
  final _mapController = MapController();
  LatLng? _pickupLL = const LatLng(13.0012, 80.2565);
  bool _mapReady = false;
  int _selectedDriver = 0;
  int _shiftHours = 4;
  Timer? _debounce;

  static const _defaultCenter = LatLng(13.0827, 80.2707);

  // ── CITY FALLBACK (Tamil Nadu + India cities) ──
  static const Map<String, LatLng> _cityFallback = {
    'chennai': LatLng(13.0827, 80.2707),
    'anna nagar': LatLng(13.0850, 80.2101),
    't nagar': LatLng(13.0418, 80.2341),
    'velachery': LatLng(12.9756, 80.2207),
    'adyar': LatLng(13.0012, 80.2565),
    'omr': LatLng(12.9219, 80.2275),
    'tambaram': LatLng(12.9249, 80.1000),
    'guindy': LatLng(13.0067, 80.2206),
    'mylapore': LatLng(13.0368, 80.2676),
    'egmore': LatLng(13.0732, 80.2609),
    'airport': LatLng(12.9856, 80.1636),
    'coimbatore': LatLng(11.0168, 76.9558),
    'madurai': LatLng(9.9252, 78.1198),
    'trichy': LatLng(10.7905, 78.7047),
    'bangalore': LatLng(12.9716, 77.5946),
  };

  // ── 5 VERIFIED ACTING DRIVERS WITH 5 MANDATORY PROOFS (STRICTLY NO CARS) ──
  static const List<Map<String, dynamic>> _drivers = [
    {
      'name': 'Rajesh Kumar',
      'initial': 'R',
      'avatarColor': Color(0xFFD97706),
      'rating': 4.92,
      'trips': 1840,
      'experience': '8+ Years Exp',
      'languages': ['Tamil', 'English', 'Hindi'],
      'expertise': ['Automatic & Luxury', 'City Traffic', 'Night Drives'],
      'perHour': 149.0,
      'eta': '4 min ETA',
      'badge': 'Top Rated Pro',
      // 5 Mandatory Proofs
      'proofLicense': 'TN-2012-0012345 • Commercial LMV • Valid till Dec 2028',
      'proofAadhaar': 'XXXX-XXXX-5678 • UIDAI Biometric Identity Verified',
      'proofAddress': 'Adyar, Chennai — Residential Proof Verified',
      'proofPolice': 'PV-CHN-2024-0093 • Clear Background Certificate 2024',
      'proofExp': '8+ Years Professional Commercial Driving Record',
    },
    {
      'name': 'Arun Varma',
      'initial': 'A',
      'avatarColor': Color(0xFF2563EB),
      'rating': 4.88,
      'trips': 1210,
      'experience': '11+ Years Exp',
      'languages': ['Tamil', 'Telugu', 'English'],
      'expertise': ['Manual & Automatic', 'Highway Specialist', 'Outstation'],
      'perHour': 139.0,
      'eta': '6 min ETA',
      'badge': 'Highway Certified',
      // 5 Mandatory Proofs
      'proofLicense': 'TN-2010-0008763 • Commercial LMV+HMV • Valid till Mar 2027',
      'proofAadhaar': 'XXXX-XXXX-3412 • UIDAI Biometric Identity Verified',
      'proofAddress': 'Anna Nagar, Chennai — Residential Proof Verified',
      'proofPolice': 'PV-CHN-2024-0041 • Clear Background Certificate 2024',
      'proofExp': '11+ Years Highway & Inter-State Driving Record',
    },
    {
      'name': 'Karthik Suresh',
      'initial': 'K',
      'avatarColor': Color(0xFF10B981),
      'rating': 4.81,
      'trips': 940,
      'experience': '6+ Years Exp',
      'languages': ['Tamil', 'English'],
      'expertise': ['Manual & Automatic', 'Fast Responders', 'Office Commutes'],
      'perHour': 129.0,
      'eta': '8 min ETA',
      'badge': 'Fast Responder',
      // 5 Mandatory Proofs
      'proofLicense': 'TN-2015-0021456 • Commercial LMV • Valid till Jun 2029',
      'proofAadhaar': 'XXXX-XXXX-9234 • UIDAI Biometric Identity Verified',
      'proofAddress': 'T Nagar, Chennai — Residential Proof Verified',
      'proofPolice': 'PV-CHN-2024-0178 • Clear Background Certificate 2024',
      'proofExp': '6+ Years City & Daily Commute Driving Record',
    },
    {
      'name': 'Suresh Muthu',
      'initial': 'S',
      'avatarColor': Color(0xFF7C3AED),
      'rating': 4.95,
      'trips': 2300,
      'experience': '14+ Years Exp',
      'languages': ['Tamil', 'Malayalam', 'Kannada', 'English'],
      'expertise': ['All Transmissions', 'VIP Chauffeur', 'Long-Distance'],
      'perHour': 159.0,
      'eta': '10 min ETA',
      'badge': 'Master Veteran',
      // 5 Mandatory Proofs
      'proofLicense': 'TN-2008-0004521 • Commercial LMV+PSV • Valid till Aug 2026',
      'proofAadhaar': 'XXXX-XXXX-7891 • UIDAI Biometric Identity Verified',
      'proofAddress': 'Velachery, Chennai — Residential Proof Verified',
      'proofPolice': 'PV-CHN-2023-0055 • Clear Background Certificate 2023',
      'proofExp': '14+ Years Senior Commercial & Fleet Driving Record',
    },
    {
      'name': 'Venkatesh Rajan',
      'initial': 'V',
      'avatarColor': Color(0xFF06B6D4),
      'rating': 4.85,
      'trips': 1560,
      'experience': '9+ Years Exp',
      'languages': ['Tamil', 'English', 'Hindi'],
      'expertise': ['Automatic', 'SUV Specialist', 'Airport Transfers'],
      'perHour': 149.0,
      'eta': '5 min ETA',
      'badge': 'SUV Specialist',
      // 5 Mandatory Proofs
      'proofLicense': 'TN-2013-0017832 • Commercial LMV • Valid till Nov 2027',
      'proofAadhaar': 'XXXX-XXXX-6120 • UIDAI Biometric Identity Verified',
      'proofAddress': 'OMR, Chennai — Residential Proof Verified',
      'proofPolice': 'PV-CHN-2024-0212 • Clear Background Certificate 2024',
      'proofExp': '9+ Years High-End SUV & Commercial Record',
    },
  ];

  double get _totalFare {
    final d = _drivers[_selectedDriver];
    return (d['perHour'] as double) * _shiftHours;
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<LatLng?> _geocode(String q) async {
    if (q.trim().isEmpty) return null;
    final key = q.trim().toLowerCase();
    for (final entry in _cityFallback.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    try {
      final r = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(q)}'
          '&format=json&countrycodes=in&limit=5',
        ),
        headers: {'User-Agent': 'MobilityApp/1.0 contact@mobilityapp.in'},
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        if (list.isNotEmpty) {
          return LatLng(
            double.parse(list[0]['lat'].toString()),
            double.parse(list[0]['lon'].toString()),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  void _onPickup(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final ll = await _geocode(v);
      if (ll != null && mounted) {
        setState(() => _pickupLL = ll);
        if (_mapReady) _mapController.move(ll, 14);
      }
    });
  }

  // ── VIEW PROOF CERTIFICATE PREVIEW MODAL ──
  void _showProofCertificateModal(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_rounded,
                            color: Color(0xFFD97706), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verified Driver Proofs',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Government & Police Verified Certificate',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Certificate Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (driver['avatarColor'] as Color).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            driver['initial'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: driver['avatarColor'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${driver['badge']} • ${driver['trips']} Completed Trips',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),

                    // All 5 Proofs itemized
                    _certRow('1. Driving License Proof', driver['proofLicense'] as String, Icons.badge_rounded),
                    const SizedBox(height: 10),
                    _certRow('2. Aadhaar Identity Proof', driver['proofAadhaar'] as String, Icons.fingerprint_rounded),
                    const SizedBox(height: 10),
                    _certRow('3. Address Proof', driver['proofAddress'] as String, Icons.home_rounded),
                    const SizedBox(height: 10),
                    _certRow('4. Police Verification Proof', driver['proofPolice'] as String, Icons.security_rounded),
                    const SizedBox(height: 10),
                    _certRow('5. Driving Experience Proof', driver['proofExp'] as String, Icons.workspace_premium_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seal & Confirm
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All 5 background checks 100% verified & approved.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close Certificate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certRow(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFFD97706)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VERIFIED ✅',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  void _book() {
    final d = _drivers[_selectedDriver];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          paymentArgs: {
            'pickupAddress': _pickupCtrl.text.isEmpty
                ? 'Adyar, Chennai'
                : _pickupCtrl.text,
            'dropoffAddress': 'Driver Hired for Your Own Car',
            'distanceKm': 0.0,
            'vehicleName': '${d['name']} (Verified Acting Driver)',
            'serviceType': 'Acting Driver Services',
            'totalFare': _totalFare,
            'driverName': d['name'],
            'shiftHours': _shiftHours,
            'customerName': 'Rajavel Kumar',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selDriver = _drivers[_selectedDriver];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acting Driver Services',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Verified Drivers for Your Own Car • 5 Mandatory Proofs',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── LOCATION + SHIFT HOURS ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.location_on_rounded,
                            color: Color(0xFFD97706), size: 18),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _pickupCtrl,
                          style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Where should driver arrive?',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: _onPickup,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Shift Hours Selector
                Row(
                  children: [
                    const Text(
                      'Shift Duration:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [2, 4, 8, 12].map((hrs) {
                            final sel = _shiftHours == hrs;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('$hrs hrs'),
                                selected: sel,
                                selectedColor: const Color(0xFFFEF3C7),
                                backgroundColor: const Color(0xFFF8FAFC),
                                labelStyle: TextStyle(
                                  color: sel
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: sel
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFE2E8F0),
                                ),
                                onSelected: (_) =>
                                    setState(() => _shiftHours = hrs),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mini Map Preview for Pickup Location
          Container(
            height: 110,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pickupLL ?? _defaultCenter,
                initialZoom: 14.0,
                onMapReady: () => _mapReady = true,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.mobilityapp.actingdriver',
                ),
                if (_pickupLL != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pickupLL!,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x33D97706), blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.white,
                              size: 20),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── VERIFIED DRIVERS LIST (ONLY DRIVERS & 5 PROOFS — ZERO CARS) ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _drivers.length,
              itemBuilder: (context, idx) {
                final d = _drivers[idx];
                final sel = idx == _selectedDriver;
                final ac = d['avatarColor'] as Color;
                final driverTotal = (d['perHour'] as double) * _shiftHours;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDriver = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
                        width: sel ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: sel
                              ? const Color(0x18D97706)
                              : const Color(0x060F172A),
                          blurRadius: sel ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Avatar, Name, Rating & Rate
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: ac.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: ac.withOpacity(0.3)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                d['initial'] as String,
                                style: TextStyle(
                                  color: ac,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        d['name'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded,
                                          color: Color(0xFF10B981), size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          d['experience'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFFB45309),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFF59E0B), size: 14),
                                      Text(
                                        ' ${d['rating']} (${d['trips']} trips)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${driverTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                Text(
                                  '₹${(d['perHour'] as double).toStringAsFixed(0)}/hr • ${d['eta']}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Languages & Expertise chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...((d['languages'] as List).map((l) =>
                                _chip('🗣 $l', const Color(0xFFF1F5F9), const Color(0xFF475569)))),
                            ...((d['expertise'] as List).map((e) =>
                                _chip('⚙ $e', const Color(0xFFEFF6FF), const Color(0xFF1E40AF)))),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── 5 MANDATORY PROOFS BOX ──
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '5 MANDATORY VERIFICATION PROOFS',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        _showProofCertificateModal(d),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.visibility_rounded,
                                            size: 13, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text(
                                          'View Certificate',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _proofRow('1. Driving License Proof', d['proofLicense'] as String, Icons.badge_rounded),
                              _proofRow('2. Aadhaar Identity Proof', d['proofAadhaar'] as String, Icons.fingerprint_rounded),
                              _proofRow('3. Address Proof', d['proofAddress'] as String, Icons.home_rounded),
                              _proofRow('4. Police Verification Proof', d['proofPolice'] as String, Icons.security_rounded),
                              _proofRow('5. Driving Experience Proof', d['proofExp'] as String, Icons.workspace_premium_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── BOTTOM HIRE BUTTON ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${_totalFare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${selDriver['name']} • $_shiftHours hrs shift',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _book,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Row(
                      children: [
                        Text('Hire ${(selDriver['name'] as String).split(' ').first}',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(t, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _proofRow(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF10B981)),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'VERIFIED',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
