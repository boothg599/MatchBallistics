# Release Notes - Version 4

## Empirical Dope v4 - Smart CSV Import

**Release Date:** December 23, 2025  
**Build:** v4  
**APK SHA256:** `e4e8208fc78e4dd816f28b8831e445f68807d3a7be017f2e2d937df81f753b03`

---

## 🎯 What's New

### Automatic Format Detection
No more guessing which CSV format you have! The app now automatically detects whether your file is:
- **Ballistics data** (GeoBallistics, AB Quantum) - with range and elevation
- **Velocity data** (ShotView) - with muzzle velocity readings

Just browse or paste your CSV and click Import. The app figures out the rest.

### Flexible CSV Parsing
The parser now handles real-world CSV files that include:
- ✅ Title rows before the header
- ✅ Metadata rows (position, wind, temperature, etc.)
- ✅ Empty lines throughout the file
- ✅ Summary rows after data (AVERAGE, STD DEV, etc.)
- ✅ Extra columns you don't need
- ✅ BOM characters and special formatting
- ✅ Direction indicators (U, L, R)

### Simplified User Interface
- **Removed** the confusing "Source" dropdown
- **Added** helpful text explaining what formats are supported
- **Changed** "Load example CSV" to a popup menu
- **Improved** error messages when import fails

---

## 🔧 Technical Improvements

### Smart Header Detection
Instead of assuming the first line is the header, the parser now:
1. Searches through the file for the actual header row
2. Looks for key column names (range, elevation, velocity, etc.)
3. Starts processing data from the row after the header

### Enhanced Column Matching
The parser recognizes many variations of column names:

**Distance/Range:**
- "Range (yd)"
- "Distance"
- "Range [Y]"
- "Yard"

**Elevation:**
- "Elev. (MRAD)"
- "Elevation [MRAD]"
- "Drop"
- "DOPE"

**Velocity:**
- "Speed (FPS)"
- "Velocity [FPS]"
- "Vel. (ft/s)"
- "MV"

### Better Data Validation
- Strips non-numeric characters (U, L, R, etc.)
- Validates numbers are finite (not NaN or Infinity)
- Skips rows that don't have enough data
- Handles quoted fields with commas inside

---

## 📊 Supported CSV Formats

### 1. GeoBallistics Export
```csv
(B) 6GT 2963
Position,"40.3°, -97.0°"
...
Range (yd),Elev. (MRAD),Wind (MRAD),Vel. (ft/s)
100.00,  0.00,  0.00,2771.14
200.00,U 0.28,  0.02,2607.32
```
✅ Handles metadata rows  
✅ Skips empty lines  
✅ Strips direction indicators

### 2. Applied Ballistics Quantum
```csv
Custom Bullet

Target,Range [Y],Elevation [MRAD],Windage [MRAD],...
1,100,0.0 U,0.1 L,...
2,200,0.6 U,0.2 L,...
```
✅ Handles title and empty lines  
✅ Works with 20+ columns  
✅ Strips direction indicators

### 3. Garmin ShotView
```csv
Rifle Bullet 108.0 gr
#,Speed (FPS),Δ Avg (FPS),KE (FT-LBS),...
1,2936.9,-2.8,2068.1,...
...
AVERAGE SPEED,2939.7,,,,,
STD DEV,12.1,,,,,
```
✅ Handles title row  
✅ Skips summary statistics  
✅ Uses default distance/elevation

---

## 🚀 How to Use

### Basic Import (Ballistics Data)
1. Open a profile
2. Tap menu (⋮) → "Import CSV"
3. Tap "Browse file" or paste CSV text
4. Tap "Import"
5. Done! The app detects the format automatically

### Velocity-Only Import (ShotView)
1. Open a profile
2. Tap menu (⋮) → "Import CSV"
3. Enter default distance (e.g., 100 yards)
4. Enter default elevation (e.g., 0.0 MIL)
5. Browse or paste your velocity data
6. Tap "Import"

### Load Example Files
1. Tap the download icon (📥)
2. Select an example format:
   - Garmin ShotView
   - GeoBallistics
   - Applied Ballistics (AB Quantum)
3. Review the format
4. Tap "Import" to try it

---

## 🐛 Bug Fixes

### Fixed: CSV Files with Metadata
**Before:** Failed to import GeoBallistics files with position/wind data  
**After:** Automatically skips metadata and finds the data table

### Fixed: Summary Rows
**Before:** Tried to import "AVERAGE SPEED" as a data point  
**After:** Recognizes and skips summary rows

