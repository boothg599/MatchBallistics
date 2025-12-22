import 'package:flutter/material.dart';

import '../models/dope_point.dart';
import '../models/profile.dart';
import '../utils/dope_calculator.dart';
import 'db.dart';

class ProfileProvider extends ChangeNotifier {
  final _db = AppDatabase.instance;
  List<Profile> _profiles = [];
  bool _isLoading = false;

  List<Profile> get profiles => _profiles;
  bool get isLoading => _isLoading;

  Profile? getProfileById(int id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();
    _profiles = await _db.fetchProfiles();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProfile(String name, ElevationUnit unit, {bool advanced = false}) async {
    final profile = Profile(
      id: null,
      name: name,
      unit: unit,
      dopePoints: [],
      advancedMode: advanced,
    );
    final id = await _db.insertProfile(profile);
    final basePoint = DopePoint(profileId: id, distanceYards: 100, elevation: 0);
    final newProfile = profile.copyWith(id: id, dopePoints: [basePoint]);
    _profiles = [..._profiles, newProfile];
    notifyListeners();
  }

  Future<void> updateProfile(Profile profile) async {
    await _db.updateProfile(profile);
    _profiles = _profiles.map((p) => p.id == profile.id ? profile : p).toList();
    notifyListeners();
  }

  Future<void> deleteProfile(int id) async {
    await _db.deleteProfile(id);
    _profiles.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> addDopePoint(
    int profileId,
    double distance,
    double elevation, {
    double? muzzleVelocity,
    double? temperatureF,
    double? pressureInHg,
    double? humidityPercent,
  }) async {
    final newPoint = DopePoint(
      profileId: profileId,
      distanceYards: distance,
      elevation: elevation,
      muzzleVelocity: muzzleVelocity,
      temperatureF: temperatureF,
      pressureInHg: pressureInHg,
      humidityPercent: humidityPercent,
    );
    final id = await _db.insertDopePoint(newPoint);
    final pointWithId = newPoint.copyWith(id: id);
    _profiles = _profiles.map((p) {
      if (p.id == profileId) {
        final updatedPoints = [...p.dopePoints, pointWithId]..sort((a, b) => a.distanceYards.compareTo(b.distanceYards));
        return p.copyWith(dopePoints: updatedPoints);
      }
      return p;
    }).toList();
    notifyListeners();
  }

  Future<void> deleteDopePoint(int profileId, int pointId) async {
    await _db.deleteDopePoint(pointId);
    _profiles = _profiles.map((p) {
      if (p.id == profileId) {
        final updatedPoints = p.dopePoints.where((dp) => dp.id != pointId).toList();
        return p.copyWith(dopePoints: updatedPoints);
      }
      return p;
    }).toList();
    notifyListeners();
  }

  double predict(Profile profile, double distance) {
    return DopeCalculator.predictElevation(distance, profile.dopePoints);
  }

  List<Map<String, double>> dopeCard(Profile profile, {double start = 100, double end = 1200, double step = 50}) {
    final entries = <Map<String, double>>[];
    for (double d = start; d <= end; d += step) {
      entries.add({'distance': d, 'elevation': predict(profile, d)});
    }
    return entries;
  }

  Future<void> setAdvancedMode(Profile profile, bool advanced) async {
    final updated = profile.copyWith(advancedMode: advanced);
    await updateProfile(updated);
  }

  Future<int> importShotViewCsv({
    required int profileId,
    required String csvText,
    double? defaultDistance,
    double? defaultElevation,
  }) async {
    final trimmed = csvText.trim();
    if (trimmed.isEmpty) return 0;
    final lines = trimmed.split('\n');
    if (lines.length <= 1) return 0;

    final header = _splitCsvLine(lines.first.toLowerCase());

    int indexOf(List<String> names) {
      return header.indexWhere((h) => names.any((n) => h.contains(n)));
    }

    final idxDistance = indexOf(['distance', 'range']);
    final idxElevation = indexOf(['elevation', 'adj']);
    final idxMv = indexOf(['muzzle', 'velocity', 'mv']);
    final idxTemp = indexOf(['temp']);
    final idxPressure = indexOf(['pressure', 'baro']);
    final idxHumidity = indexOf(['humidity', 'rh']);

    int added = 0;
    for (int i = 1; i < lines.length; i++) {
      final row = lines[i].trim();
      if (row.isEmpty) continue;
      final cols = _splitCsvLine(row);
      double? parseAt(int idx) {
        if (idx < 0 || idx >= cols.length) return null;
        final cleaned = cols[idx].replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleaned);
      }

      final distance = parseAt(idxDistance) ?? defaultDistance ?? 100;
      final elevation = parseAt(idxElevation) ?? defaultElevation ?? 0;
      final mv = parseAt(idxMv);
      final temp = parseAt(idxTemp);
      final pressure = parseAt(idxPressure);
      final humidity = parseAt(idxHumidity);

      await addDopePoint(
        profileId,
        distance,
        elevation,
        muzzleVelocity: mv,
        temperatureF: temp,
        pressureInHg: pressure,
        humidityPercent: humidity,
      );
      added++;
    }
    return added;
  }

  List<String> _splitCsvLine(String line) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        parts.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(ch);
    }
    parts.add(buffer.toString());

    return parts.map((p) => p.trim().replaceAll('"', '')).toList();
  }
}
