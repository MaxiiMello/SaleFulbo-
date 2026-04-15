import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_post.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((Ref ref) {
  return FirestoreService();
});

/// Stream de todos los matches activos sincronizado en tiempo real
final matchesStreamProvider = StreamProvider<List<MatchPost>>((Ref ref) {
  final FirestoreService firestore = ref.watch(firestoreServiceProvider);
  return firestore.watchMatches();
});

/// Controller para acciones (crear, unirse, cerrar)
final matchesControllerProvider =
    Provider<MatchesController>((Ref ref) {
  return MatchesController(ref.watch(firestoreServiceProvider));
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

class MatchesController {
  MatchesController(this._firestore);

  final FirestoreService _firestore;

  Future<void> addMatch(MatchPost match) async {
    await _firestore.createMatch(match);
  }

  Future<void> adjustMissingPlayers(String matchId, int delta) async {
    await _firestore.adjustMissingPlayers(matchId, delta);
  }

  Future<JoinMatchResult> joinAsPlayer(String matchId, String userId) async {
    try {
      final MatchPost? target = await _firestore.getMatch(matchId);
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

      await _firestore.joinMatch(matchId, userId);
      return JoinMatchResult(status: JoinMatchStatus.joined, match: target);
    } catch (_) {
      return const JoinMatchResult(status: JoinMatchStatus.notFound);
    }
  }

  Future<CloseMatchResult> closeMatch(String matchId, String userId) async {
    try {
      final MatchPost? target = await _firestore.getMatch(matchId);
      if (target == null) {
        return const CloseMatchResult(status: CloseMatchStatus.notFound);
      }
      if (target.createdByUserId != userId) {
        return const CloseMatchResult(status: CloseMatchStatus.notAuthorized);
      }

      await _firestore.closeMatch(matchId);
      return const CloseMatchResult(status: CloseMatchStatus.closed);
    } catch (_) {
      return const CloseMatchResult(status: CloseMatchStatus.notFound);
    }
  }
}

