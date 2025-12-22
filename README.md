# Empirical Dope

A KISS empirical ballistic calculator for shooters and hunters. The app learns exclusively from real DOPE points captured in the field and uses polynomial fitting to predict holds without requiring muzzle velocity or environmental data.

## Features
- Create rifle/load profiles with MIL or MOA units.
- Record DOPE points (distance vs. elevation). A 100-yard zero is always included.
- Quadratic least-squares fitting to interpolate/extrapolate elevation for new distances.
- Dope card generation from 100 to 1200 yards.
- Cosine calculator for angled shots.
- Advanced mode to capture muzzle velocity and environmental data per DOPE entry.
- ShotView CSV import (paste/export) for quickly loading muzzle-velocity strings. Use the import sheet's "Load example CSV" to try the bundled `assets/shotview_example.csv`.
- Offline-first with local SQLite storage.

## Development
1. Install Flutter (3.3+ recommended).
2. Run `flutter pub get`.
3. Launch with `flutter run` on your simulator or device.

Data is stored locally using the `sqflite` package. No network access is required.
