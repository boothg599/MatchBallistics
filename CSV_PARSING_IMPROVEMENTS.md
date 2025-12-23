# CSV Parsing Improvements

## Overview

Enhanced CSV import parsing to handle flexible formats with varying numbers of rows, columns, metadata, and header positions.

## Problems Solved

### 1. Rigid Header Assumptions
**Before:** Parser assumed the first line was always the header.

**Issue:** Real CSV files often have:
- Title rows before the header
- Metadata rows (position, wind, temperature, etc.)
- Empty lines
- BOM (Byte Order Mark) characters

**After:** Parser now searches for the header row by looking for key column names.

### 2. Summary Row Handling
**Before:** Parser tried to process all rows after the header as data.

**Issue:** Files like ShotView include summary rows:
- AVERAGE SPEED
- STD DEV
- SPREAD
- Date information
- Session notes

**After:** Parser skips rows that start with known summary keywords.

### 3. Metadata Rows
**Before:** Parser failed on files with metadata before the data table.

**Issue:** GeoBallistics exports include:
- Position coordinates
- Shot bearing and angle
- Wind conditions
- Pressure, temperature, humidity
- Density altitude

**After:** Parser skips all rows until it finds the header row.

### 4. Column Detection
**Before:** Limited column name matching.

**Issue:** Different apps use different column names:
- "Range (yd)" vs "Distance" vs "Range [Y]"
- "Elev. (MRAD)" vs "Elevation [MRAD]" vs "Drop"
- "Speed (FPS)" vs "Velocity [FPS]" vs "Vel. (ft/s)"

**After:** Flexible matching with multiple aliases per column type.

## Technical Changes

### ShotView CSV Parser

**Header Detection:**
```dart
// Find header by looking for velocity/speed columns
for (int i = 0; i < lines.length; i++) {
  final cols = _splitCsvLine(lines[i].toLowerCase());
  if (cols.any((c) => c.contains('speed') || c.contains('velocity') || 
                       c.contains('fps') || c.contains('distance'))) {
    headerIdx = i;
    header = cols;
    break;
  }
}
```

**Summary Row Filtering:**
```dart
// Skip summary rows
if (rowLower.startsWith('average') || rowLower.startsWith('std') || 
    rowLower.startsWith('spread') || rowLower.startsWith('date') ||
    rowLower.startsWith('session') || rowLower.startsWith('all shots') ||
    rowLower.startsWith('projectile') || row.startsWith('-')) {
  continue;
}
```

**Column Matching:**
```dart
final idxMv = indexOf(['speed', 'velocity', 'fps']);
```

### Ballistics CSV Parser

**Header Detection:**
```dart
// Find header by looking for range AND elevation columns
for (int i = 0; i < lines.length; i++) {
  final cols = _splitCsvLine(lines[i].toLowerCase());
  final hasRange = cols.any((c) => c.contains('range') || 
                                    c.contains('distance') || 
                                    c.contains('yard'));
  final hasElev = cols.any((c) => c.contains('elev') || 
                                   c.contains('drop') || 
                                   c.contains('dope'));
  if (hasRange && hasElev) {
    headerIdx = i;
    header = cols;
    break;
  }
}
```

**Flexible Column Names:**
```dart
final idxDistance = indexOf(['range', 'distance', 'yard', 'yd']);
final idxElevation = indexOf(['elev', 'drop', 'dope', 'elevation']);
```

### CSV Line Splitter

**BOM Handling:**
```dart
// Remove BOM and other invisible characters
final cleaned = line.replaceAll('\ufeff', '').replaceAll('\u200b', '');
```

## Supported Formats

### 1. ShotView CSV
```csv
﻿Rifle Bullet 108.0 gr
﻿#,Speed (FPS),Δ Avg (FPS),KE (FT-LBS),Power Factor (kgr⋅ft/s),Time,Clean Bore,Cold Bore,Shot Notes
1,2936.9,-2.8,2068.1,317.2,17:41:38,,,
2,2927.8,-11.8,2055.3,316.2,17:42:02,,,
...
AVERAGE SPEED,2939.7,,,,,
STD DEV,12.1,,,,,
```

