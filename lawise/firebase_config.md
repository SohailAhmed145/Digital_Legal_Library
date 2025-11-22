# Firebase Configuration for LaWise

This guide will help you set up Firebase for the LaWise Flutter app.

## 🔥 Firebase Project Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `LaWise`
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Firebase Services

#### Authentication
1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" provider
3. Enable "Google" provider (optional)
4. Enable "Apple" provider (optional)

#### Firestore Database
1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location close to your users
4. Click "Enable"

#### Storage
1. Go to "Storage" → "Get started"
2. Choose "Start in test mode" (for development)
3. Select a location
4. Click "Done"

#### Cloud Messaging
1. Go to "Cloud Messaging"
2. Note the Server key (will be needed for notifications)

## 📱 Platform Configuration

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

2. **Update web/index.html**
   ```html
   <!DOCTYPE html>
   <html>
   <head>
     <!-- ... existing head content ... -->
   </head>
   <body>
     <!-- ... existing body content ... -->
     
     <!-- Firebase Configuration -->
     <script type="module">
       import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js'
       import { getAuth } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js'
       import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js'
       import { getStorage } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-storage.js'
       import { getMessaging } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging.js'
       
       const firebaseConfig = {
         apiKey: "your-api-key",
         authDomain: "your-project.firebaseapp.com",
         projectId: "your-project-id",
         storageBucket: "your-project.appspot.com",
         messagingSenderId: "your-sender-id",
         appId: "your-app-id"
       };
       
       const app = initializeApp(firebaseConfig);
       const auth = getAuth(app);
       const db = getFirestore(app);
       const storage = getStorage(app);
       const messaging = getMessaging(app);
     </script>
   </body>
   </html>
   ```

## 🔐 Security Rules

### Firestore Rules
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

## 🚀 Environment Variables

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

## 🔧 Testing Configuration

### Test Authentication
1. Run the app
2. Try to create an account
3. Check Firebase Console → Authentication → Users

### Test Firestore
1. Create a case
2. Check Firebase Console → Firestore Database → Data

### Test Storage
1. Upload a file
2. Check Firebase Console → Storage → Files

## 🚨 Common Issues

### Android Build Errors
- Ensure `google-services.json` is in `android/app/`
- Check Gradle version compatibility
- Clean and rebuild: `flutter clean && flutter pub get`

### iOS Build Errors
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Run `pod install` in `ios/` directory
- Check iOS deployment target (minimum iOS 12.0)

### Web Build Errors
- Check Firebase config in `web/index.html`
- Ensure all Firebase services are enabled
- Check browser console for errors

## 📚 Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Firebase Plugin](https://pub.dev/packages/firebase_core)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

## 🆘 Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Verify configuration files are in correct locations
3. Check Flutter and Firebase plugin versions
4. Review security rules configuration
5. Create an issue in the GitHub repository
