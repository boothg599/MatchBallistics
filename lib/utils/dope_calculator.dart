import 'dart:math';

import '../models/dope_point.dart';
import 'fitting.dart';

class DopeCalculator {
  static double predictElevation(double distance, List<DopePoint> points) {
    if (points.isEmpty) {
      return double.nan;
    }

    final sortedPoints = [...points]..sort((a, b) => a.distanceYards.compareTo(b.distanceYards));
    final match = sortedPoints.firstWhere(
      (p) => (p.distanceYards - distance).abs() < 0.001,
      orElse: () => DopePoint(profileId: -1, distanceYards: -1, elevation: -1),
    );
    if (match.profileId != -1) {
      return match.elevation;
    }

    if (sortedPoints.length >= 3) {
      final fit = fitQuadratic(
        sortedPoints.map((p) => Point<double>(p.distanceYards, p.elevation)).toList(),
      );
      final y = fit.evaluate(distance);
      return y;
    }

    if (sortedPoints.length >= 2) {
      final lower = sortedPoints.lastWhere((p) => p.distanceYards < distance, orElse: () => sortedPoints.first);
      final upper = sortedPoints.firstWhere((p) => p.distanceYards > distance, orElse: () => sortedPoints.last);
      if (lower.distanceYards == upper.distanceYards) {
        return lower.elevation;
      }
      final ratio = (distance - lower.distanceYards) / (upper.distanceYards - lower.distanceYards);
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
}
