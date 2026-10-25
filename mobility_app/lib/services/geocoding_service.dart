import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  GeocodingService._internal();
  static final GeocodingService instance = GeocodingService._internal();

  static final Map<String, LatLng> _knownLandmarks = {
    'central station': const LatLng(13.0827, 80.2707),
    'central railway': const LatLng(13.0850, 80.2780),
    'central railway station': const LatLng(13.0850, 80.2780),
    'central railway station hub': const LatLng(13.0850, 80.2780),
    'chennai central': const LatLng(13.0850, 80.2780),
    'airport': const LatLng(12.9856, 80.1636),
    'airport t1': const LatLng(12.9856, 80.1636),
    'international airport': const LatLng(12.9856, 80.1636),
    'tech park': const LatLng(12.9719, 80.2458),
    'marina beach': const LatLng(13.0499, 80.2824),
    'guindy': const LatLng(13.0067, 80.2025),
    't nagar': const LatLng(13.0418, 80.2341),
    'velachery': const LatLng(12.9756, 80.2207),
    'adyar': const LatLng(13.0012, 80.2565),
    'anna nagar': const LatLng(13.0850, 80.2101),
    'koyambedu': const LatLng(13.0694, 80.1948),
    'tambaram': const LatLng(12.9249, 80.1000),
    'egmore': const LatLng(13.0784, 80.2608),
  };

  Future<LatLng?> geocodeAddress(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    // Direct coordinate input: "13.0827, 80.2707"
    final coordMatch = RegExp(
      r'^([-+]?\d{1,2}(?:\.\d+)?)[,\s]+([-+]?\d{1,3}(?:\.\d+)?)$',
    ).firstMatch(cleanQuery);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return LatLng(lat, lng);
      }
    }

    // Landmark dictionary
    final lower = cleanQuery.toLowerCase();
    for (final entry in _knownLandmarks.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    // OpenStreetMap Nominatim fallback
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=1',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'MobilityPlatform/1.0'})
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body) as List;
        if (decoded.isNotEmpty) {
          final lat = double.tryParse(decoded[0]['lat'].toString());
          final lon = double.tryParse(decoded[0]['lon'].toString());
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding error: $e');
    }

    return null;
  }
}
