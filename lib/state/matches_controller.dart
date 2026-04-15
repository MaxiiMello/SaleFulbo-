import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_post.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((Ref ref) {
  return FirestoreService();
});

final matchesStreamProvider = StreamProvider<List<MatchPost>>((Ref ref) {
  final FirestoreService firestore = ref.watch(firestoreServiceProvider);
  return firestore.watchMatches();
});

final matchesControllerProvider =
    StateNotifierProvider<MatchesController, AsyncValue<List<MatchPost>>>((Ref ref) {
  return MatchesController(ref.watch(firestoreServiceProvider))..init();
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

class MatchesController extends StateNotifier<AsyncValue<List<MatchPost>>> {
  MatchesController(this._firestore)
      : super(const AsyncValue.loading());

  final FirestoreService _firestore;
  List<MatchPost> _cachedMatches = <MatchPost>[];

  Future<void> init() async {
    _firestore.watchMatches().listen(
      (List<MatchPost> matches) {
        _cachedMatches = matches;
        state = AsyncValue.data(matches);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<void> addMatch(MatchPost match) async {
    try {
      await _firestore.createMatch(match);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> adjustMissingPlayers(String matchId, int delta) async {
    try {
      await _firestore.adjustMissingPlayers(matchId, delta);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
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

    try {
      await _firestore.joinMatch(matchId, userId);
      return JoinMatchResult(status: JoinMatchStatus.joined, match: target);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<CloseMatchResult> closeMatch(String matchId, String userId) async {
    final MatchPost? target = _findById(matchId);
    if (target == null) {
      return const CloseMatchResult(status: CloseMatchStatus.notFound);
    }
    if (target.createdByUserId != userId) {
      return const CloseMatchResult(status: CloseMatchStatus.notAuthorized);
    }

    try {
      await _firestore.closeMatch(matchId);
      return const CloseMatchResult(status: CloseMatchStatus.closed);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  MatchPost? _findById(String id) {
    for (final MatchPost match in _cachedMatches) {
      if (match.id == id) return match;
    }
    return null;
  }
}

