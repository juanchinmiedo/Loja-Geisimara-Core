@echo off
setlocal enabledelayedexpansion

echo ========================================
echo CLIENT SETUP (Windows)
echo Creates local files that must NOT be committed.
echo ========================================

REM Ensure lib folder exists
if not exist "lib" (
  echo ERROR: 'lib' folder not found. Run this from the project root.
  exit /b 1
)

REM 1) Create lib/firebase_options.dart from example if missing
if not exist "lib\firebase_options.example.dart" (
  echo ERROR: lib\firebase_options.example.dart not found.
  echo Create the template file first.
  exit /b 1
)

if not exist "lib\firebase_options.dart" (
  copy "lib\firebase_options.example.dart" "lib\firebase_options.dart" >nul
  echo Created: lib\firebase_options.dart  (FILL IT with Firebase data)
) else (
  echo Exists:  lib\firebase_options.dart
)

REM 2) Create android/local.properties if missing (keep sdk.dir empty for client to fill)
if not exist "android" (
  echo WARNING: 'android' folder not found. Skipping Android local.properties.
) else (
  if not exist "android\local.properties" (
    echo sdk.dir= > "android\local.properties"
    echo flutter.sdk= >> "android\local.properties"
    echo GOOGLE_MAPS_API_KEY= >> "android\local.properties"
    echo Created: android\local.properties  (Fill sdk.dir/flutter.sdk/GOOGLE_MAPS_API_KEY)
  ) else (
    echo Exists:  android\local.properties
  )
)

echo.
echo NEXT STEPS:
echo - Put google-services.json in: android\app\google-services.json
echo - Put iOS plist in: ios\Runner\GoogleService-Info.plist (Mac only)
echo - Put macOS plist in: macos\Runner\GoogleService-Info.plist (Mac only)
echo - Fill: lib\firebase_options.dart (Firebase Console values)
echo - Fill: android\local.properties (GOOGLE_MAPS_API_KEY)
echo.
echo Done.
endlocal
