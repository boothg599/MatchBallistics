class DopePoint {
  final int? id;
  final int profileId;
  final double distanceYards;
  final double elevation;
  final double? muzzleVelocity;
  final double? temperatureF;
  final double? pressureInHg;
  final double? humidityPercent;
  final bool confirmed;
  final String? source;

  DopePoint({
    this.id,
    required this.profileId,
    required this.distanceYards,
    required this.elevation,
    this.muzzleVelocity,
    this.temperatureF,
    this.pressureInHg,
    this.humidityPercent,
    this.confirmed = true,
    this.source,
  });

  DopePoint copyWith({
    int? id,
    int? profileId,
    double? distanceYards,
    double? elevation,
    double? muzzleVelocity,
    double? temperatureF,
    double? pressureInHg,
    double? humidityPercent,
    bool? confirmed,
    String? source,
  }) {
    return DopePoint(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      distanceYards: distanceYards ?? this.distanceYards,
      elevation: elevation ?? this.elevation,
      muzzleVelocity: muzzleVelocity ?? this.muzzleVelocity,
      temperatureF: temperatureF ?? this.temperatureF,
      pressureInHg: pressureInHg ?? this.pressureInHg,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      confirmed: confirmed ?? this.confirmed,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'distance_yards': distanceYards,
      'elevation': elevation,
      'muzzle_velocity': muzzleVelocity,
      'temperature_f': temperatureF,
      'pressure_inhg': pressureInHg,
      'humidity_percent': humidityPercent,
      'confirmed': confirmed ? 1 : 0,
      'source': source,
    };
  }

  factory DopePoint.fromMap(Map<String, dynamic> map) {
    return DopePoint(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      distanceYards: (map['distance_yards'] as num).toDouble(),
      elevation: (map['elevation'] as num).toDouble(),
      muzzleVelocity: (map['muzzle_velocity'] as num?)?.toDouble(),
      temperatureF: (map['temperature_f'] as num?)?.toDouble(),
      pressureInHg: (map['pressure_inhg'] as num?)?.toDouble(),
      humidityPercent: (map['humidity_percent'] as num?)?.toDouble(),
      confirmed: (map['confirmed'] as int? ?? 1) == 1,
      source: map['source'] as String?,
    );
  }
}
