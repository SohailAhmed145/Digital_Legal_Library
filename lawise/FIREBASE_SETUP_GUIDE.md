# 🔥 Firebase Setup Guide for LaWise

This guide will walk you through setting up Firebase for your LaWise Flutter app step by step.

## 📋 Prerequisites

- Flutter SDK installed
- Firebase account (create one at [console.firebase.google.com](https://console.firebase.google.com))
- Android Studio / Xcode (for platform-specific setup)

## 🚀 Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `LaWise`
4. Enable Google Analytics (recommended)
5. Click "Create project"
6. Wait for project creation to complete

## 🔧 Step 2: Enable Firebase Services

### Authentication
1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" provider
3. Enable "Google" provider (optional)
4. Enable "Apple" provider (optional)

### Firestore Database
1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location close to your users
4. Click "Enable"

### Storage
1. Go to "Storage" → "Get started"
2. Choose "Start in test mode" (for development)
3. Select a location
4. Click "Done"

### Cloud Messaging
1. Go to "Cloud Messaging"
2. Note the Server key (will be needed for notifications)

## 📱 Step 3: Platform Configuration

### Android Setup

1. **Add Android App**
   - In Firebase Console, click "Add app" → "Android"
   - Package name: `com.example.lawise`
   - App nickname: `LaWise`
   - Click "Register app"

2. **Download Configuration**
   - Download `google-services.json`
   - Place it in `android/app/`

3. **Update Gradle Files**
   
   **android/build.gradle:**
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.3.15'
       }
   }
   ```
   
   **android/app/build.gradle:**
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   
   android {
       defaultConfig {
           minSdkVersion 21
       }
   }
   
   dependencies {
       implementation platform('com.google.firebase:firebase-bom:32.7.0')
       implementation 'com.google.firebase:firebase-analytics'
       implementation 'com.google.firebase:firebase-auth'
       implementation 'com.google.firebase:firebase-firestore'
       implementation 'com.google.firebase:firebase-storage'
       implementation 'com.google.firebase:firebase-messaging'
   }
   ```

### iOS Setup

1. **Add iOS App**
   - In Firebase Console, click "Add app" → "iOS"
   - Bundle ID: `com.example.lawise`
   - App nickname: `LaWise`
   - Click "Register app"

2. **Download Configuration**
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/`

3. **Update Podfile**
   ```ruby
   platform :ios, '12.0'
   
   target 'Runner' do
     use_frameworks!
     use_modular_headers!
   
     flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
   end
   ```

4. **Install Pods**
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Web Setup

1. **Add Web App**
   - In Firebase Console, click "Add app" → "Web"
   - App nickname: `LaWise Web`
   - Click "Register app"

2. **Copy Configuration**
   - Copy the Firebase config object
   - Update `lib/firebase_options.dart` with your values

## 🔑 Step 4: Update Configuration Files

### Update Firebase Options

1. Open `lib/firebase_options.dart`
2. Replace all placeholder values with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: "your-actual-web-api-key",
  appId: "your-actual-web-app-id",
  messagingSenderId: "your-actual-sender-id",
  projectId: "your-actual-project-id",
  authDomain: "your-actual-project.firebaseapp.com",
  storageBucket: "your-actual-project.appspot.com",
  measurementId: "your-actual-measurement-id",
);
```

3. Do the same for `android` and `ios` configurations

### Update Web Configuration

1. Open `web/index.html`
2. Replace the Firebase config in the script tag with your actual values

## 🛡️ Step 5: Security Rules

### Firestore Rules

1. In Firebase Console, go to "Firestore Database" → "Rules"
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Cases can only be accessed by the creator
    match /cases/{caseId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.createdBy;
    }
    
    // Chat conversations can only be accessed by the user
    match /chat_conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Chat messages can only be accessed by conversation participants
    match /chat_messages/{messageId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/chat_conversations/$(resource.data.conversationId)) &&
        get(/databases/$(database)/documents/chat_conversations/$(resource.data.conversationId)).data.userId == request.auth.uid;
    }
    
    // Notifications can only be accessed by the user
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Law documents are publicly readable
    match /law_documents/{documentId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Storage Rules

1. In Firebase Console, go to "Storage" → "Rules"
2. Replace the rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only upload to their own folder
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Case documents can only be accessed by case creator
    match /cases/{caseId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/cases/$(caseId)) &&
        get(/databases/$(database)/documents/cases/$(caseId)).data.createdBy == request.auth.uid;
    }
  }
}
```

## 🧪 Step 6: Test Configuration

### Test Authentication
1. Run the app: `flutter run`
2. Try to create an account
3. Check Firebase Console → Authentication → Users

### Test Firestore
1. Create a case in the app
2. Check Firebase Console → Firestore Database → Data

### Test Storage
1. Upload a file in the app
2. Check Firebase Console → Storage → Files

## 🚨 Common Issues & Solutions

### Android Build Errors
- **Issue**: `google-services.json` not found
  - **Solution**: Ensure `google-services.json` is in `android/app/`

- **Issue**: Gradle sync failed
  - **Solution**: Clean and rebuild: `flutter clean && flutter pub get`

### iOS Build Errors
- **Issue**: `GoogleService-Info.plist` not found
  - **Solution**: Ensure file is in `ios/Runner/`

- **Issue**: Pod install failed
  - **Solution**: Run `cd ios && pod install && cd ..`

### Web Build Errors
- **Issue**: Firebase not initialized
  - **Solution**: Check Firebase config in `web/index.html`

- **Issue**: CORS errors
  - **Solution**: Add your domain to Firebase Console → Authentication → Settings → Authorized domains

## 🔐 Environment Variables (Optional)

Create a `.env` file in your project root:

```env
# Firebase Configuration
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id

# Google Gemini API
GEMINI_API_KEY=your-gemini-api-key

# Other Configuration
ENVIRONMENT=development
```

## 📚 Next Steps

After completing this setup:

1. **Test the app** with Firebase services
2. **Implement Google Sign-In** (optional)
3. **Implement Apple Sign-In** (optional)
4. **Set up Cloud Functions** for advanced features
5. **Configure Analytics** and monitoring
6. **Set up CI/CD** with GitHub Actions

## 🆘 Getting Help

If you encounter issues:

1. Check Firebase Console for error logs
2. Verify configuration files are in correct locations
3. Check Flutter and Firebase plugin versions
4. Review security rules configuration
5. Check the [Firebase Flutter Documentation](https://firebase.flutter.dev/)

## 🎯 Success Checklist

- [ ] Firebase project created
- [ ] Services enabled (Auth, Firestore, Storage, Messaging)
- [ ] Platform apps added (Android, iOS, Web)
- [ ] Configuration files downloaded and placed
- [ ] Security rules configured
- [ ] App runs without Firebase errors
- [ ] Authentication works
- [ ] Database operations work
- [ ] File uploads work
- [ ] Notifications work

---

**Congratulations!** 🎉 Your LaWise app is now connected to Firebase and ready for development.
