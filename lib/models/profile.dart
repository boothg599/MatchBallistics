import 'dope_point.dart';

enum ElevationUnit { mil, moa }

extension ElevationUnitExtension on ElevationUnit {
  String get label => this == ElevationUnit.mil ? 'MIL' : 'MOA';

  String get toggleLabel => this == ElevationUnit.mil ? 'Switch to MOA' : 'Switch to MIL';

  static ElevationUnit fromString(String value) {
    return value.toUpperCase() == 'MOA' ? ElevationUnit.moa : ElevationUnit.mil;
  }

  String toShortString() => label;
}

class Profile {
  final int? id;
  final String name;
  final ElevationUnit unit;
  final List<DopePoint> dopePoints;
  final bool advancedMode;

  Profile({
    this.id,
    required this.name,
    required this.unit,
    required this.dopePoints,
    this.advancedMode = false,
  });

  Profile copyWith({
    int? id,
    String? name,
    ElevationUnit? unit,
    List<DopePoint>? dopePoints,
    bool? advancedMode,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      dopePoints: dopePoints ?? this.dopePoints,
      advancedMode: advancedMode ?? this.advancedMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit.label,
      'advanced': advancedMode ? 1 : 0,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map, List<DopePoint> points) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: ElevationUnitExtension.fromString(map['unit'] as String),
      dopePoints: points,
      advancedMode: (map['advanced'] as int? ?? 0) == 1,
    );
  }
}
