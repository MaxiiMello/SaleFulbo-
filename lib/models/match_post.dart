enum FootballFormat {
  five,
  seven,
  eleven,
}

enum MatchIntensity {
  tranquilo,
  moderado,
  fuerte,
}

String footballFormatLabel(FootballFormat format) {
  switch (format) {
    case FootballFormat.five:
      return 'Futbol 5';
    case FootballFormat.seven:
      return 'Futbol 7';
    case FootballFormat.eleven:
      return 'Futbol 11';
  }
}

String intensityLabel(MatchIntensity intensity) {
  switch (intensity) {
    case MatchIntensity.tranquilo:
      return 'Tranquilo';
    case MatchIntensity.moderado:
      return 'Moderado';
    case MatchIntensity.fuerte:
      return 'Fuerte';
  }
}

class MatchPost {
  MatchPost({
    required this.id,
    required this.createdByUserId,
    required this.createdByName,
    required this.title,
    required this.courtName,
    required this.totalPlayers,
    required this.missingPlayers,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.isClosed,
    required this.format,
    required this.intensity,
    required this.courtPrice,
    required this.creatorRating,
    required this.playerRating,
    Set<String>? joinedPlayerIds,
  }) : joinedPlayerIds = joinedPlayerIds ?? <String>{};

  final String id;
  final String createdByUserId;
  final String createdByName;
  final String title;
  final String courtName;
  final int totalPlayers;
  final int missingPlayers;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final bool isClosed;
  final FootballFormat format;
  final MatchIntensity intensity;
  final double courtPrice;
  final double creatorRating;
  final double playerRating;
  final Set<String> joinedPlayerIds;

  MatchPost copyWith({
    String? id,
    String? createdByUserId,
    String? createdByName,
    String? title,
    String? courtName,
    int? totalPlayers,
    int? missingPlayers,
    double? latitude,
    double? longitude,
    DateTime? scheduledAt,
    bool? isClosed,
    FootballFormat? format,
    MatchIntensity? intensity,
    double? courtPrice,
    double? creatorRating,
    double? playerRating,
    Set<String>? joinedPlayerIds,
  }) {
    return MatchPost(
      id: id ?? this.id,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      title: title ?? this.title,
      courtName: courtName ?? this.courtName,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      missingPlayers: missingPlayers ?? this.missingPlayers,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isClosed: isClosed ?? this.isClosed,
      format: format ?? this.format,
      intensity: intensity ?? this.intensity,
      courtPrice: courtPrice ?? this.courtPrice,
      creatorRating: creatorRating ?? this.creatorRating,
      playerRating: playerRating ?? this.playerRating,
      joinedPlayerIds: joinedPlayerIds ?? Set<String>.from(this.joinedPlayerIds),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'title': title,
      'courtName': courtName,
      'totalPlayers': totalPlayers,
      'missingPlayers': missingPlayers,
      'latitude': latitude,
      'longitude': longitude,
      'scheduledAt': scheduledAt.toIso8601String(),
      'isClosed': isClosed,
      'format': format.name,
      'intensity': intensity.name,
      'courtPrice': courtPrice,
      'creatorRating': creatorRating,
      'playerRating': playerRating,
      'joinedPlayerIds': joinedPlayerIds.toList(),
    };
  }

  factory MatchPost.fromMap(Map<dynamic, dynamic> map) {
    return MatchPost(
      id: map['id'] as String,
      createdByUserId: map['createdByUserId'] as String? ?? 'legacy-creator',
      createdByName: map['createdByName'] as String? ?? 'Creador',
      title: map['title'] as String,
      courtName: map['courtName'] as String,
      totalPlayers: map['totalPlayers'] as int,
      missingPlayers: map['missingPlayers'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
        scheduledAt:
          DateTime.tryParse(map['scheduledAt'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
        isClosed: map['isClosed'] as bool? ?? false,
      format: FootballFormat.values.firstWhere(
        (FootballFormat v) => v.name == map['format'],
        orElse: () => FootballFormat.five,
      ),
      intensity: MatchIntensity.values.firstWhere(
        (MatchIntensity v) => v.name == map['intensity'],
        orElse: () => MatchIntensity.tranquilo,
      ),
      courtPrice: (map['courtPrice'] as num?)?.toDouble() ?? 0,
      creatorRating: (map['creatorRating'] as num).toDouble(),
      playerRating: (map['playerRating'] as num).toDouble(),
      joinedPlayerIds: Set<String>.from(((map['joinedPlayerIds'] as List<dynamic>?) ?? <dynamic>[]).cast<String>()),
    );
  }
}
