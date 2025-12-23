import 'dart:math';

import '../models/dope_point.dart';
import 'fitting.dart';

class DopeCalculator {
  static double predictElevation(double distance, List<DopePoint> points) {
    if (points.isEmpty) {
      return double.nan;
    }

    final zero = points.where((p) => p.distanceYards == 100).toList();
    final confirmedBeyondZero = points.where((p) => p.confirmed && p.distanceYards != 100).toList();
    final fallbackPoints = confirmedBeyondZero.isNotEmpty
        ? [
            ...confirmedBeyondZero,
            if (zero.isNotEmpty) zero.first,
          ]
        : points;

    final sortedPoints = [...fallbackPoints]..sort((a, b) => a.distanceYards.compareTo(b.distanceYards));
    final uniquePoints = _uniquePoints(sortedPoints);
    final match = sortedPoints.firstWhere(
      (p) => (p.distanceYards - distance).abs() < 0.001,
      orElse: () => DopePoint(profileId: -1, distanceYards: -1, elevation: -1),
    );
    if (match.profileId != -1) {
      return match.elevation;
    }

    if (uniquePoints.length >= 3) {
      final fit = fitQuadratic(
        uniquePoints,
      );
      final y = fit.evaluate(distance);
      return y;
    }

    if (uniquePoints.length >= 2) {
      final lower = uniquePoints.lastWhere((p) => p.x < distance, orElse: () => uniquePoints.first);
      final upper = uniquePoints.firstWhere((p) => p.x > distance, orElse: () => uniquePoints.last);
      if (lower.x == upper.x) {
        return lower.y;
      }
      final ratio = (distance - lower.x) / (upper.x - lower.x);
      return lower.y + ratio * (upper.y - lower.y);
    }

    final base = sortedPoints.first;
    final scale = base.distanceYards == 0 ? 1 : distance / base.distanceYards;
    return base.elevation * scale;
  }

  static double cosineMultiplier(double angleDegrees) {
    final radians = angleDegrees * pi / 180;
    return cos(radians);
  }

  static List<Point<double>> _uniquePoints(List<DopePoint> points) {
    final grouped = <String, List<DopePoint>>{};
    for (final p in points) {
      final key = p.distanceYards.toStringAsFixed(3);
      grouped.putIfAbsent(key, () => []).add(p);
    }

    final averaged = grouped.entries.map((entry) {
      final distance = entry.value.first.distanceYards;
      final totalElevation = entry.value.fold<double>(0, (sum, p) => sum + p.elevation);
      final avgElevation = totalElevation / entry.value.length;
      return Point<double>(distance, avgElevation);
    }).toList();

    averaged.sort((a, b) => a.x.compareTo(b.x));
    return averaged;
  }
}
