import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../data/court_aliases.dart';
import '../data/seed_courts.dart';
import '../models/court_suggestion.dart';

class CourtSearchService {
  static const double riveraLivramentoCenterLat = -30.8920;
  static const double riveraLivramentoCenterLon = -55.5370;
  static const double _westLon = -55.67;
  static const double _eastLon = -55.40;
  static const double _northLat = -30.80;
  static const double _southLat = -31.00;

  Future<List<CourtSuggestion>> searchNearbyCourts({
    required String query,
    required double userLatitude,
    required double userLongitude,
    double radiusKm = 15,
  }) async {
    final String normalized = _normalize(query);
    final Set<String> searchTerms = _expandSearchTerms(normalized);

    final List<CourtSuggestion> seed = _searchSeed(
      searchTerms,
      userLatitude,
      userLongitude,
      radiusKm,
    );

    final List<CourtSuggestion> api = await _searchNominatim(
      searchTerms,
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
    Set<String> searchTerms,
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
          final String normalizedName = _normalize(court.name);
          final bool matchesName =
              searchTerms.isEmpty || searchTerms.any((String term) => normalizedName.contains(term));
          return matchesName && court.distanceKm <= radiusKm;
        })
        .toList();
  }

  Future<List<CourtSuggestion>> _searchNominatim(
    Set<String> searchTerms,
    double userLatitude,
    double userLongitude,
    double radiusKm,
  ) async {
    if (searchTerms.isEmpty) return <CourtSuggestion>[];

    try {
      final List<String> scopedQueries = <String>[];
      for (final String term in searchTerms) {
        scopedQueries.add('$term cancha futbol, Rivera, Uruguay');
        scopedQueries.add('$term cancha futebol, Santana do Livramento, Rio Grande do Sul, Brasil');
      }

      final List<CourtSuggestion> collected = <CourtSuggestion>[];
      for (final String scoped in scopedQueries) {
        final Uri uri = Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
          'format': 'jsonv2',
          'q': scoped,
          'limit': '20',
          'addressdetails': '0',
          'countrycodes': 'uy,br',
          'viewbox': '$_westLon,$_northLat,$_eastLon,$_southLat',
          'bounded': '1',
        });

        final http.Response response = await http.get(uri, headers: <String, String>{
          'User-Agent': 'salefulbo-app/1.0 (matchmaking)',
        });
        if (response.statusCode != 200) {
          continue;
        }

        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        collected.addAll(
          data.whereType<Map<String, dynamic>>().map((Map<String, dynamic> item) {
            final double lat = double.tryParse('${item['lat']}') ?? 0;
            final double lon = double.tryParse('${item['lon']}') ?? 0;
            final String display = (item['display_name'] as String? ?? '').toLowerCase();
            final bool inTargetRegion =
                display.contains('rivera') || display.contains('livramento') || display.contains('santana');
            if (!inTargetRegion) {
              return const CourtSuggestion(
                name: '',
                latitude: 0,
                longitude: 0,
                distanceKm: 9999,
                source: 'api',
              );
            }

            final double distance = _distanceKm(userLatitude, userLongitude, lat, lon);
            return CourtSuggestion(
              name: (item['display_name'] as String? ?? 'Cancha sin nombre').split(',').first,
              latitude: lat,
              longitude: lon,
              distanceKm: distance,
              source: 'api',
            );
          }),
        );
      }

        return collected
          .where((CourtSuggestion court) => court.name.isNotEmpty && court.distanceKm <= radiusKm)
          .toList();
    } catch (_) {
      return <CourtSuggestion>[];
    }
  }

  Set<String> _expandSearchTerms(String query) {
    if (query.isEmpty) return <String>{};

    final Set<String> terms = <String>{query};
    for (final CourtAlias alias in riveraLivramentoCourtAliases) {
      final String canonical = _normalize(alias.canonical);
      final List<String> normalizedAliases =
          alias.aliases.map((String aliasValue) => _normalize(aliasValue)).toList();

      if (canonical.contains(query) || query.contains(canonical)) {
        terms.add(canonical);
      }

      final bool aliasMatched = normalizedAliases.any(
        (String aliasValue) => aliasValue.contains(query) || query.contains(aliasValue),
      );
      if (aliasMatched) {
        terms.add(canonical);
        terms.addAll(normalizedAliases);
      }
    }

    return terms;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
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
