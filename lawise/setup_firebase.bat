@echo off
echo ========================================
echo    LaWise Firebase Setup Script
echo ========================================
echo.

echo This script will help you set up Firebase for your LaWise app.
echo.
echo Before running this script, make sure you have:
echo 1. Created a Firebase project at console.firebase.google.com
echo 2. Downloaded google-services.json for Android
echo 3. Downloaded GoogleService-Info.plist for iOS
echo.

pause

echo.
echo Checking current directory...
if not exist "android\app\google-services.json" (
    echo.
    echo WARNING: google-services.json not found in android\app\
    echo Please download it from Firebase Console and place it in android\app\
    echo.
    pause
) else (
    echo ✓ google-services.json found
)

if not exist "ios\Runner\GoogleService-Info.plist" (
    echo.
    echo WARNING: GoogleService-Info.plist not found in ios\Runner\
    echo Please download it from Firebase Console and place it in ios\Runner\
    echo.
    pause
) else (
    echo ✓ GoogleService-Info.plist found
)

echo.
echo Running Flutter commands...
echo.

echo Cleaning project...
flutter clean

echo Getting dependencies...
flutter pub get

echo.
echo ========================================
echo    Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Update lib/firebase_options.dart with your Firebase config
echo 2. Update web/index.html with your Firebase config
echo 3. Configure security rules in Firebase Console
echo 4. Test the app with: flutter run
echo.
echo For detailed instructions, see FIREBASE_SETUP_GUIDE.md
echo.
pause
