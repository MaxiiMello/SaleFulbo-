import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import './firestore_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = (Firebase.apps.isNotEmpty) ? (firebaseAuth ?? FirebaseAuth.instance) : null,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  AppUser? _demoUser;

  bool get firebaseConfigured => _firebaseAuth != null;

  Stream<AppUser?> authStateChanges() {
    if (_firebaseAuth == null) {
      return Stream<AppUser?>.value(_demoUser);
    }
    
    return _firebaseAuth.authStateChanges().asyncMap<AppUser?>((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      
      // Mapear usuario de Firebase
      final AppUser baseUser = AppUser(
        id: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'Jugador',
        email: firebaseUser.email ?? 'sin-email',
      );
      
      // Intentar cargar perfil completo de Firestore (nickname, photoUrl, etc.)
      try {
        final FirestoreService firestore = FirestoreService();
        final AppUser? firestoreUser = await firestore.loadUserProfile(firebaseUser.uid);
        
        if (firestoreUser != null) {
          // Combinar datos de Firebase con datos de Firestore
          return baseUser.copyWith(
            nickname: firestoreUser.nickname,
            photoUrl: firestoreUser.photoUrl,
          );
        }
      } catch (e) {
        // Si hay error cargando de Firestore, usar datos básicos
        print('Error cargando perfil de Firestore: $e');
      }
      
      return baseUser;
    });
  }

  AppUser? get currentUser => _firebaseAuth == null ? _demoUser : _mapFirebaseUser(_firebaseAuth.currentUser);

  Future<AppUser> signInWithGoogle() async {
    final FirebaseAuth? firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null) {
      throw Exception('Firebase no esta configurado. Usa modo demo o conecta Firebase.');
    }

    if (kIsWeb) {
      final GoogleAuthProvider provider = GoogleAuthProvider();
      provider.setCustomParameters(<String, String>{'prompt': 'select_account'});

      final UserCredential result = await firebaseAuth.signInWithPopup(provider);
      final AppUser? user = _mapFirebaseUser(result.user);
      if (user == null) {
        throw Exception('No se pudo iniciar sesion con Google.');
      }
      return user;
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Inicio de sesion cancelado.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await firebaseAuth.signInWithCredential(credential);
    final AppUser? user = _mapFirebaseUser(result.user);
    if (user == null) {
      throw Exception('No se pudo iniciar sesion con Google.');
    }
    return user;
  }

  Future<AppUser> signInDemo() async {
    _demoUser = const AppUser(
      id: 'demo-user',
      displayName: 'Jugador Demo',
      email: 'demo@salefulbo.local',
    );
    return _demoUser!;
  }

  Future<void> signOut() async {
    final FirebaseAuth? firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null) {
      _demoUser = null;
      return;
    }
    await Future.wait(<Future<void>>[
      firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      displayName: user.displayName ?? 'Jugador',
      email: user.email ?? 'sin-email',
    );
  }
}
