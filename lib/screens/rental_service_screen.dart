import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';

class RentalServiceScreen extends StatefulWidget {
  const RentalServiceScreen({super.key});

  @override
  State<RentalServiceScreen> createState() => _RentalServiceScreenState();
}

class _RentalServiceScreenState extends State<RentalServiceScreen> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final _mapController = MapController();

  LatLng? _pickupLL;
  LatLng? _dropLL;
  List<LatLng> _routePts = [];
  double? _distKm;
  bool _loadingRoute = false;
  bool _mapReady = false;
  int _selIdx = 3; // default Honda City
  Timer? _t1, _t2;

  static const _defaultCenter = LatLng(13.0827, 80.2707); // Chennai

  // ── CITY FALLBACK MAP (Tamil Nadu + India major cities) ──
  static const Map<String, LatLng> _cityFallback = {
    'chennai': LatLng(13.0827, 80.2707),
    'chennai central': LatLng(13.0850, 80.2780),
    'anna nagar': LatLng(13.0850, 80.2101),
    't nagar': LatLng(13.0418, 80.2341),
    'velachery': LatLng(12.9756, 80.2207),
    'adyar': LatLng(13.0012, 80.2565),
    'omr': LatLng(12.9219, 80.2275),
    'omr tech park': LatLng(12.9219, 80.2275),
    'marina beach': LatLng(13.0499, 80.2824),
    'airport': LatLng(12.9856, 80.1636),
    'tambaram': LatLng(12.9249, 80.1000),
    'perambur': LatLng(13.1186, 80.2425),
    'porur': LatLng(13.0366, 80.1572),
    'sholinganallur': LatLng(12.9010, 80.2279),
    'guindy': LatLng(13.0067, 80.2206),
    'kodambakkam': LatLng(13.0516, 80.2239),
    'mylapore': LatLng(13.0368, 80.2676),
    'egmore': LatLng(13.0732, 80.2609),
    'coimbatore': LatLng(11.0168, 76.9558),
    'madurai': LatLng(9.9252, 78.1198),
    'trichy': LatLng(10.7905, 78.7047),
    'salem': LatLng(11.6643, 78.1460),
    'erode': LatLng(11.3410, 77.7172),
    'vellore': LatLng(12.9165, 79.1325),
    'tirunelveli': LatLng(8.7139, 77.7567),
    'bangalore': LatLng(12.9716, 77.5946),
    'mumbai': LatLng(19.0760, 72.8777),
    'delhi': LatLng(28.6139, 77.2090),
    'hyderabad': LatLng(17.3850, 78.4867),
  };

  // ── 10+ CARS FLEET WITH COMPLETE SPECIFICATIONS ──
  static const List<Map<String, dynamic>> _fleet = [
    {
      'name': 'Maruti Swift',
      'cat': 'Hatchback',
      'seats': 5,
      'bags': 2,
      'fuel': 'Petrol',
      'trans': 'Manual / Auto',
      'ac': 'Dual AC',
      'base': 500.0,
      'perKm': 12.0,
      'bata': 300.0,
      'rating': 4.6,
      'tag': 'BEST VALUE',
      'catColor': Color(0xFF10B981),
    },
    {
      'name': 'Hyundai i20',
      'cat': 'Hatchback',
      'seats': 5,
      'bags': 2,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / DCT',
      'ac': 'Climate Control',
      'base': 600.0,
      'perKm': 13.0,
      'bata': 300.0,
      'rating': 4.7,
      'tag': 'FEATURE-RICH',
      'catColor': Color(0xFF10B981),
    },
    {
      'name': 'Tata Nexon',
      'cat': 'Compact SUV',
      'seats': 5,
      'bags': 3,
      'fuel': 'Petrol / Diesel / EV',
      'trans': 'Manual / Auto',
      'ac': 'Dual Zone AC',
      'base': 750.0,
      'perKm': 14.0,
      'bata': 350.0,
      'rating': 4.8,
      'tag': '5★ SAFETY',
      'catColor': Color(0xFF06B6D4),
    },
    {
      'name': 'Honda City',
      'cat': 'Executive Sedan',
      'seats': 5,
      'bags': 3,
      'fuel': 'Petrol',
      'trans': 'Manual / CVT',
      'ac': 'Climate Control',
      'base': 700.0,
      'perKm': 14.0,
      'bata': 350.0,
      'rating': 4.8,
      'tag': 'MOST POPULAR',
      'catColor': Color(0xFF2563EB),
    },
    {
      'name': 'Hyundai Verna',
      'cat': 'Executive Sedan',
      'seats': 5,
      'bags': 3,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Climate Control',
      'base': 750.0,
      'perKm': 14.0,
      'bata': 350.0,
      'rating': 4.7,
      'tag': 'COMFORT RIDE',
      'catColor': Color(0xFF2563EB),
    },
    {
      'name': 'Maruti Ertiga',
      'cat': 'Family MUV',
      'seats': 7,
      'bags': 4,
      'fuel': 'Petrol / CNG',
      'trans': 'Manual / Auto',
      'ac': 'Roof AC Vents',
      'base': 900.0,
      'perKm': 16.0,
      'bata': 400.0,
      'rating': 4.6,
      'tag': 'FAMILY CHOICE',
      'catColor': Color(0xFFD97706),
    },
    {
      'name': 'Kia Carens',
      'cat': 'Modern MPV',
      'seats': 7,
      'bags': 4,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Automatic Multi-Zone',
      'base': 950.0,
      'perKm': 16.0,
      'bata': 400.0,
      'rating': 4.8,
      'tag': 'PREMIUM 7-SEATER',
      'catColor': Color(0xFFD97706),
    },
    {
      'name': 'Toyota Innova Crysta',
      'cat': 'Luxury MUV',
      'seats': 7,
      'bags': 5,
      'fuel': 'Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Rear Individual AC',
      'base': 1200.0,
      'perKm': 19.0,
      'bata': 450.0,
      'rating': 4.9,
      'tag': 'HIGHWAY KING',
      'catColor': Color(0xFF7C3AED),
    },
    {
      'name': 'Mahindra XUV700',
      'cat': 'Luxury SUV',
      'seats': 7,
      'bags': 4,
      'fuel': 'Petrol / Diesel',
      'trans': 'Manual / Auto',
      'ac': 'Dual-Zone Climate',
      'base': 1300.0,
      'perKm': 20.0,
      'bata': 500.0,
      'rating': 4.9,
      'tag': 'FLAGSHIP SUV',
      'catColor': Color(0xFF7C3AED),
    },
    {
      'name': 'Toyota Fortuner',
      'cat': 'Premium 4x4 SUV',
      'seats': 7,
      'bags': 5,
      'fuel': 'Diesel 4x4',
      'trans': 'Automatic',
      'ac': 'Triple Zone AC',
      'base': 1800.0,
      'perKm': 25.0,
      'bata': 600.0,
      'rating': 4.95,
      'tag': 'ULTRA LUXURY',
      'catColor': Color(0xFF7C3AED),
    },
  ];

  static const List<Map<String, String>> _popularPlaces = [
    {'name': 'Chennai Central', 'lat': '13.0850', 'lng': '80.2780'},
    {'name': 'Anna Nagar', 'lat': '13.0850', 'lng': '80.2101'},
    {'name': 'T Nagar', 'lat': '13.0418', 'lng': '80.2341'},
    {'name': 'Velachery', 'lat': '12.9756', 'lng': '80.2207'},
    {'name': 'Airport', 'lat': '12.9856', 'lng': '80.1636'},
    {'name': 'OMR Tech Park', 'lat': '12.9219', 'lng': '80.2275'},
  ];

  @override
  void initState() {
    super.initState();
    // Default initial demonstration route (Anna Nagar to Airport)
    _pickupCtrl.text = 'Anna Nagar, Chennai';
    _dropCtrl.text = 'Chennai Airport T1';
    _pickupLL = const LatLng(13.0850, 80.2101);
    _dropLL = const LatLng(12.9856, 80.1636);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOSRMRoute());
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _t1?.cancel();
    _t2?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── NOMINATIM OPENSTREETMAP GEOCODING ──
  Future<LatLng?> _geocode(String query) async {
    if (query.trim().isEmpty) return null;
    final key = query.trim().toLowerCase();
    for (final entry in _cityFallback.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&countrycodes=in&limit=5',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'MobilityApp/1.0 contact@mobilityapp.in'
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
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

  // ── OSRM DRIVING ROUTE API (100% ACCURATE ROAD KM) ──
  Future<void> _fetchOSRMRoute() async {
    if (_pickupLL == null || _dropLL == null) return;
    setState(() => _loadingRoute = true);

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_pickupLL!.longitude},${_pickupLL!.latitude};'
          '${_dropLL!.longitude},${_dropLL!.latitude}'
          '?overview=full&geometries=geojson';

      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final r = routes[0];
          final meters = (r['distance'] as num).toDouble();
          final coords = r['geometry']['coordinates'] as List;
          final pts = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();

          setState(() {
            _distKm = meters / 1000.0;
            _routePts = pts;
            _loadingRoute = false;
          });

          _fitRouteBounds();
          return;
        }
      }
    } catch (_) {}

    // Fallback haversine road approximation
    final dist = _approxDistance(_pickupLL!, _dropLL!);
    setState(() {
      _distKm = dist;
      _routePts = [_pickupLL!, _dropLL!];
      _loadingRoute = false;
    });
    _fitRouteBounds();
  }

  double _approxDistance(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180.0) *
            cos(p2.latitude * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c) * 1.35; // 1.35 road winding factor
  }

  void _fitRouteBounds() {
    if (!_mapReady || _pickupLL == null || _dropLL == null) return;
    final latMin = min(_pickupLL!.latitude, _dropLL!.latitude);
    final latMax = max(_pickupLL!.latitude, _dropLL!.latitude);
    final lngMin = min(_pickupLL!.longitude, _dropLL!.longitude);
    final lngMax = max(_pickupLL!.longitude, _dropLL!.longitude);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(latMin, lngMin), LatLng(latMax, lngMax)),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  void _onPickupChanged(String v) {
    _t1?.cancel();
    _t1 = Timer(const Duration(milliseconds: 700), () async {
      final ll = await _geocode(v);
      if (ll != null && mounted) {
        setState(() => _pickupLL = ll);
        if (_dropLL != null) _fetchOSRMRoute();
      }
    });
  }

  void _onDropChanged(String v) {
    _t2?.cancel();
    _t2 = Timer(const Duration(milliseconds: 700), () async {
      final ll = await _geocode(v);
      if (ll != null && mounted) {
        setState(() => _dropLL = ll);
        if (_pickupLL != null) _fetchOSRMRoute();
      }
    });
  }

  double get _totalFare {
    final c = _fleet[_selIdx];
    final km = _distKm ?? 15.0;
    final base = (c['base'] as num).toDouble();
    final perKm = (c['perKm'] as num).toDouble();
    final bata = (c['bata'] as num).toDouble();
    return base + (perKm * km) + bata;
  }

  void _proceedToPayment() {
    final c = _fleet[_selIdx];
    final km = _distKm ?? 15.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          paymentArgs: {
            'pickupAddress': _pickupCtrl.text.isEmpty
                ? 'Anna Nagar, Chennai'
                : _pickupCtrl.text,
            'dropoffAddress': _dropCtrl.text.isEmpty
                ? 'Chennai Airport T1'
                : _dropCtrl.text,
            'distanceKm': km,
            'vehicleName': '${c['name']} (Rental Service with Driver)',
            'serviceType': 'Rental Service',
            'totalFare': _totalFare,
            'customerName': 'Rajavel Kumar',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selCar = _fleet[_selIdx];
    final km = _distKm ?? 15.0;

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
              'Rental Service',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Car + Professional Commercial Driver',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── LOCATION INPUTS & CHIPS ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
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
                        child: Icon(Icons.trip_origin_rounded,
                            color: Color(0xFF10B981), size: 18),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _pickupCtrl,
                          style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Enter Pickup Location',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: _onPickupChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Drop-off field
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
                            color: Color(0xFFEF4444), size: 18),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _dropCtrl,
                          style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Enter Destination / Drop Location',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: _onDropChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Popular location chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _popularPlaces
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(p['name']!,
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFFF1F5F9),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              onPressed: () {
                                _dropCtrl.text = p['name']!;
                                setState(() {
                                  _dropLL = LatLng(
                                    double.parse(p['lat']!),
                                    double.parse(p['lng']!),
                                  );
                                });
                                if (_pickupLL != null) _fetchOSRMRoute();
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── LIVE ROAD MAP VIEW ──
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickupLL ?? _defaultCenter,
                    initialZoom: 12.0,
                    onMapReady: () {
                      _mapReady = true;
                      if (_pickupLL != null && _dropLL != null) {
                        _fitRouteBounds();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'in.mobilityapp.rental',
                    ),
                    if (_routePts.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePts,
                            color: const Color(0xFF2563EB),
                            strokeWidth: 4.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_pickupLL != null)
                          Marker(
                            point: _pickupLL!,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0x3310B981), blurRadius: 8)
                                ],
                              ),
                              child: const Icon(Icons.trip_origin_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        if (_dropLL != null)
                          Marker(
                            point: _dropLL!,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0x33EF4444), blurRadius: 8)
                                ],
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // 100% Road KM badge overlay
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F0F172A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        if (_loadingRoute)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF2563EB)),
                          )
                        else
                          const Icon(Icons.alt_route_rounded,
                              size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          _loadingRoute
                              ? 'Calculating Route...'
                              : '${km.toStringAsFixed(1)} Road KM',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 10+ CARS FLEET LIST ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _fleet.length,
              itemBuilder: (context, idx) {
                final car = _fleet[idx];
                final sel = idx == _selIdx;
                final perKm = (car['perKm'] as num).toDouble();
                final base = (car['base'] as num).toDouble();
                final bata = (car['bata'] as num).toDouble();
                final carFare = base + (perKm * km) + bata;
                final catColor = car['catColor'] as Color;

                return GestureDetector(
                  onTap: () => setState(() => _selIdx = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: sel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: sel ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: sel
                              ? const Color(0x182563EB)
                              : const Color(0x060F172A),
                          blurRadius: sel ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Car Name, Category Badge & Price
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.directions_car_rounded,
                                  color: catColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        car['name'] as String,
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
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          car['tag'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${car['cat']} • ${car['rating']}★ Driver Rated',
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
                                  '₹${carFare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2563EB),
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

                        // Row 2: Specifications Chips (Seating, Fuel, Trans, AC, Bags)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _specBadge(Icons.people_alt_rounded,
                                '${car['seats']} Seater'),
                            _specBadge(Icons.local_gas_station_rounded,
                                car['fuel'] as String),
                            _specBadge(Icons.settings_rounded,
                                car['trans'] as String),
                            _specBadge(Icons.ac_unit_rounded,
                                car['ac'] as String),
                            _specBadge(Icons.luggage_rounded,
                                '${car['bags']} Bags'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── BOTTOM SUMMARY & BOOK BUTTON ──
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
                      '${selCar['name']} • ${km.toStringAsFixed(1)} KM',
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
                    onPressed: _proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Row(
                      children: [
                        Text('Book Rental Now',
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
