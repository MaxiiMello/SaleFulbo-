import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio para manejar uploads a Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload de foto de perfil
  /// Retorna la URL de descarga pública
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref('profile_photos/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      await uploadTask;
      
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  /// Upload de foto de partido/evento
  Future<String> uploadMatchPhoto({
    required String matchId,
    required File imageFile,
  }) async {
    try {
      final String fileName = '${matchId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref('match_photos/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      await uploadTask;
      
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading match photo: $e');
    }
  }

  /// Eliminar foto de Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final Reference ref = FirebaseStorage.instance.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      // Log pero no fallar si delete falla
      print('Error deleting photo: $e');
    }
  }
}
