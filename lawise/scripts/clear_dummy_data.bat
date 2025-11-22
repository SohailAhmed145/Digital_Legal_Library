@echo off
echo Clearing persistent dummy data (Alexander Mitchell profile)...
echo.
echo This will remove all stored profile data to allow proper user names.
echo.
pause

cd /d "%~dp0.."
echo Running clear dummy data script...
dart run scripts/clear_dummy_data.dart

echo.
echo Done! You can now restart the app and create a new account.
pause