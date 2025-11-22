@echo off
REM Profile Image Fix Test Runner (Windows)
REM This script runs the comprehensive tests for the profile image loading fix

echo 🧪 Running Profile Image Fix Tests...
echo ======================================

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: Please run this script from the project root directory
    pause
    exit /b 1
)

REM Install dependencies if needed
echo 📦 Installing dependencies...
flutter pub get

REM Generate mock files
echo 🔧 Generating mock files...
flutter packages pub run build_runner build --delete-conflicting-outputs

REM Run the profile image fix tests
echo 🚀 Running profile image loading tests...
flutter test test/profile_image_loading_test.dart

REM Check test results
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ All tests passed! Profile image fix is working correctly.
    echo.
    echo 📋 Test Summary:
    echo    - Profile path preservation: ✅
    echo    - Invalid path handling: ✅
    echo    - Widget behavior: ✅
    echo    - Integration scenarios: ✅
    echo.
    echo 🎯 The bug has been fixed! Profile images will now persist across login cycles.
) else (
    echo.
    echo ❌ Some tests failed. Please check the output above for details.
    echo.
    echo 🔍 Common issues:
    echo    - Make sure all dependencies are installed
    echo    - Check that the mock files were generated correctly
    echo    - Verify the test file exists at test/profile_profile_loading_test.dart
)

pause
