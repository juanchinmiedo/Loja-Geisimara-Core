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

REM 1) Create lib/firebase_options_local.dart from example if missing
if not exist "lib\firebase_options_local.example.dart" (
  echo ERROR: lib\firebase_options_local.example.dart not found.
  echo Create the template file first.
  exit /b 1
)

if not exist "lib\firebase_options_local.dart" (
  copy "lib\firebase_options_local.example.dart" "lib\firebase_options_local.dart" >nul
  echo Created: lib\firebase_options_local.dart  (FILL IT with Firebase data)
) else (
  echo Exists:  lib\firebase_options_local.dart
)

REM 2) Create android/local.properties if missing
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

REM 3) Ensure firebase folder exists (rules/indexes)
if exist "firebase" (
  echo Found: firebase/ (rules/indexes live here)
) else (
  echo NOTE: firebase/ folder not found. If rules/indexes are required, add them.
)

echo.
echo NEXT STEPS:
echo - Put google-services.json in: android\app\google-services.json
echo - Put iOS plist in: ios\Runner\GoogleService-Info.plist (Mac only)
echo - Put macOS plist in: macos\Runner\GoogleService-Info.plist (Mac only)
echo - Fill: lib\firebase_options_local.dart (Firebase Console values)
echo - Fill: android\local.properties (GOOGLE_MAPS_API_KEY)
echo - Deploy rules:   firebase deploy --only firestore:rules
echo - Deploy indexes: firebase deploy --only firestore:indexes
echo.
echo Done.
endlocal
