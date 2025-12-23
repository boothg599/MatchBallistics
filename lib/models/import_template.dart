enum CsvTemplate { shotView, geoBallistics, abQuantum }

extension CsvTemplateInfo on CsvTemplate {
  String get label {
    switch (this) {
      case CsvTemplate.shotView:
        return 'Garmin ShotView';
      case CsvTemplate.geoBallistics:
        return 'GeoBallistics';
      case CsvTemplate.abQuantum:
        return 'Applied Ballistics (AB Quantum)';
    }
  }

  String get assetPath {
    switch (this) {
      case CsvTemplate.shotView:
        return 'assets/shotview_mv_series.csv';
      case CsvTemplate.geoBallistics:
        return 'assets/geoballistics_export.csv';
      case CsvTemplate.abQuantum:
        return 'assets/ab_quantum_export.csv';
    }
  }

  String get sourceLabel {
    switch (this) {
      case CsvTemplate.shotView:
        return 'ShotView CSV';
      case CsvTemplate.geoBallistics:
        return 'GeoBallistics CSV';
      case CsvTemplate.abQuantum:
        return 'AB Quantum CSV';
    }
  }
}
