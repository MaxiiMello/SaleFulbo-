import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/match_post.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _matchesCollection = 'matches';
  static const String _usersCollection = 'users';

  /// Stream de matches activos (no cerrados y fecha futura)
  Stream<List<MatchPost>> watchMatches() {
    developer.log('🔵 watchMatches: Iniciando stream');
    try {
      final DateTime now = DateTime.now();
      
      return _firestore
          .collection(_matchesCollection)
          .snapshots()
          .map((QuerySnapshot snapshot) {
        developer.log('🟢 watchMatches: ${snapshot.docs.length} docs recibidos');
        
        // Parse todos
        final List<MatchPost> allMatches = snapshot.docs
            .map((QueryDocumentSnapshot doc) {
              return MatchPost.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            })
            .toList();
        
        // Filtrar: NO cerrados Y fecha futura
        final List<MatchPost> activeMatches = allMatches
            .where((MatchPost m) => !m.isClosed && m.scheduledAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        
        developer.log('🟢 watchMatches: ${activeMatches.length} activos de ${allMatches.length} totales');
        return activeMatches;
      });
    } catch (e) {
      developer.log('❌ watchMatches ERROR: $e', error: e);
      return Stream.value(<MatchPost>[]);
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

  /// Obtener historial de partidos jugados por un usuario
  Future<List<MatchPost>> getUserPlayedMatches(String userId) async {
    try {
      developer.log('getUserPlayedMatches: Buscando partidos jugados por $userId');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_matchesCollection)
          .get();

      final List<MatchPost> allMatches = snapshot.docs
          .map((QueryDocumentSnapshot doc) {
            return MatchPost.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            });
          })
          .toList();

      // Filtrar: partidos cerrados donde el usuario está en joinedPlayerIds
      final List<MatchPost> playedMatches = allMatches
          .where((MatchPost m) => 
              m.isClosed && 
              m.joinedPlayerIds.contains(userId) &&
              m.scheduledAt.isBefore(DateTime.now()))
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      developer.log('getUserPlayedMatches: ${playedMatches.length} partidos encontrados');
      return playedMatches;
    } catch (e) {
      developer.log('getUserPlayedMatches ERROR: $e', error: e);
      return <MatchPost>[];
    }
  }

  /// Obtener historial de partidos organizados por un usuario
  Future<List<MatchPost>> getUserOrganizedMatches(String userId) async {
    try {
      developer.log('getUserOrganizedMatches: Buscando partidos organizados por $userId');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_matchesCollection)
          .get();

      final List<MatchPost> allMatches = snapshot.docs
          .map((QueryDocumentSnapshot doc) {
            return MatchPost.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            });
          })
          .toList();

      // Filtrar: partidos organizados por el usuario (createdByUserId == userId)
      final List<MatchPost> organizedMatches = allMatches
          .where((MatchPost m) => 
              m.createdByUserId == userId &&
              (m.isClosed || m.scheduledAt.isBefore(DateTime.now())))
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      developer.log('getUserOrganizedMatches: ${organizedMatches.length} partidos encontrados');
      return organizedMatches;
    } catch (e) {
      developer.log('getUserOrganizedMatches ERROR: $e', error: e);
      return <MatchPost>[];
    }
  }

  /// Guardar o actualizar perfil de usuario en Firestore
  Future<void> updateUserProfile(AppUser user) async {
    try {
      developer.log('updateUserProfile: Guardando perfil de ${user.id}');
      
      await _firestore.collection(_usersCollection).doc(user.id).set({
        'id': user.id,
        'displayName': user.displayName,
        'email': user.email,
        'nickname': user.nickname ?? '',
        'photoUrl': user.photoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      developer.log('updateUserProfile: Perfil guardado exitosamente');
    } catch (e) {
      developer.log('updateUserProfile ERROR: $e', error: e);
      rethrow;
    }
  }

  /// Cargar perfil de usuario desde Firestore
  Future<AppUser?> loadUserProfile(String userId) async {
    try {
      developer.log('loadUserProfile: Cargando perfil de $userId');
      
      final DocumentSnapshot doc = 
          await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (!doc.exists) {
        developer.log('loadUserProfile: Perfil no encontrado para $userId');
        return null;
      }
      
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      final AppUser user = AppUser(
        id: data['id'] as String,
        displayName: data['displayName'] as String? ?? 'Jugador',
        email: data['email'] as String? ?? '',
        nickname: data['nickname'] as String?,
        photoUrl: data['photoUrl'] as String?,
      );
      
      developer.log('loadUserProfile: Perfil cargado exitosamente para $userId');
      return user;
    } catch (e) {
      developer.log('loadUserProfile ERROR: $e', error: e);
      return null;
    }
  }
}
