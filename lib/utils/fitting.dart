import 'dart:math';

class PolynomialFitResult {
  final List<double> coefficients;
  final double rSquared;

  const PolynomialFitResult({required this.coefficients, required this.rSquared});

  double evaluate(double x) {
    return coefficients.asMap().entries.fold<double>(0, (sum, entry) {
      return sum + entry.value * pow(x, entry.key);
    });
  }
}

List<double> _solve3x3(List<List<double>> a, List<double> b) {
  final detA = _determinant3x3(a);
  if (detA.abs() < 1e-9) {
    return [0, 0, 0];
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

PolynomialFitResult fitQuadratic(List<Point<double>> points) {
  final n = points.length.toDouble();
  double sx = 0, sx2 = 0, sx3 = 0, sx4 = 0;
  double sy = 0, sxy = 0, sx2y = 0;

  for (final p in points) {
    final x = p.x;
    final y = p.y;
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
    [n, sx, sx2],
    [sx, sx2, sx3],
    [sx2, sx3, sx4],
  ];
  final matrixB = [sy, sxy, sx2y];
  final coeffs = _solve3x3(matrixA, matrixB);

  final meanY = sy / n;
  double ssTot = 0;
  double ssRes = 0;
  for (final p in points) {
    final predicted = coeffs[0] + coeffs[1] * p.x + coeffs[2] * p.x * p.x;
    ssRes += pow(p.y - predicted, 2) as double;
    ssTot += pow(p.y - meanY, 2) as double;
  }
  final r2 = ssTot == 0 ? 1 : 1 - (ssRes / ssTot);

  return PolynomialFitResult(coefficients: coeffs, rSquared: r2);
}

PolynomialFitResult fitLinear(List<Point<double>> points) {
  final n = points.length.toDouble();
  double sx = 0, sy = 0, sxy = 0, sx2 = 0;
  for (final p in points) {
    sx += p.x;
    sy += p.y;
    sxy += p.x * p.y;
    sx2 += p.x * p.x;
  }
  final denominator = (n * sx2) - (sx * sx);
  final slope = denominator == 0 ? 0 : ((n * sxy) - (sx * sy)) / denominator;
  final intercept = n == 0 ? 0 : (sy - slope * sx) / n;

  double meanY = sy / n;
  double ssTot = 0;
  double ssRes = 0;
  for (final p in points) {
    final predicted = intercept + slope * p.x;
    ssRes += pow(p.y - predicted, 2) as double;
    ssTot += pow(p.y - meanY, 2) as double;
  }
  final r2 = ssTot == 0 ? 1 : 1 - (ssRes / ssTot);

  return PolynomialFitResult(coefficients: [intercept, slope], rSquared: r2);
}
