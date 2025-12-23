# Changelog

All notable changes to the Empirical Dope application.

## [v4.2] - 2025-12-23

### Fixed
- **File encoding error** - Fixed "Failed to decode data using encoding 'utf-8'" error
  - Added multi-encoding support (UTF-8, Latin-1, ASCII)
  - Handles files with special characters and different encodings
  - Gracefully falls back through encoding options
  - Works with files exported from Windows, Mac, and various apps

### Technical
- Read files as bytes first, then decode with proper encoding
- Try UTF-8 with malformed character handling
- Fall back to Latin-1 (Windows-1252) for legacy files
- Last resort: ASCII with non-ASCII character replacement

**APK Details:**
- Size: 21.4 MB
- SHA256: `bbc301b5b24ef9a6610ab8827acbc91c8f06821fb9b7c2099d60d4c1181187ac`

---

## [v4.1] - 2025-12-23

### Fixed
- **File picker reading error** - Fixed "Unable to load asset" error when browsing for CSV files
  - Changed from `rootBundle.loadString()` to `File.readAsString()`
  - Now correctly reads files from device storage
  - Works with Downloads, Documents, and cloud storage

**APK Details:**
- Size: 21.4 MB
- SHA256: `f33064fdb8c579dbb88a5d15607338fce0ed453b416dd649572eefaa90c2eb98`

---

## [v4] - 2025-12-23

### Added
- **Flexible CSV parsing** - Handles real-world CSV formats with varying structures
  - Auto-detects header row position
  - Skips metadata and summary rows
  - Handles BOM characters and special formatting
  - Works with files that have title rows, empty lines, and extra columns
- **Automatic format detection** - No need to select CSV source type
  - Tries ballistics format first (GeoBallistics, AB Quantum)
  - Falls back to velocity format (ShotView) if needed
  - Shows clear feedback on import results

### Changed
- **Removed source dropdown** - Import now auto-detects format
- **Simplified import UI** - Cleaner interface with popup menu for examples
- **Better error messages** - Shows "No data imported" if format not recognized
- **Enhanced column matching** - More flexible column name detection
  - "Range (yd)" / "Distance" / "Range [Y]"
  - "Elev. (MRAD)" / "Elevation [MRAD]" / "Drop"
  - "Speed (FPS)" / "Velocity [FPS]" / "Vel. (ft/s)"

### Fixed
- CSV files with title rows before headers now import correctly
- Files with metadata rows (position, wind, etc.) are handled properly
- Summary rows (AVERAGE, STD DEV) are skipped automatically
- BOM characters no longer cause parsing issues
- Direction indicators (U, L, R) are properly stripped from values

### Technical
- Enhanced `importShotViewCsv()` with header detection
- Enhanced `importBallisticsCsv()` with flexible parsing
- Added BOM removal to `_splitCsvLine()`
- Improved number parsing with validation

**APK Details:**
- Size: 21.3 MB
- SHA256: `e4e8208fc78e4dd816f28b8831e445f68807d3a7be017f2e2d937df81f753b03`

---

## [v3] - 2025-12-23

### Added
- **File browser for CSV imports** - Users can now browse and select CSV files from device storage
  - Added "Browse file" button in CSV import dialog
  - Supports CSV and TXT file types
  - Works with local storage, Downloads, and cloud storage providers
  - Maintains backward compatibility with paste method
- Added `file_picker: ^8.1.4` dependency

### Changed
- Updated CSV import UI with three options: Browse file, Load example, Clear
- Changed text field hint from "Paste CSV contents" to "CSV contents"
- Updated README.md to highlight file browsing capability

### Technical
- Added `_pickCsvFile()` method in ProfileDetailScreen
- Implemented dual file reading strategy (bytes and path-based)
- Updated Android SDK compile version to 35

**APK Details:**
- Size: 21.3 MB
- SHA256: `56ba335b3700624c497fbaf319ffa2ae916282754ef373300dea6c177526413e`

---

## [v2] - 2025-12-23

### Fixed
- **Database initialization crash** - Fixed "Queries can be performed using SQLiteDatabase query or rawQuery methods only" error
  - Removed explicit `PRAGMA journal_mode = WAL` statement
  - Added `singleInstance: true` parameter
  - Relies on sqflite's built-in WAL mode support

### Technical
- Modified `_initDatabase()` in db.dart
- Kept `PRAGMA foreign_keys = ON` (safe and necessary)

**APK Details:**
- Size: 21.2 MB
- SHA256: `28fa55f5a5ad42b996c12ef8984fae332abe593e4e056c69ad3eac12306fe242`

---

## [v1] - 2025-12-23

### Initial Release

#### Features
- Create rifle/load profiles with MIL or MOA units
- Record DOPE points (distance vs. elevation)
- Automatic 100-yard zero point
- Quadratic least-squares fitting for elevation prediction
- Linear interpolation fallback
- Dope card generation (100-1200 yards)
- Cosine calculator for angled shots
- Advanced mode with environmental data
  - Muzzle velocity
  - Temperature
  - Barometric pressure
  - Humidity
- CSV imports
  - Garmin ShotView format
  - GeoBallistics format
  - Applied Ballistics (AB Quantum) format
  - Paste CSV text method
  - Load example CSV files
- Offline-first architecture
- Local SQLite storage
- Profile and DOPE point management
- Delete confirmations for safety
- Confirmed vs unconfirmed data tracking

#### Technical
- Flutter 3.24.5
- Dart 3.5.4
- SQLite database with foreign keys
- Transaction-safe operations
- Database migrations support
- Provider state management
- Material Design 3

#### Audit Results
- ✅ No security vulnerabilities
- ✅ Proper error handling
- ✅ Transaction safety
- ✅ Foreign key constraints
- ✅ Data validation
- ✅ Production ready

**Initial APK:**
- Size: 21.2 MB
- SHA256: `f14a5febbf1af711be1b593b770f934b57eab5eb8a923644a37fa3c7a8e4e180`

---

## Development Setup

### Added in Audit
- Enhanced .gitignore with comprehensive patterns
- Created analysis_options.yaml for code quality
- Configured dev container with Flutter SDK
- Added .gitattributes for line ending normalization
- Created comprehensive documentation
  - AUDIT_SUMMARY.md
  - FIXES.md
  - SAMPLE_DATA.md
  - INSTALL_APK.md
  - BUGFIX_WAL_MODE.md
  - FEATURE_FILE_PICKER.md

### Database
- Version 5 (current)
- Added index on profile_id for performance
- Proper migration paths from v1-v4

---

## Known Issues

None currently reported.

---

## Upgrade Notes

### v2 → v3
- No data migration required
- File picker permissions may be requested on first use
- All existing features remain unchanged

### v1 → v2
- Database automatically migrates to v5
- No user action required
- All data preserved

---

## Future Roadmap

Potential features for consideration:
- Multiple file selection for batch imports
- Export profiles to CSV
- Backup/restore functionality
- Wind drift calculations
- Spin drift compensation
- Coriolis effect calculations
- Ballistic coefficient tracking
- Velocity decay modeling
- Shot logging and statistics
- Dark/light theme toggle
- Imperial/metric unit conversion

---

## Support

For issues, questions, or feature requests:
- Review documentation in the repository
- Check INSTALL_APK.md for installation help
- See FEATURE_FILE_PICKER.md for file import details
- Consult BUGFIX_WAL_MODE.md for database issues

---

## License

See LICENSE file for details.

---

## Credits

**Developer:** Garrett Booth  
**Project:** MatchBallistics / Empirical Dope  
**Audit & Enhancements:** Ona (AI Assistant)
