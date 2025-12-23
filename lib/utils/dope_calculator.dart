import 'dart:math';

import '../models/dope_point.dart';
import 'fitting.dart';

class DopeCalculator {
  static double predictElevation(double distance, List<DopePoint> points) {
    if (points.isEmpty) {
      return double.nan;
    }

    final zero = points.where((p) => p.distanceYards == 100).toList();
    final confirmedBeyondZero =
        points.where((p) => p.confirmed && p.distanceYards != 100).toList();
    final fallbackPoints = confirmedBeyondZero.isNotEmpty
        ? [
            ...confirmedBeyondZero,
            if (zero.isNotEmpty) zero.first,
          ]
        : points;

    final sortedPoints = [...fallbackPoints]
      ..sort((a, b) => a.distanceYards.compareTo(b.distanceYards));
    final uniquePoints = _uniquePoints(sortedPoints);
    final match = sortedPoints.firstWhere(
      (p) => (p.distanceYards - distance).abs() < 0.001,
      orElse: () => DopePoint(profileId: -1, distanceYards: -1, elevation: -1),
    );
    if (match.profileId != -1) {
      return match.elevation;
    }

    if (uniquePoints.length >= 3) {
      try {
        final fit = fitQuadratic(
          uniquePoints,
          confirmedOnly: false,
        );
        if (distance >= fit.minDistance && distance <= fit.maxDistance) {
          return fit.evaluate(distance);
        }
      } catch (_) {
        // Fall through to linear interpolation when a quadratic fit is not available.
      }
    }

    if (uniquePoints.length >= 2) {
      final lower = uniquePoints.lastWhere((p) => p.distanceYards < distance,
          orElse: () => uniquePoints.first,);
      final upper = uniquePoints.firstWhere((p) => p.distanceYards > distance,
          orElse: () => uniquePoints.last,);
      if (lower.distanceYards == upper.distanceYards) {
        return lower.elevation;
      }
      final ratio =
          (distance - lower.distanceYards) / (upper.distanceYards - lower.distanceYards);
      return lower.elevation + ratio * (upper.elevation - lower.elevation);
    }

    final base = sortedPoints.first;
    final scale = base.distanceYards == 0 ? 1 : distance / base.distanceYards;
    return base.elevation * scale;
  }

  static double cosineMultiplier(double angleDegrees) {
    final radians = angleDegrees * pi / 180;
    return cos(radians);
  }

  static List<DopePoint> _uniquePoints(List<DopePoint> points) {
    final grouped = <String, List<DopePoint>>{};
    for (final p in points) {
      final key = p.distanceYards.toStringAsFixed(3);
      grouped.putIfAbsent(key, () => []).add(p);
    }

    final averaged = grouped.entries.map((entry) {
      final distance = entry.value.first.distanceYards;
      final totalElevation =
          entry.value.fold<double>(0, (sum, p) => sum + p.elevation);
      final avgElevation = totalElevation / entry.value.length;
      final first = entry.value.first;
      final allConfirmed = entry.value.every((p) => p.confirmed);
      return DopePoint(
        id: first.id,
        profileId: first.profileId,
        distanceYards: distance,
        elevation: avgElevation,
        muzzleVelocity: first.muzzleVelocity,
        temperatureF: first.temperatureF,
        pressureInHg: first.pressureInHg,
        humidityPercent: first.humidityPercent,
        confirmed: allConfirmed,
        source: first.source,
      );
    }).toList();

    averaged.sort((a, b) => a.distanceYards.compareTo(b.distanceYards));
    return averaged;
  }
}