import 'package:hive_flutter/hive_flutter.dart';

import '../models/match_post.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _boxName = 'salefulbo_box';
  static const String _matchesKey = 'matches';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_boxName);
  }

  Future<List<MatchPost>> loadMatches() async {
    final Box<dynamic> box = Hive.box<dynamic>(_boxName);
    final List<dynamic> rawList = (box.get(_matchesKey) as List<dynamic>?) ?? <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((Map map) => MatchPost.fromMap(Map<dynamic, dynamic>.from(map)))
        .toList();
  }

  Future<void> saveMatches(List<MatchPost> matches) async {
    final Box<dynamic> box = Hive.box<dynamic>(_boxName);
    await box.put(
      _matchesKey,
      matches.map((MatchPost match) => match.toMap()).toList(),
    );
  }
}
