import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_post.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _matchesCollection = 'matches';

  /// Stream de todos los matches activos (no cerrados)
  Stream<List<MatchPost>> watchMatches() {
    return _firestore
        .collection(_matchesCollection)
        .where('isClosed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot doc) {
            return MatchPost.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            });
          })
          .toList();
    });
  }

  /// Crear un nuevo match
  Future<MatchPost> createMatch(MatchPost match) async {
    final DocumentReference ref =
        await _firestore.collection(_matchesCollection).add(match.toMap());
    return match.copyWith(id: ref.id);
  }

  /// Unirse a un match como jugador
  Future<void> joinMatch(String matchId, String userId) async {
    final DocumentReference docRef =
        _firestore.collection(_matchesCollection).doc(matchId);

    await docRef.update({
      'joinedPlayerIds': FieldValue.arrayUnion(<String>[userId]),
      'missingPlayers': FieldValue.increment(-1),
    });
  }

  /// Ajustar jugadores faltantes
  Future<void> adjustMissingPlayers(String matchId, int delta) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({'missingPlayers': FieldValue.increment(delta)});
  }

  /// Cerrar un match
  Future<void> closeMatch(String matchId) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({'isClosed': true});
  }

  /// Obtener un match específico
  Future<MatchPost?> getMatch(String matchId) async {
    final DocumentSnapshot doc =
        await _firestore.collection(_matchesCollection).doc(matchId).get();

    if (!doc.exists) return null;

    return MatchPost.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }
}
