# LaWise App Deployment Guide

This guide covers deploying the LaWise Flutter app to various platforms.

## 🚀 Prerequisites

- Flutter SDK 3.7.2+
- Firebase project configured
- Google Gemini API key
- Platform-specific development tools

## 📱 Android Deployment

### 1. Build Configuration

**android/app/build.gradle:**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.lawise"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. Signing Configuration

**android/key.properties:**
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path_to_your_keystore.jks
```

**android/app/build.gradle:**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

### 3. Build Commands

```bash
# Generate keystore (if not exists)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Build split APKs
flutter build apk --split-per-abi --release
```

### 4. Play Store Deployment

1. **Create Play Console Account**
   - Go to [Google Play Console](https://play.google.com/console)
   - Pay $25 one-time registration fee

2. **Upload App Bundle**
   - Create new app
   - Upload AAB file
   - Fill store listing
   - Set up content rating
   - Configure pricing

3. **Release**
   - Internal testing
   - Closed testing
   - Open testing
   - Production release

## 🍎 iOS Deployment

### 1. Build Configuration

**ios/Runner/Info.plist:**
```xml
<key>CFBundleDisplayName</key>
<string>LaWise</string>
<key>CFBundleIdentifier</key>
<string>com.example.lawise</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 2. Signing & Capabilities

1. **Xcode Setup**
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Configure signing team
   - Set bundle identifier

2. **Capabilities**
   - Push Notifications
   - Background Modes
   - App Groups (if needed)

### 3. Build Commands

```bash
# Build iOS app
flutter build ios --release

# Archive in Xcode
# Product → Archive
```

### 4. App Store Deployment

1. **App Store Connect**
   - Create app record
   - Upload build via Xcode
   - Fill app information
   - Submit for review

2. **Review Process**
   - 1-7 days typical
   - Ensure compliance with App Store guidelines

## 🌐 Web Deployment

### 1. Build Configuration

**web/index.html:**
```html
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="LaWise - Empowering Legal Minds">
  
  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="LaWise">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  
  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>
  
  <title>LaWise</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script>
    var serviceWorkerVersion = null;
  </script>
  <script src="flutter.js" defer></script>
</body>
</html>
```

### 2. Build Commands

```bash
# Build web app
flutter build web --release

# Build with specific base href
flutter build web --release --web-renderer html --base-href "/lawise/"
```

### 3. Deployment Options

#### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize hosting
firebase init hosting

# Deploy
firebase deploy
```

#### Netlify
1. Connect GitHub repository
2. Build command: `flutter build web --release`
3. Publish directory: `build/web`
4. Deploy automatically on push

#### Vercel
1. Import GitHub repository
2. Framework preset: Other
3. Build command: `flutter build web --release`
4. Output directory: `build/web`

## 🔧 CI/CD Setup

### GitHub Actions

**.github/workflows/deploy.yml:**
```yaml
name: Deploy LaWise

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.7.2'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: app-bundle
          path: build/app/outputs/bundle/release/app-release.aab

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: build/web
```

### Environment Variables

**GitHub Secrets:**
- `FIREBASE_SERVICE_ACCOUNT_KEY`
- `GEMINI_API_KEY`
- `PLAY_STORE_CREDENTIALS`
- `APP_STORE_CONNECT_API_KEY`

## 📊 Performance Optimization

### 1. Build Optimizations

```bash
# Enable R8 optimization
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Web optimization
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### 2. Asset Optimization

- Compress images
- Use WebP format
- Implement lazy loading
- Cache static assets

### 3. Code Splitting

- Implement route-based code splitting
- Lazy load non-critical components
- Use deferred imports for heavy libraries

## 🔒 Security Checklist

- [ ] API keys not exposed in source code
- [ ] Firebase security rules configured
- [ ] HTTPS enabled for web
- [ ] Input validation implemented
- [ ] Authentication properly configured
- [ ] Data encryption for sensitive information
- [ ] Regular security updates

## 📱 Testing Before Deployment

### 1. Local Testing
```bash
# Run on device/emulator
flutter run --release

# Test web
flutter run -d chrome --release
```

### 2. Automated Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### 3. Manual Testing
- [ ] Authentication flow
- [ ] Core functionality
- [ ] UI responsiveness
- [ ] Performance metrics
- [ ] Error handling

## 🚨 Post-Deployment

### 1. Monitoring
- Firebase Analytics
- Crash reporting
- Performance monitoring
- User feedback collection

### 2. Updates
- Regular dependency updates
- Security patches
- Feature releases
- Bug fixes

### 3. Rollback Plan
- Keep previous versions
- Feature flags for gradual rollout
- Database migration strategies
- Backup procedures

## 📚 Additional Resources

- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🆘 Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Flutter version compatibility
   - Verify dependency versions
   - Clean and rebuild: `flutter clean && flutter pub get`

2. **Signing Issues**
   - Verify keystore configuration
   - Check certificate validity
   - Ensure proper key aliases

3. **Deployment Errors**
   - Review platform-specific requirements
   - Check API quotas and limits
   - Verify configuration files

4. **Performance Issues**
   - Analyze build output
   - Check asset sizes
   - Review code optimization

For additional support, create an issue in the GitHub repository or contact the development team.
