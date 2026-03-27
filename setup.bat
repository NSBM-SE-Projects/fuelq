@echo off
echo Checking secret files...

if not exist "android\app\google-services.json" (
    echo MISSING: google-services.json CHECK SETUP.md
    exit /b 1
)

if not exist "lib\firebase_options.dart" (
    echo MISSING: firebase_options.dart CHECK SETUP.md
    exit /b 1
)

echo All secret files present
flutter pub get
echo Setup Complete!
echo Run: flutter run