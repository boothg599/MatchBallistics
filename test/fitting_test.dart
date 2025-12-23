import 'package:test/test.dart';

import 'package:empirical_dope/models/dope_point.dart';
import 'package:empirical_dope/utils/fitting.dart';

void main() {
  group('fitQuadratic', () {
    test('succeeds with exactly 3 confirmed points', () {
      final points = [
        DopePoint(profileId: 1, distanceYards: 0, elevation: 1),
        DopePoint(profileId: 1, distanceYards: 1, elevation: 2),
        DopePoint(profileId: 1, distanceYards: 2, elevation: 5),
      ];

      final result = fitQuadratic(points);

      expect(result.pointCount, 3);
      expect(result.coefficients.length, 3);
      expect(result.rmse, closeTo(0, 1e-9));
      expect(result.evaluate(3), closeTo(10, 1e-6));
    });

    test('excludes unconfirmed points from fit', () {
      final confirmed = [
        DopePoint(profileId: 1, distanceYards: 0, elevation: 0),
        DopePoint(profileId: 1, distanceYards: 1, elevation: 1),
        DopePoint(profileId: 1, distanceYards: 2, elevation: 4),
      ];
      final noisy = DopePoint(
        profileId: 1,
        distanceYards: 1,
        elevation: 100,
        confirmed: false,
      );

      final result = fitQuadratic([...confirmed, noisy]);

      expect(result.pointCount, 3);
      expect(result.evaluate(3), closeTo(9, 1e-6));
    });

    test('fails with fewer than 3 confirmed points', () {
      final points = [
        DopePoint(profileId: 1, distanceYards: 0, elevation: 0),
        DopePoint(profileId: 1, distanceYards: 1, elevation: 1),
        DopePoint(
          profileId: 1,
          distanceYards: 2,
          elevation: 4,
          confirmed: false,
        ),
      ];

      expect(() => fitQuadratic(points), throwsStateError);
    });
  });
}
