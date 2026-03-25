import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../data/seed_courts.dart';
import '../models/court_suggestion.dart';

class CourtSearchService {
  Future<List<CourtSuggestion>> searchNearbyCourts({
    required String query,
    required double userLatitude,
    required double userLongitude,
    double radiusKm = 15,
  }) async {
    final String normalized = query.trim().toLowerCase();
    final List<CourtSuggestion> seed = _searchSeed(
      normalized,
      userLatitude,
      userLongitude,
      radiusKm,
    );

    final List<CourtSuggestion> api = await _searchNominatim(
      normalized,
      userLatitude,
      userLongitude,
      radiusKm,
    );

    final Map<String, CourtSuggestion> byName = <String, CourtSuggestion>{
      for (final CourtSuggestion court in seed) court.name.toLowerCase(): court,
      for (final CourtSuggestion court in api) court.name.toLowerCase(): court,
    };

    final List<CourtSuggestion> merged = byName.values.toList()
      ..sort((CourtSuggestion a, CourtSuggestion b) => a.distanceKm.compareTo(b.distanceKm));

    return merged;
  }

  List<CourtSuggestion> _searchSeed(
    String query,
    double userLatitude,
    double userLongitude,
    double radiusKm,
  ) {
    return riveraLivramentoSeedCourts
        .map((CourtSuggestion court) {
          final double distance = _distanceKm(
            userLatitude,
            userLongitude,
            court.latitude,
            court.longitude,
          );
          return CourtSuggestion(
            name: court.name,
            latitude: court.latitude,
            longitude: court.longitude,
            distanceKm: distance,
            source: court.source,
          );
        })
        .where((CourtSuggestion court) {
          final bool matchesName = query.isEmpty || court.name.toLowerCase().contains(query);
          return matchesName && court.distanceKm <= radiusKm;
        })
        .toList();
  }

  Future<List<CourtSuggestion>> _searchNominatim(
    String query,
    double userLatitude,
    double userLongitude,
    double radiusKm,
  ) async {
    if (query.isEmpty) return <CourtSuggestion>[];

    final Uri uri = Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
      'format': 'jsonv2',
      'q': '$query cancha futbol',
      'limit': '20',
      'addressdetails': '0',
      'bounded': '0',
    });

    try {
      final http.Response response = await http.get(uri, headers: <String, String>{
        'User-Agent': 'salefulbo-app/1.0 (matchmaking)',
      });
      if (response.statusCode != 200) {
        return <CourtSuggestion>[];
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) {
            final double lat = double.tryParse('${item['lat']}') ?? 0;
            final double lon = double.tryParse('${item['lon']}') ?? 0;
            final double distance = _distanceKm(userLatitude, userLongitude, lat, lon);
            return CourtSuggestion(
              name: (item['display_name'] as String? ?? 'Cancha sin nombre').split(',').first,
              latitude: lat,
              longitude: lon,
              distanceKm: distance,
              source: 'api',
            );
          })
          .where((CourtSuggestion court) => court.distanceKm <= radiusKm)
          .toList();
    } catch (_) {
      return <CourtSuggestion>[];
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}