**Features:**
- Title row before header
- Multiple data columns
- Summary statistics after data
- Metadata rows at end

### 2. GeoBallistics CSV
```csv
﻿(B) 6GT 2963
Position,"40.3°, -97.0°"
Shot Bearing,190.0°
...
Wind,0.0 mph @ 27.9°
Pressure,28.82 in Hg

Range (yd),Elev. (MRAD),Wind (MRAD),Vel. (ft/s),Energy (ft-lb)
100.00,  0.00,  0.00,2771.14,1841.22
200.00,U 0.28,  0.02,2607.32,1629.97
```

**Features:**
- Title and metadata rows
- Empty line separator
- Direction indicators (U, L)
- Multiple decimal places
- Extra spacing

### 3. AB Quantum CSV
```csv
Custom Bullet

Target,Range [Y],Elevation [MRAD],Windage [MRAD],Velocity [FPS],Energy [J],...
1,100,0.0 U,0.1 L,2196,2032,...
2,200,0.6 U,0.2 L,2038,1750,...
```

**Features:**
- Title row
- Empty line
- Many columns (20+)
- Direction indicators
- Target numbers

## Flexibility Features

### Variable Column Count
- Parser doesn't require specific number of columns
- Only needs to find distance and elevation columns
- Additional columns are optional

### Variable Row Count
- No minimum or maximum row count
- Skips empty lines automatically
- Handles files with 1 to 1000+ data rows

### Metadata Tolerance
- Skips any rows before the header
- Skips summary rows after data
- Handles mixed content gracefully

### Format Variations
- Works with or without quotes
- Handles extra whitespace
- Tolerates BOM characters
- Supports various decimal formats

## Error Handling

### Graceful Degradation
```dart
// Skip invalid rows instead of failing
if (distance == null || elevation == null || distance <= 0) {
  skipped++;
  continue;
}
```

### Validation
```dart
// Ensure parsed values are valid numbers
final parsed = double.tryParse(cleaned);
return (parsed != null && parsed.isFinite) ? parsed : null;
```

### Duplicate Detection
```dart
// Skip duplicate distances
final alreadyPresent = existingDistances.any((d) => (d - distance).abs() < 0.001);
if (alreadyPresent) {
  skipped++;
  continue;
}
```

## Testing Scenarios

### Tested Formats
- ✅ ShotView with title and summary rows
- ✅ GeoBallistics with metadata header
- ✅ AB Quantum with empty lines
- ✅ Files with BOM characters
- ✅ Files with extra columns
- ✅ Files with missing optional columns
- ✅ Files with varying row counts

### Edge Cases Handled
- ✅ Empty lines throughout file
- ✅ Lines with only commas
- ✅ Quoted fields with commas
- ✅ Direction indicators (U, L, R)
- ✅ Extra whitespace
- ✅ Mixed case column names
- ✅ Special characters in values

## User Benefits

### More Reliable Imports
- Works with real-world CSV exports
- Doesn't fail on metadata or summary rows
- Handles format variations automatically

### Better Feedback
- Reports number of rows added
- Reports number of rows skipped
- Shows clear error messages

### Flexibility
- No need to manually edit CSV files
- Works with exports from various apps
- Handles future format changes

## Migration Notes

### Backward Compatibility
- ✅ All existing CSV imports still work
- ✅ No changes to database schema
- ✅ No changes to UI
- ✅ No user action required

### Performance
- Minimal performance impact
- Header search is O(n) where n = number of lines
- Typically finds header in first 10 lines

## Future Enhancements

Potential improvements:
- Auto-detect CSV format (ShotView vs Ballistics)
- Support for tab-separated values (TSV)
- Import preview before committing
- Column mapping UI for custom formats
- Batch file import
- Import history and undo

## Version Information

- **Feature:** Flexible CSV Parsing
- **Version:** v4 (pending)
- **Files Modified:** `lib/services/profile_provider.dart`
- **Lines Changed:** ~150 lines

## Related Documentation

- README.md - CSV import feature overview
- FEATURE_FILE_PICKER.md - File browsing capability
- SAMPLE_DATA.md - Sample CSV file descriptions
