import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'vehicle_selection_page.dart';

class RoutePlannerScreen extends StatefulWidget {
  final String serviceType;
  const RoutePlannerScreen({super.key, required this.serviceType});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _mapController = MapController();

  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  List<LatLng> _routePoints = [];
  double? _distanceKm;
  bool _loadingRoute = false;
  bool _mapReady = false;

  Timer? _pickupDebounce;
  Timer? _dropDebounce;

  static const _defaultCenter = LatLng(13.0827, 80.2707); // Chennai

  static const List<Map<String, String>> _popular = [
    {'name': 'Chennai Central', 'lat': '13.0850', 'lng': '80.2780'},
    {'name': 'Anna Nagar', 'lat': '13.0850', 'lng': '80.2101'},
    {'name': 'T Nagar', 'lat': '13.0418', 'lng': '80.2341'},
    {'name': 'Velachery', 'lat': '12.9756', 'lng': '80.2207'},
    {'name': 'Airport', 'lat': '12.9856', 'lng': '80.1636'},
    {'name': 'Adyar', 'lat': '13.0012', 'lng': '80.2565'},
    {'name': 'OMR Tech Park', 'lat': '12.9219', 'lng': '80.2275'},
    {'name': 'Marina Beach', 'lat': '13.0499', 'lng': '80.2824'},
  ];

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

  @override
  void initState() {
    super.initState();
    _pickupCtrl.text = 'Anna Nagar, Chennai';
    _dropoffCtrl.text = 'Chennai Airport T1';
    _pickupLatLng = const LatLng(13.0850, 80.2101);
    _dropLatLng = const LatLng(12.9856, 80.1636);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRoute());
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _pickupDebounce?.cancel();
    _dropDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

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

  Future<void> _fetchRoute() async {
    if (_pickupLatLng == null || _dropLatLng == null) return;
    setState(() => _loadingRoute = true);

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_pickupLatLng!.longitude},${_pickupLatLng!.latitude};'
          '${_dropLatLng!.longitude},${_dropLatLng!.latitude}'
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
            _distanceKm = meters / 1000.0;
            _routePoints = pts;
            _loadingRoute = false;
          });

          _fitBounds();
          return;
        }
      }
    } catch (_) {}

    // Fallback
    final d = _approxDist(_pickupLatLng!, _dropLatLng!);
    setState(() {
      _distanceKm = d;
      _routePoints = [_pickupLatLng!, _dropLatLng!];
      _loadingRoute = false;
    });
    _fitBounds();
  }

  double _approxDist(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180.0) *
            cos(p2.latitude * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c) * 1.35;
  }

  void _fitBounds() {
    if (!_mapReady || _pickupLatLng == null || _dropLatLng == null) return;
    final latMin = min(_pickupLatLng!.latitude, _dropLatLng!.latitude);
    final latMax = max(_pickupLatLng!.latitude, _dropLatLng!.latitude);
    final lngMin = min(_pickupLatLng!.longitude, _dropLatLng!.longitude);
    final lngMax = max(_pickupLatLng!.longitude, _dropLatLng!.longitude);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(latMin, lngMin), LatLng(latMax, lngMax)),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  void _onPickupChanged(String val) {
    _pickupDebounce?.cancel();
    _pickupDebounce = Timer(const Duration(milliseconds: 700), () async {
      final ll = await _geocode(val);
      if (ll != null && mounted) {
        setState(() => _pickupLatLng = ll);
        if (_dropLatLng != null) _fetchRoute();
      }
    });
  }

  void _onDropChanged(String val) {
    _dropDebounce?.cancel();
    _dropDebounce = Timer(const Duration(milliseconds: 700), () async {
      final ll = await _geocode(val);
      if (ll != null && mounted) {
        setState(() => _dropLatLng = ll);
        if (_pickupLatLng != null) _fetchRoute();
      }
    });
  }

  void _proceedToVehicles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleSelectionPage(
          routeArgs: {
            'pickupAddress': _pickupCtrl.text.isEmpty
                ? 'Anna Nagar, Chennai'
                : _pickupCtrl.text,
            'dropoffAddress': _dropoffCtrl.text.isEmpty
                ? 'Chennai Airport T1'
                : _dropoffCtrl.text,
            'distanceKm': _distanceKm ?? 15.0,
            'serviceType': widget.serviceType,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceKm ?? 15.0;

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
              'Self-Drive Car Rental',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Drive Yourself with Zero Deposit • Live Road Route',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── LOCATION INPUTS ──
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
                          controller: _dropoffCtrl,
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
                    children: _popular
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
                                _dropoffCtrl.text = p['name']!;
                                setState(() {
                                  _dropLatLng = LatLng(
                                    double.parse(p['lat']!),
                                    double.parse(p['lng']!),
                                  );
                                });
                                if (_pickupLatLng != null) _fetchRoute();
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

          // ── INTERACTIVE LIVE MAP ──
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickupLatLng ?? _defaultCenter,
                    initialZoom: 12.0,
                    onMapReady: () {
                      _mapReady = true;
                      if (_pickupLatLng != null && _dropLatLng != null) {
                        _fitBounds();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'in.mobilityapp.selfdrive',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF10B981),
                            strokeWidth: 4.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_pickupLatLng != null)
                          Marker(
                            point: _pickupLatLng!,
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
                        if (_dropLatLng != null)
                          Marker(
                            point: _dropLatLng!,
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

                // Distance Float Card
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F0F172A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route_rounded,
                            size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accurate Road Distance',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B)),
                            ),
                            Text(
                              _loadingRoute
                                  ? 'Routing...'
                                  : '${dist.toStringAsFixed(1)} KM',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM PROCEED BUTTON ──
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
                    const Text(
                      'Ready to choose your car?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '10+ Self-Drive Cars Available',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _proceedToVehicles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: const Row(
                      children: [
                        Text('Select Car',
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
}
