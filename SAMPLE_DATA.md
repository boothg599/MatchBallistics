# Sample Data Files

This directory contains sample CSV files for testing import functionality.

## Files in Root Directory

### GeoBallistics-Sample.csv
Sample export from GeoBallistics app showing ballistic drop data.
- Used for testing GeoBallistics CSV import
- Contains distance and elevation data

### Rifle_Bullet_2025-06-01_17-38-59.csv
Sample chronograph data showing muzzle velocity measurements.
- Contains shot-by-shot velocity data
- Used for testing ShotView-style imports

### ab_quantum_export_1766445256.csv
Sample export from Applied Ballistics Quantum calculator.
- Contains ballistic trajectory data with environmental conditions
- Used for testing AB Quantum CSV import

## Files in assets/ Directory

The following files are bundled with the app for demonstration:

- `assets/shotview_mv_series.csv` - Garmin ShotView muzzle velocity series
- `assets/geoballistics_export.csv` - GeoBallistics drop table
- `assets/ab_quantum_export.csv` - Applied Ballistics Quantum export

These can be loaded via the "Load example CSV" buttons in the import interface.

## Usage

These sample files demonstrate the CSV import formats supported by the app. Users can:
1. Import their own CSV files in similar formats
2. Use the bundled examples to understand the expected format
3. Test the import functionality with known-good data
