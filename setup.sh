#! /bin/bash

echo "Checking secret files..."

if [ ! -f "android/app/google-services.json" ]; then
    echo "MISSING: google-services.json PLEASE CHECK SETUP.md"
    exit 1
fi

if [ ! -f "lib/firebase_options.dart" ]; then
    echo "MISSING: firebase_options.dart PLEASE CHECK SETUP.md"
    exit 1
fi

echo "All secret files present : )"
flutter pub get
echo "Setup Complete!"
echo "Run: flutter run"
