@echo off
echo Deploying Firebase Configuration...
echo.

echo 1. Installing Firebase CLI (if not already installed)...
npm install -g firebase-tools

echo.
echo 2. Logging into Firebase...
firebase login

echo.
echo 3. Initializing Firebase project...
firebase use lawise-5a5a7

echo.
echo 4. Deploying Firestore rules...
firebase deploy --only firestore:rules

echo.
echo 5. Deploying Firestore indexes...
firebase deploy --only firestore:indexes

echo.
echo 6. Deploying Storage rules...
firebase deploy --only storage

echo.
echo Firebase configuration deployed successfully!
echo.
echo Next steps:
echo 1. Restart your Flutter app
echo 2. Test Firebase authentication and Firestore operations
echo 3. Check Firebase Console for any additional configuration needed
echo.
pause