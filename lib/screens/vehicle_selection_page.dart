import 'package:flutter/material.dart';
import 'payment_screen.dart';

class VehicleSelectionPage extends StatefulWidget {
  final Map<String, dynamic>? routeArgs;
  final String? serviceId;
  final String? serviceTitle;
  final IconData? serviceIcon;

  const VehicleSelectionPage({
    super.key,
    this.routeArgs,
    this.serviceId,
    this.serviceTitle,
    this.serviceIcon,
  });

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  int _selectedIndex = 2; // default Tata Nexon

  Map<String, dynamic> get _args => widget.routeArgs ?? {};
  double get _distanceKm => (_args['distanceKm'] as num?)?.toDouble() ?? 15.0;
  String get _pickup => _args['pickupAddress']?.toString() ?? 'Anna Nagar, Chennai';
  String get _dropoff => _args['dropoffAddress']?.toString() ?? 'Chennai Airport T1';
  String get _serviceType => _args['serviceType']?.toString() ?? 'self_drive';

  // ── 10+ CARS FLEET FOR SELF-DRIVE WITH FULL SPECIFICATIONS ──
  static const List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Maruti Swift',
      'subtitle': 'Best city hatchback • Easy to park',
      'category': 'Hatchback',
      'seats': 5,
      'fuel': 'Petrol',
      'trans': 'Manual / Auto',
      'ac': 'Dual AC',
      'luggage': '2 Bags',
      'baseFare': 500.0,
      'perKm': 12.0,
      'deposit': 0.0,
      'tag': 'BEST VALUE',
      'tagColor': Color(0xFF10B981),
      'rating': 4.6,
    },
    {
      'name': 'Hyundai i20',
      'subtitle': 'Premium hatchback • Sunroof & tech',
      'category': 'Hatchback',
      'seats': 5,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / DCT',
      'ac': 'Climate Control',
      'luggage': '2 Bags',
      'baseFare': 600.0,
      'perKm': 13.0,
      'deposit': 0.0,
      'tag': 'FEATURE-RICH',
      'tagColor': Color(0xFF10B981),
      'rating': 4.7,
    },
    {
      'name': 'Tata Nexon',
      'subtitle': 'Compact SUV • 5-Star Global NCAP safety',
      'category': 'Compact SUV',
      'seats': 5,
      'fuel': 'Petrol / Diesel / EV',
      'trans': 'Manual / Auto',
      'ac': 'Dual Zone AC',
      'luggage': '3 Bags',
      'baseFare': 750.0,
      'perKm': 14.0,
      'deposit': 0.0,
      'tag': '5★ SAFETY',
      'tagColor': Color(0xFF06B6D4),
      'rating': 4.8,
    },
    {
      'name': 'Honda City',
      'subtitle': 'Executive sedan • Supreme comfort',
      'category': 'Executive Sedan',
      'seats': 5,
      'fuel': 'Petrol',
      'trans': 'Manual / CVT',
      'ac': 'Climate Control',
      'luggage': '3 Bags',
      'baseFare': 700.0,
      'perKm': 14.0,
      'deposit': 0.0,
      'tag': 'MOST POPULAR',
      'tagColor': Color(0xFF2563EB),
      'rating': 4.8,
    },
    {
      'name': 'Hyundai Verna',
      'subtitle': 'Turbocharged sedan • Fast & stylish',
      'category': 'Executive Sedan',
      'seats': 5,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Climate Control',
      'luggage': '3 Bags',
      'baseFare': 750.0,
      'perKm': 14.0,
      'deposit': 0.0,
      'tag': 'SPORT SEDAN',
      'tagColor': Color(0xFF2563EB),
      'rating': 4.7,
    },
    {
      'name': 'Maruti Ertiga',
      'subtitle': 'Smart 7-seater MUV • Spacious family ride',
      'category': 'Family MUV',
      'seats': 7,
      'fuel': 'Petrol / CNG',
      'trans': 'Manual / Auto',
      'ac': 'Roof AC Vents',
      'luggage': '4 Bags',
      'baseFare': 900.0,
      'perKm': 16.0,
      'deposit': 0.0,
      'tag': 'FAMILY CHOICE',
      'tagColor': Color(0xFFD97706),
      'rating': 4.6,
    },
    {
      'name': 'Kia Carens',
      'subtitle': 'Modern family MPV • Ventilated seats',
      'category': 'Modern MPV',
      'seats': 7,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Multi-Zone Auto',
      'luggage': '4 Bags',
      'baseFare': 950.0,
      'perKm': 16.0,
      'deposit': 0.0,
      'tag': 'PREMIUM 7-SEATER',
      'tagColor': Color(0xFFD97706),
      'rating': 4.8,
    },
    {
      'name': 'Toyota Innova Crysta',
      'subtitle': 'Legendary comfort • Captain seats',
      'category': 'Luxury MUV',
      'seats': 7,
      'fuel': 'Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Rear Individual AC',
      'luggage': '5 Bags',
      'baseFare': 1200.0,
      'perKm': 19.0,
      'deposit': 0.0,
      'tag': 'HIGHWAY KING',
      'tagColor': Color(0xFF7C3AED),
      'rating': 4.9,
    },
    {
      'name': 'Mahindra XUV700',
      'subtitle': 'Luxury 7-seater SUV • Panoramic skyroof',
      'category': 'Luxury SUV',
      'seats': 7,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Dual-Zone Climate',
      'luggage': '4 Bags',
      'baseFare': 1300.0,
      'perKm': 20.0,
      'deposit': 0.0,
      'tag': 'FLAGSHIP SUV',
      'tagColor': Color(0xFF7C3AED),
      'rating': 4.9,
    },
    {
      'name': 'Toyota Fortuner',
      'subtitle': 'Powerhouse 4x4 SUV • Command the road',
      'category': 'Premium 4x4 SUV',
      'seats': 7,
      'fuel': 'Diesel 4x4',
      'trans': 'Automatic',
      'ac': 'Triple Zone AC',
      'luggage': '5 Bags',
      'baseFare': 1800.0,
      'perKm': 25.0,
      'deposit': 0.0,
      'tag': 'ULTRA LUXURY',
      'tagColor': Color(0xFF7C3AED),
      'rating': 4.95,
    },
  ];

  double get _totalFare {
    final v = _vehicles[_selectedIndex];
    final base = (v['baseFare'] as num).toDouble();
    final perKm = (v['perKm'] as num).toDouble();
    return base + (perKm * _distanceKm);
  }

  void _proceedToCheckout() {
    final v = _vehicles[_selectedIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          paymentArgs: {
            'pickupAddress': _pickup,
            'dropoffAddress': _dropoff,
            'distanceKm': _distanceKm,
            'vehicleName': '${v['name']} (Self-Drive)',
            'serviceType': _serviceType == 'self_drive'
                ? 'Self-Drive Car Rental'
                : 'Rental Service',
            'totalFare': _totalFare,
            'customerName': 'Rajavel Kumar',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selVehicle = _vehicles[_selectedIndex];

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
              'Select Self-Drive Car',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Zero Deposit • Instant Confirmation',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── ROUTE SUMMARY CHIP STRIP ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin_rounded,
                              size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _pickup,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _dropoff,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alt_route_rounded,
                          size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Text(
                        '${_distanceKm.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 10+ VEHICLES LIST ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              itemBuilder: (context, idx) {
                final v = _vehicles[idx];
                final sel = idx == _selectedIndex;
                final base = (v['baseFare'] as num).toDouble();
                final perKm = (v['perKm'] as num).toDouble();
                final fare = base + (perKm * _distanceKm);
                final tagColor = v['tagColor'] as Color;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: sel ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                        width: sel ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: sel
                              ? const Color(0x1810B981)
                              : const Color(0x060F172A),
                          blurRadius: sel ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Icon, Name, Tag & Fare
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.directions_car_rounded,
                                  color: tagColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        v['name'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          v['tag'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFF065F46),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    v['subtitle'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${fare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                Text(
                                  '₹${perKm.toStringAsFixed(0)}/KM + Base ₹${base.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Specs (Seats, Fuel, Trans, AC, Luggage)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _specBadge(Icons.people_alt_rounded,
                                '${v['seats']} Seater'),
                            _specBadge(Icons.local_gas_station_rounded,
                                v['fuel'] as String),
                            _specBadge(Icons.settings_rounded,
                                v['trans'] as String),
                            _specBadge(Icons.ac_unit_rounded,
                                v['ac'] as String),
                            _specBadge(Icons.luggage_rounded,
                                v['luggage'] as String),
                            _specBadge(Icons.shield_rounded, 'Zero Deposit'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── BOTTOM SUMMARY BAR ──
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
                      '${selVehicle['name']} • ${_distanceKm.toStringAsFixed(1)} KM',
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
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Row(
                      children: [
                        Text('Book Self-Drive',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
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

  Widget _specBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
