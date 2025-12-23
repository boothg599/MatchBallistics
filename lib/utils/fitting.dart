import 'dart:math';

import '../models/dope_point.dart';

class FitResult {
  final List<double> coefficients; // [a, b, c] for ax^2 + bx + c
  final double rmse;
  final int pointCount;
  final double minDistance;
  final double maxDistance;

  const FitResult({
    required this.coefficients,
    required this.rmse,
    required this.pointCount,
    required this.minDistance,
    required this.maxDistance,
  });

  double evaluate(double x) {
    final a = coefficients[0];
    final b = coefficients[1];
    final c = coefficients[2];
    return a * x * x + b * x + c;
  }
}

List<double>? _solve3x3(List<List<double>> a, List<double> b) {
  final detA = _determinant3x3(a);
  if (detA.abs() < 1e-9) {
    return null;
  }
  final d1 = _determinant3x3([b, a[1], a[2]]);
  final d2 = _determinant3x3([a[0], b, a[2]]);
  final d3 = _determinant3x3([a[0], a[1], b]);
  return [d1 / detA, d2 / detA, d3 / detA];
}

double _determinant3x3(List<List<double>> m) {
  return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
      m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
      m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
}

FitResult fitQuadratic(
  List<DopePoint> points, {
  bool confirmedOnly = true,
}) {
  final filteredPoints = confirmedOnly
      ? points.where((p) => p.confirmed).toList()
      : List<DopePoint>.from(points);

  if (filteredPoints.length < 3) {
    throw StateError('Need at least 3 confirmed points to fit quadratic');
  }

  final distances = filteredPoints.map((p) => p.distanceYards).toList();

  double sx = 0, sx2 = 0, sx3 = 0, sx4 = 0;
  double sy = 0, sxy = 0, sx2y = 0;

  for (final p in filteredPoints) {
    final x = p.distanceYards;
    final y = p.elevation;
    final x2 = x * x;
    sx += x;
    sx2 += x2;
    sx3 += x2 * x;
    sx4 += x2 * x2;
    sy += y;
    sxy += x * y;
    sx2y += x2 * y;
  }

  final matrixA = [
    [sx4, sx3, sx2],
    [sx3, sx2, sx],
    [sx2, sx, filteredPoints.length.toDouble()],
  ];
  final matrixB = [sx2y, sxy, sy];
  final coeffs = _solve3x3(matrixA, matrixB);

  if (coeffs == null) {
    throw StateError('Unable to fit quadratic to provided points');
  }

  final n = filteredPoints.length.toDouble();
  double ssRes = 0;
  for (final p in filteredPoints) {
    final predicted = coeffs[0] * p.distanceYards * p.distanceYards +
        coeffs[1] * p.distanceYards +
        coeffs[2];
    ssRes += pow(p.elevation - predicted, 2) as double;
  }

  final rmse = sqrt(ssRes / n);

  return FitResult(
    coefficients: coeffs,
    rmse: rmse,
    pointCount: filteredPoints.length,
    minDistance: distances.reduce(min),
    maxDistance: distances.reduce(max),
  );
}