### Fixed: BOM Characters
**Before:** Files with UTF-8 BOM failed to parse correctly  
**After:** Strips BOM characters before processing

### Fixed: Direction Indicators
**Before:** "U 0.28" parsed as 0 instead of 0.28  
**After:** Strips U, L, R indicators and parses the number

---

## 📈 Import Feedback

### Success Message
```
Imported 15 data points (2 skipped)
```
Shows how many points were added and how many were skipped (duplicates, invalid data, etc.)

### Failure Message
```
No data imported. Check CSV format and try again.
```
Appears in orange if the parser couldn't find any valid data.

---

## 🔄 Upgrade Notes

### From v3 to v4
- ✅ No data migration required
- ✅ All existing profiles and data preserved
- ✅ Import behavior improved but compatible
- ✅ UI simplified but all features remain

### What Changed
- Source dropdown removed (auto-detection instead)
- Default distance/elevation fields always visible
- Example CSV selection moved to popup menu
- Better error messages

### What Stayed the Same
- All existing features work as before
- Database structure unchanged
- Profile management unchanged
- DOPE prediction unchanged

---

## 📱 Installation

### Download
**File:** `build/app/outputs/flutter-apk/app-release.apk`  
**Size:** 21.3 MB  
**SHA256:** `e4e8208fc78e4dd816f28b8831e445f68807d3a7be017f2e2d937df81f753b03`

### Install
1. Download the APK
2. Transfer to your Android device
3. Enable "Install from unknown sources"
4. Tap the APK to install
5. Grant storage permissions when prompted

### Update from Previous Version
If you have v1, v2, or v3 installed:
1. Simply install the new APK
2. Your data will be preserved
3. No additional steps needed

---

## 🧪 Testing Checklist

Before using in the field, verify:
- [ ] Import GeoBallistics CSV
- [ ] Import AB Quantum CSV
- [ ] Import ShotView CSV with defaults
- [ ] Browse and select CSV file
- [ ] Paste CSV text directly
- [ ] Load example CSV files
- [ ] Verify imported data is correct
- [ ] Check that duplicates are skipped
- [ ] Confirm error messages appear for invalid files

---

## 📚 Documentation

### New Documents
- **CSV_PARSING_IMPROVEMENTS.md** - Technical details on parser enhancements
- **RELEASE_NOTES_V4.md** - This file

### Updated Documents
- **CHANGELOG.md** - Version history
- **INSTALL_APK.md** - Installation instructions
- **README.md** - Feature list

### Reference Documents
- **FEATURE_FILE_PICKER.md** - File browser feature (v3)
- **BUGFIX_WAL_MODE.md** - Database fix (v2)
- **AUDIT_SUMMARY.md** - Initial audit results

---

## 🎓 Tips & Tricks

### Getting the Best Results

**1. Use Real Export Files**
Don't manually create CSV files. Export directly from:
- GeoBallistics app
- Applied Ballistics app
- Garmin ShotView

**2. Don't Edit CSV Files**
The parser handles metadata and formatting automatically. No need to:
- Remove title rows
- Delete summary rows
- Clean up formatting

**3. Check Your Data**
After import:
- Review the DOPE table
- Verify distances and elevations look correct
- Mark imported data as "confirmed" after field validation

**4. Use Default Values Wisely**
For ShotView imports:
- Set default distance to your zero distance (usually 100 yards)
- Set default elevation to 0.0
- This creates velocity-tagged DOPE points

---

## 🤝 Support

### Common Issues

**"No data imported"**
- Check that your CSV has range/distance and elevation columns
- Or provide default distance/elevation for velocity data
- Try loading an example CSV to see the expected format

**"X skipped"**
- Duplicate distances are automatically skipped
- Invalid data (negative distances, non-numbers) is skipped
- This is normal and expected

**File picker doesn't open**
- Grant storage permissions when prompted
- Ensure you have a file manager app installed
- Try restarting the app

### Getting Help
1. Review the example CSV files (tap 📥 icon)
2. Check CSV_PARSING_IMPROVEMENTS.md for format details
3. Verify your CSV matches one of the supported formats

---

## 🔮 Future Enhancements

Potential features for future versions:
- Import preview before committing
- Custom column mapping UI
- Support for more CSV formats
- Batch file import
- Export profiles to CSV
- Import/export backup files

---

## 👏 Credits

**Developer:** Garrett Booth  
**Project:** MatchBallistics / Empirical Dope  
**Enhancements:** Ona (AI Assistant)  
**Version:** 4  
**Date:** December 23, 2025

---

## 📄 License

See LICENSE file for details.

---

**Enjoy the improved CSV import experience!** 🎯
