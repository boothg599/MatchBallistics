import 'package:flutter/material.dart';

import '../models/dope_point.dart';
import '../models/profile.dart';
import '../utils/dope_calculator.dart';
import 'db.dart';

class ImportResult {
  ImportResult({required this.added, this.skipped = 0, this.detectedUnit});

  final int added;
  final int skipped;
  final ElevationUnit? detectedUnit;
}

class ProfileProvider extends ChangeNotifier {
  final _db = AppDatabase.instance;
  List<Profile> _profiles = [];
  bool _isLoading = false;
  String? _error;

  List<Profile> get profiles => _profiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Profile? getProfileById(int id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProfiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profiles = await _db.fetchProfiles();
    } catch (e) {
      _error = 'Failed to load profiles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addProfile(String name, ElevationUnit unit, {bool advanced = false}) async {
    final profile = Profile(
      id: null,
      name: name,
      unit: unit,
      dopePoints: [],
      advancedMode: advanced,
    );
    final id = await _db.insertProfile(profile);
    final basePoint = DopePoint(
      profileId: id,
      distanceYards: 100,
      elevation: 0,
      confirmed: true,
      source: 'Zero',
    );
    final newProfile = profile.copyWith(id: id, dopePoints: [basePoint]);
    _profiles = [..._profiles, newProfile];
    notifyListeners();
    return id;
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
    bool confirmed = true,
    String? source,
  }) async {
    if (distance <= 0) {
      throw ArgumentError('Distance must be positive');
    }
    final profile = getProfileById(profileId);
    if (profile != null) {
      final exists = profile.dopePoints.any((p) => (p.distanceYards - distance).abs() < 0.001);
      if (exists) {
        throw ArgumentError('A DOPE entry for this distance already exists');
      }
    }

    final newPoint = DopePoint(
      profileId: profileId,
      distanceYards: distance,
      elevation: elevation,
      muzzleVelocity: muzzleVelocity,
      temperatureF: temperatureF,
      pressureInHg: pressureInHg,
      humidityPercent: humidityPercent,
      confirmed: confirmed,
      source: source,
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

  Future<void> confirmDopePoint(int profileId, DopePoint point) async {
    final updated = point.copyWith(confirmed: true);
    await _db.updateDopePoint(updated);
    _profiles = _profiles.map((p) {
      if (p.id == profileId) {
        final updatedPoints = p.dopePoints.map((dp) => dp.id == point.id ? updated : dp).toList();
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

  Future<ImportResult> importShotViewCsv({
    required int profileId,
    required String csvText,
    double? defaultDistance,
    double? defaultElevation,
    bool markAsConfirmed = true,
    String sourceLabel = 'ShotView CSV',
  }) async {
    final trimmed = csvText.trim();
    if (trimmed.isEmpty) return ImportResult(added: 0);
    final lines = trimmed.split('\n');
    if (lines.length <= 1) return ImportResult(added: 0);

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

    final existingDistances = <double>{
      ...?getProfileById(profileId)?.dopePoints.map((p) => p.distanceYards),
    };

    int added = 0;
    int skipped = 0;
    for (int i = 1; i < lines.length; i++) {
      final row = lines[i].trim();
      if (row.isEmpty) continue;
      final cols = _splitCsvLine(row);
      double? parseAt(int idx) {
        if (idx < 0 || idx >= cols.length) return null;
        final cleaned = cols[idx].replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleaned);
      }

      final distance = parseAt(idxDistance) ?? defaultDistance;
      final elevation = parseAt(idxElevation) ?? defaultElevation;
      if (distance == null || elevation == null || distance <= 0) {
        skipped++;
        continue;
      }
      final alreadyPresent = existingDistances.any((d) => (d - distance).abs() < 0.001);
      if (alreadyPresent) {
        skipped++;
        continue;
      }

      existingDistances.add(distance);
      final mv = parseAt(idxMv);
      final temp = parseAt(idxTemp);
      final pressure = parseAt(idxPressure);
      final humidity = parseAt(idxHumidity);

      try {
        await addDopePoint(
          profileId,
          distance,
          elevation,
          muzzleVelocity: mv,
          temperatureF: temp,
          pressureInHg: pressure,
          humidityPercent: humidity,
          confirmed: markAsConfirmed,
          source: sourceLabel,
        );
        added++;
      } catch (_) {
        skipped++;
      }
    }
    return ImportResult(added: added, skipped: skipped);
  }

  Future<ImportResult> importBallisticsCsv({
    required int profileId,
    required String csvText,
    required ElevationUnit fallbackUnit,
    String sourceLabel = 'External CSV',
    bool markAsConfirmed = false,
  }) async {
    final trimmed = csvText.trim();
    if (trimmed.isEmpty) return ImportResult(added: 0);
    final lines = trimmed.split('\n');
    if (lines.length <= 1) return ImportResult(added: 0);

    final header = _splitCsvLine(lines.first.toLowerCase());

    int indexOf(List<String> names) {
      return header.indexWhere((h) => names.any((n) => h.contains(n)));
    }

    final idxDistance = indexOf(['distance', 'range', 'yard', 'yd']);
    final idxElevation = indexOf(['drop', 'dope', 'elevation', 'adj']);

    ElevationUnit? detectedUnit;
    if (header.any((h) => h.contains('moa'))) {
      detectedUnit = ElevationUnit.moa;
    } else if (header.any((h) => h.contains('mil') || h.contains('mrad'))) {
      detectedUnit = ElevationUnit.mil;
    }

    final existingDistances = <double>{
      ...?getProfileById(profileId)?.dopePoints.map((p) => p.distanceYards),
    };

    int added = 0;
    int skipped = 0;
    for (int i = 1; i < lines.length; i++) {
      final row = lines[i].trim();
      if (row.isEmpty) continue;
      final cols = _splitCsvLine(row);

      double? parseAt(int idx) {
        if (idx < 0 || idx >= cols.length) return null;
        final cleaned = cols[idx].replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleaned);
      }

      final distance = parseAt(idxDistance);
      final elevation = parseAt(idxElevation);
      if (distance == null || elevation == null) {
        skipped++;
        continue;
      }

      // Skip the built-in 100 yard zero and any duplicate range entries to avoid
      // cluttering imported profiles with redundant rows.
      if ((distance - 100).abs() < 0.001 && elevation.abs() < 0.001) {
        skipped++;
        continue;
      }
      final alreadyPresent = existingDistances.any((d) => (d - distance).abs() < 0.001);
      if (alreadyPresent) {
        skipped++;
        continue;
      }

      existingDistances.add(distance);

      try {
        await addDopePoint(
          profileId,
          distance,
          elevation,
          confirmed: markAsConfirmed,
          source: sourceLabel,
        );
        added++;
      } catch (_) {
        skipped++;
      }
    }

    // Update profile unit if the CSV clearly indicated another unit.
    final profile = getProfileById(profileId);
    if (profile != null && detectedUnit != null && detectedUnit != profile.unit) {
      final updated = profile.copyWith(unit: detectedUnit);
      await updateProfile(updated);
    }

    return ImportResult(added: added, skipped: skipped, detectedUnit: detectedUnit ?? fallbackUnit);
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