import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Provides reverse-geocoding via the LocationIQ HTTP API.
class LocationIqService {
  LocationIqService._();

  static const String _baseHost = 'us1.locationiq.com';
  static const String _endpoint = '/v1/reverse';

  /// API key defaults to the provided constant but can be overridden using
  /// `--dart-define=LOCATIONIQ_API_KEY=your-key`.
  static const String _apiKey = String.fromEnvironment(
    'LOCATIONIQ_API_KEY',
    defaultValue: 'pk.f41b553f474eafeb828bb40e471600ae',
  );

  static final Map<String, String> _cache = {};

  static String _cacheKey(double lat, double lon) =>
      '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';

  /// Reverse geocodes the given coordinates and returns a human-readable label.
  static Future<String?> reverseGeocode({
    double? latitude,
    double? longitude,
    GeoPoint? geoPoint,
  }) async {
    final lat = latitude ?? geoPoint?.latitude;
    final lon = longitude ?? geoPoint?.longitude;
    if (lat == null || lon == null) return null;

    final cacheKey = _cacheKey(lat, lon);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    if (_apiKey.isEmpty) {
      debugPrint('LocationIQ API key missing, skipping reverse geocode');
      return null;
    }

    final uri = Uri.https(_baseHost, _endpoint, {
      'key': _apiKey,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
      'normalizecity': '1',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('LocationIQ error ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final address = decoded['address'] as Map<String, dynamic>?;

      String? formatAddress(Map<String, dynamic>? addr) {
        if (addr == null) return null;
        final segments = <String?>[
          addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'],
          addr['state'] ?? addr['state_district'],
          addr['country'],
        ];
        final cleaned = segments
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
        if (cleaned.isNotEmpty) {
          return cleaned.join(', ');
        }
        return null;
      }

      final label =
          formatAddress(address) ?? decoded['display_name']?.toString();
      if (label != null && label.trim().isNotEmpty) {
        _cache[cacheKey] = label.trim();
        return _cache[cacheKey];
      }
    } catch (error, stackTrace) {
      debugPrint('LocationIQ reverse geocode failed: $error');
      debugPrint('$stackTrace');
    }

    return null;
  }
}
