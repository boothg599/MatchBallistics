# Feature: File Browser for CSV Imports

## Overview

Added file browsing capability to the CSV import feature, allowing users to select CSV files from their device's file system instead of only pasting text.

## What Changed

### New Functionality

Users can now import CSV files in two ways:
1. **Browse File** - Select a CSV file from device storage (NEW)
2. **Paste Text** - Copy and paste CSV content directly (existing)

### User Interface Updates

The CSV import dialog now includes three buttons:
- **Browse file** - Opens the system file picker to select CSV/TXT files
- **Load example** - Loads bundled sample CSV (existing)
- **Clear** - Clears the text field (existing)

### Technical Implementation

**Added Dependency:**
- `file_picker: ^8.1.4` - Cross-platform file selection

**Modified Files:**
- `pubspec.yaml` - Added file_picker dependency
- `lib/screens/profile_detail_screen.dart` - Added file picker integration

**New Method:**
```dart
Future<void> _pickCsvFile(BuildContext context) async {
  // Opens file picker for CSV/TXT files
  // Reads file content and populates the text field
  // Shows success/error messages
}
```

## How to Use

### Importing from a File

1. Open a profile
2. Tap the menu (⋮) and select "Import CSV"
3. Select the import source (ShotView, GeoBallistics, or AB Quantum)
4. Tap **"Browse file"**
5. Navigate to your CSV file in the file picker
6. Select the file
7. Review the loaded content in the text field
8. Tap **"Import"** to process the data

### Supported File Types

- `.csv` - Comma-separated values
- `.txt` - Plain text files with CSV format

### File Picker Features

- **Single file selection** - Pick one file at a time
- **File type filtering** - Only shows CSV and TXT files
- **Cross-platform** - Works on Android, iOS, and other platforms
- **Error handling** - Shows clear messages if file loading fails

## Benefits

### User Experience
- ✅ No need to open files in another app and copy/paste
- ✅ Direct access to device storage
- ✅ Faster workflow for importing data
- ✅ Supports files from Downloads, cloud storage, etc.

### Technical
- ✅ Uses native file picker for better UX
- ✅ Handles both bytes and path-based file access
- ✅ Proper error handling and user feedback
- ✅ Maintains backward compatibility with paste method

## Permissions

### Android
The file_picker package handles permissions automatically. Users will be prompted to grant storage access when first using the file browser.

### iOS
No additional permissions required for basic file access.

## Examples

### Workflow 1: Import from Downloads
1. Download CSV from email/web
2. Open Empirical Dope app
3. Navigate to profile → Import CSV
4. Tap "Browse file"
5. Select file from Downloads folder
6. Import data

### Workflow 2: Import from Cloud Storage
1. Save CSV to Google Drive/Dropbox
2. Open Empirical Dope app
3. Navigate to profile → Import CSV
4. Tap "Browse file"
5. Navigate to cloud storage provider
6. Select and import file

## Troubleshooting

### "Error loading file" Message
- Ensure the file is a valid CSV or TXT file
- Check that the file isn't corrupted
- Try copying the file to device storage first

### File Picker Doesn't Open
- Grant storage permissions when prompted
- Check that file manager app is installed
- Restart the app and try again

### File Loads but Import Fails
- Verify the CSV format matches the selected source
- Check that the file contains valid data
- Review the CSV format requirements in README.md

## Technical Details

### File Reading Strategy

The implementation uses a dual approach:
1. **Bytes-based** - Reads file.bytes if available (web, some mobile scenarios)
2. **Path-based** - Falls back to file.path for local file system access

This ensures compatibility across different platforms and file sources.

### Memory Considerations

- Files are read entirely into memory
- Suitable for typical CSV files (< 1 MB)
- Very large files may cause performance issues
- Consider splitting large datasets into smaller files

## Future Enhancements

Potential improvements for future versions:
- Support for multiple file selection
- Drag-and-drop file import (desktop/web)
- Recent files list
- File format validation before import
- Progress indicator for large files

## Version Information

- **Feature Added:** v3
- **APK SHA256:** `56ba335b3700624c497fbaf319ffa2ae916282754ef373300dea6c177526413e`
- **Package:** file_picker ^8.1.4
- **Date:** December 23, 2025

## Related Documentation

- README.md - CSV import format specifications
- INSTALL_APK.md - Installation instructions
- BUGFIX_WAL_MODE.md - Previous bug fix details

## Code Changes Summary

```diff
pubspec.yaml:
+ file_picker: ^8.1.4

lib/screens/profile_detail_screen.dart:
+ import 'package:file_picker/file_picker.dart';
+ Future<void> _pickCsvFile(BuildContext context) async { ... }
+ TextButton.icon(
+   onPressed: () => _pickCsvFile(context),
+   icon: const Icon(Icons.folder_open),
+   label: const Text('Browse file'),
+ ),
```

## Testing Checklist

- [x] File picker opens on Android
- [x] CSV files can be selected
- [x] TXT files can be selected
- [x] File content loads into text field
- [x] Import works after file selection
- [x] Error messages display correctly
- [x] Paste method still works
- [x] Example CSV loading still works
- [x] Clear button works
- [x] APK builds successfully
