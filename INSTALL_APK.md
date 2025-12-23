# APK Installation Instructions

## Download the APK

The APK file is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

**File Details:**
- Size: 21.4 MB
- SHA256: `bbc301b5b24ef9a6610ab8827acbc91c8f06821fb9b7c2099d60d4c1181187ac`
- Build: v4.2 (Fixed encoding issues)

## Installation Methods

### Method 1: Direct Download (Recommended)

1. Download the APK file from the workspace
2. Transfer it to your Android device via:
   - USB cable
   - Cloud storage (Google Drive, Dropbox, etc.)
   - Email attachment
   - Messaging app

### Method 2: ADB Installation (Developer Method)

If you have ADB (Android Debug Bridge) installed:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Installing on Your Android Device

### Prerequisites
- Android 5.0 (Lollipop) or higher
- Allow installation from unknown sources

### Steps

1. **Enable Unknown Sources**
   - Go to Settings → Security (or Privacy)
   - Enable "Install unknown apps" or "Unknown sources"
   - Select the app you'll use to install (e.g., Chrome, Files)
   - Toggle "Allow from this source"

2. **Locate the APK**
   - Open your file manager
   - Navigate to Downloads or where you saved the APK
   - Tap on `app-release.apk`

3. **Install**
   - Tap "Install" when prompted
   - Wait for installation to complete
   - Tap "Open" to launch the app

4. **Grant Permissions**
   - The app will request storage permissions for database access
   - Tap "Allow" to grant necessary permissions

## Troubleshooting

### "App not installed" Error
- Ensure you have enough storage space (at least 50 MB free)
- Try uninstalling any previous version first
- Verify the APK file downloaded completely

### "Installation blocked" Error
- Check that "Unknown sources" is enabled
- Some devices require enabling this per-app
- Try using a different file manager

### App Crashes on Launch
- Ensure your Android version is 5.0 or higher
- Clear app data: Settings → Apps → Empirical Dope → Storage → Clear Data
- Restart your device and try again

## App Information

**App Name:** Empirical Dope  
**Package Name:** com.example.empirical_dope  
**Version:** 1.0.0+1  
**Min SDK:** Android 5.0 (API 21)  
**Target SDK:** Android 14 (API 34)

## Features

Once installed, you can:
- Create rifle/load profiles with MIL or MOA units
- Record DOPE points (distance vs. elevation)
- Import CSV data from ShotView, GeoBallistics, or AB Quantum
- Generate dope cards from 100 to 1200 yards
- Use the cosine calculator for angled shots
- Store all data locally (no internet required)

## Security Note

This is an unsigned APK built for testing purposes. When installing, Android will show a warning that the app is from an unknown developer. This is normal for apps not distributed through the Google Play Store.

For production use, the APK should be signed with a proper keystore and distributed through official channels.

## Uninstalling

To remove the app:
1. Go to Settings → Apps
2. Find "Empirical Dope"
3. Tap "Uninstall"

Note: Uninstalling will delete all local data including profiles and DOPE points.

## Support

For issues or questions:
- Check the README.md for app documentation
- Review FIXES.md for known issues and solutions
- Check AUDIT_SUMMARY.md for technical details
