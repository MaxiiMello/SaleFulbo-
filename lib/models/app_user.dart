class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.nickname,
    this.photoUrl,
  });

  final String id;
  final String displayName;
  final String email;
  final String? nickname;
  final String? photoUrl;

  /// Crear copia con cambios opcionales
  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? nickname,
    String? photoUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'nickname': nickname,
      'photoUrl': photoUrl,
    };
  }

  /// Crear desde Map de Firestore
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      nickname: map['nickname'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
