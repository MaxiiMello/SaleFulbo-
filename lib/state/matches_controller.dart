import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_post.dart';
import '../services/local_storage_service.dart';

final matchesControllerProvider =
    StateNotifierProvider<MatchesController, List<MatchPost>>((Ref ref) {
  return MatchesController(LocalStorageService.instance);
});

enum JoinMatchStatus { joined, alreadyJoined, full, closed, creatorCannotJoin, notFound }

enum CloseMatchStatus { closed, alreadyClosed, notAuthorized, notFound }

class JoinMatchResult {
  const JoinMatchResult({required this.status, this.match});

  final JoinMatchStatus status;
  final MatchPost? match;
}

class CloseMatchResult {
  const CloseMatchResult({required this.status, this.match});

  final CloseMatchStatus status;
  final MatchPost? match;
}

class MatchesController extends StateNotifier<List<MatchPost>> {
  MatchesController(this._storage) : super(const <MatchPost>[]) {
    _loadMatches();
  }

  final LocalStorageService _storage;

  Future<void> _loadMatches() async {
    state = await _storage.loadMatches();
  }

  Future<void> addMatch(MatchPost match) async {
    state = <MatchPost>[match, ...state];
    await _storage.saveMatches(state);
  }

  Future<void> adjustMissingPlayers(String matchId, int delta) async {
    state = state.map((MatchPost match) {
      if (match.id != matchId) return match;
      final int nextMissing = (match.missingPlayers + delta).clamp(0, match.totalPlayers);
      return match.copyWith(missingPlayers: nextMissing);
    }).toList();

    await _storage.saveMatches(state);
  }

  Future<JoinMatchResult> joinAsPlayer(String matchId, String userId) async {
    final MatchPost? target = _findById(matchId);
    if (target == null) {
      return const JoinMatchResult(status: JoinMatchStatus.notFound);
    }
    if (target.missingPlayers == 0) {
      return const JoinMatchResult(status: JoinMatchStatus.full);
    }
    if (target.isClosed) {
      return const JoinMatchResult(status: JoinMatchStatus.closed);
    }
    if (target.createdByUserId == userId) {
      return const JoinMatchResult(status: JoinMatchStatus.creatorCannotJoin);
    }
    if (target.joinedPlayerIds.contains(userId)) {
      return JoinMatchResult(status: JoinMatchStatus.alreadyJoined, match: target);
    }

    final Set<String> joined = Set<String>.from(target.joinedPlayerIds)..add(userId);
    final MatchPost updated = target.copyWith(
      missingPlayers: (target.missingPlayers - 1).clamp(0, target.totalPlayers),
      joinedPlayerIds: joined,
    );

    state = state.map((MatchPost match) {
      return match.id == matchId ? updated : match;
    }).toList();

    await _storage.saveMatches(state);
    return JoinMatchResult(status: JoinMatchStatus.joined, match: updated);
  }

  Future<CloseMatchResult> closeMatch(String matchId, String userId) async {
    final MatchPost? target = _findById(matchId);
    if (target == null) {
      return const CloseMatchResult(status: CloseMatchStatus.notFound);
    }
    if (target.createdByUserId != userId) {
      return const CloseMatchResult(status: CloseMatchStatus.notAuthorized);
    }

    state = state.where((MatchPost match) => match.id != matchId).toList();

    await _storage.saveMatches(state);
    return const CloseMatchResult(status: CloseMatchStatus.closed);
  }

  MatchPost? _findById(String id) {
    for (final MatchPost match in state) {
      if (match.id == id) return match;
    }
    return null;
  }
}
