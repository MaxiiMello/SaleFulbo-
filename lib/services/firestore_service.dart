import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_post.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _matchesCollection = 'matches';

  /// Stream de todos los matches activos (no cerrados)
  Stream<List<MatchPost>> watchMatches() {
    developer.log('watchMatches: Iniciando stream de Firestore');
    try {
      return _firestore
          .collection(_matchesCollection)
          .where('isClosed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((QuerySnapshot snapshot) {
        developer.log('watchMatches: Recibidos ${snapshot.docs.length} matches');
        return snapshot.docs
            .map((QueryDocumentSnapshot doc) {
              return MatchPost.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            })
            .toList();
      });
    } catch (e) {
      developer.log('watchMatches ERROR: $e', error: e);
      rethrow;
    }
  }

  /// Crear un nuevo match
  Future<MatchPost> createMatch(MatchPost match) async {
    try {
      developer.log('createMatch: Creando partido ${match.title}');
      final DocumentReference ref =
          await _firestore.collection(_matchesCollection).add(match.toMap());
      developer.log('createMatch: Partido creado con ID ${ref.id}');
      return match.copyWith(id: ref.id);
    } catch (e) {
      developer.log('createMatch ERROR: $e', error: e);
      rethrow;
    }
  }

  /// Unirse a un match como jugador
  Future<void> joinMatch(String matchId, String userId) async {
    try {
      developer.log('joinMatch: Usuario $userId uniéndose a $matchId');
      final DocumentReference docRef =
          _firestore.collection(_matchesCollection).doc(matchId);

      await docRef.update({
        'joinedPlayerIds': FieldValue.arrayUnion(<String>[userId]),
        'missingPlayers': FieldValue.increment(-1),
      });
      developer.log('joinMatch: Éxito');
    } catch (e) {
      developer.log('joinMatch ERROR: $e', error: e);
      rethrow;
    }
  }

  /// Ajustar jugadores faltantes
  Future<void> adjustMissingPlayers(String matchId, int delta) async {
    try {
      developer.log('adjustMissingPlayers: $matchId delta=$delta');
      await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .update({'missingPlayers': FieldValue.increment(delta)});
      developer.log('adjustMissingPlayers: Éxito');
    } catch (e) {
      developer.log('adjustMissingPlayers ERROR: $e', error: e);
      rethrow;
    }
  }

  /// Cerrar un match
  Future<void> closeMatch(String matchId) async {
    try {
      developer.log('closeMatch: Cerrando $matchId');
      await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .update({'isClosed': true});
      developer.log('closeMatch: Éxito');
    } catch (e) {
      developer.log('closeMatch ERROR: $e', error: e);
      rethrow;
    }
  }

  /// Obtener un match específico
  Future<MatchPost?> getMatch(String matchId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_matchesCollection).doc(matchId).get();

      if (!doc.exists) return null;

      return MatchPost.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      developer.log('getMatch ERROR: $e', error: e);
      return null;
    }
  }
}
