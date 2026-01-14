#!/usr/bin/env sh
set -e

echo "========================================"
echo "CLIENT SETUP (macOS/Linux)"
echo "Creates local files that must NOT be committed."
echo "========================================"

if [ ! -d "lib" ]; then
  echo "ERROR: 'lib' folder not found. Run this from the project root."
  exit 1
fi

# 1) Create lib/firebase_options_local.dart from example if missing
if [ ! -f "lib/firebase_options_local.example.dart" ]; then
  echo "ERROR: lib/firebase_options_local.example.dart not found."
  echo "Create the template file first."
  exit 1
fi

if [ ! -f "lib/firebase_options_local.dart" ]; then
  cp "lib/firebase_options_local.example.dart" "lib/firebase_options_local.dart"
  echo "Created: lib/firebase_options_local.dart  (FILL IT with Firebase data)"
else
  echo "Exists:  lib/firebase_options_local.dart"
fi

# 2) Create android/local.properties if missing
if [ -d "android" ]; then
  if [ ! -f "android/local.properties" ]; then
    {
      echo "sdk.dir="
      echo "flutter.sdk="
      echo "GOOGLE_MAPS_API_KEY="
    } > "android/local.properties"
    echo "Created: android/local.properties  (Fill sdk.dir/flutter.sdk/GOOGLE_MAPS_API_KEY)"
  else
    echo "Exists:  android/local.properties"
  fi
else
  echo "WARNING: 'android' folder not found. Skipping Android local.properties."
fi

# 3) Note firebase folder
if [ -d "firebase" ]; then
  echo "Found: firebase/ (rules/indexes live here)"
else
  echo "NOTE: firebase/ folder not found. If rules/indexes are required, add them."
fi

echo ""
echo "NEXT STEPS:"
echo "- Put google-services.json in: android/app/google-services.json"
echo "- Put iOS plist in: ios/Runner/GoogleService-Info.plist (Mac only)"
echo "- Put macOS plist in: macos/Runner/GoogleService-Info.plist (Mac only)"
echo "- Fill: lib/firebase_options_local.dart (Firebase Console values)"
echo "- Fill: android/local.properties (GOOGLE_MAPS_API_KEY)"
echo "- Deploy rules:   firebase deploy --only firestore:rules"
echo "- Deploy indexes: firebase deploy --only firestore:indexes"
echo ""
echo "Done."
