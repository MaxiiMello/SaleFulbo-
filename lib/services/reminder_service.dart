import 'dart:async';

import '../models/match_post.dart';

class ReminderService {
  ReminderService({required this.onReminder});

  final void Function(MatchPost) onReminder;
  final Map<String, Timer> _timers = <String, Timer>{};

  void startReminder(MatchPost match) {
    _timers[match.id]?.cancel();

    // MVP: reminder every 20 minutes while app is open.
    _timers[match.id] = Timer.periodic(
      const Duration(minutes: 20),
      (_) => onReminder(match),
    );
  }

  void stopReminder(String matchId) {
    _timers.remove(matchId)?.cancel();
  }

  void dispose() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
