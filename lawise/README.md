# LaWise - Empowering Legal Minds

A comprehensive legal management platform built with Flutter, designed to streamline case management, legal research, and AI-powered legal assistance.

## 🚀 Features

### Core Functionality
- **Authentication System**: Secure login/signup with email/password
- **Dashboard**: Overview of today's hearings, practice areas, and active cases
- **Case Management**: Comprehensive case tracking and management
- **Law Library**: Access to legal documents and resources
- **AI Legal Assistant**: Powered by Google Gemini API for legal queries and document drafting
- **Notifications**: Real-time updates and reminders
- **Profile Management**: User settings and preferences

### AI Integration
- **Google Gemini API**: Advanced AI-powered legal assistance
- **Legal Document Drafting**: AI-generated contract templates and legal documents
- **Case Analysis**: AI-powered legal case analysis and risk assessment
- **Legal Research**: AI-assisted legal research and information retrieval
- **Smart Conversations**: Context-aware legal discussions with memory
- **Professional Prompts**: Specialized legal prompts for accurate responses

### UI/UX
- **Material 3 Design**: Modern, clean interface following Google's design guidelines
- **Responsive Design**: Optimized for mobile, tablet, and web
- **Dark Mode Ready**: Theme system prepared for future dark mode implementation
- **Professional Aesthetics**: Legal industry-appropriate design language

## 🛠 Tech Stack

- **Framework**: Flutter 3.x with null safety
- **State Management**: Riverpod (Provider pattern)
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Messaging)
- **AI Integration**: Google Gemini API (gemini-pro model)
- **UI Components**: Material 3, Google Fonts
- **Platforms**: Android, iOS, Web (PWA-ready)

## 📱 Screenshots

The app includes the following screens based on the provided UI reference images:

1. **Splash Screen**: LaWise logo with "Empowering Legal Minds" tagline
2. **Authentication**: Login and Create Account screens
3. **Dashboard**: Home screen with hearings, practice areas, and cases
4. **Case Management**: Case list and detail views
5. **Law Library**: Legal document browsing
6. **AI Chat**: Legal assistant interface
7. **Notifications**: System and case updates
8. **Profile**: User settings and preferences

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.7.2 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Firebase project setup
- Google Gemini API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/lawise.git
   cd lawise
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Download and add configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
     - Web configuration for web platform

4. **AI Service Setup**
   - Get a Google Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - The API key is already configured in `lib/config/ai_config.dart`
   - For production, move the API key to environment variables
   - The AI service uses the `gemini-pro` model for optimal legal assistance

5. **Run the app**
   ```bash
   flutter run
   ```

### Configuration Files

#### Android
- Place `google-services.json` in `android/app/`
- Update `android/app/build.gradle` with Firebase dependencies

#### iOS
- Place `GoogleService-Info.plist` in `ios/Runner/`
- Update `ios/Runner/Info.plist` with required permissions

#### Web
- Add Firebase configuration to `web/index.html`

## 🔧 Configuration

### AI Service Configuration
The AI service is configured in `lib/config/ai_config.dart`:

```dart
class AIConfig {
  static const String geminiApiKey = 'YOUR_API_KEY';
  static const String geminiModel = 'gemini-pro';
  static const double temperature = 0.7;
  static const int maxOutputTokens = 2048;
}
```

### Environment Variables (Production)
For production deployment, set the following environment variables:

```bash
GEMINI_API_KEY=your_actual_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project_id
```

## 🏗 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── case_model.dart
│   ├── chat_message.dart
│   ├── notification_model.dart
│   └── law_library_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   └── case_provider.dart
├── services/                 # Business logic
│   ├── firebase_service.dart
│   └── ai_service.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── auth/                 # Authentication screens
│   └── main/                 # Main app screens
│       ├── home_screen.dart
│       ├── cases/
│       ├── library/
│       ├── ai_chat/
│       └── profile/
├── theme/                    # App theming
│   └── app_theme.dart
└── utils/                    # Utility functions
```

## 🔧 Development

### Adding New Features

1. **Create Models**: Add data models in `lib/models/`
2. **Update Providers**: Extend state management in `lib/providers/`
3. **Add Services**: Implement business logic in `lib/services/`
4. **Create Screens**: Build UI components in `lib/screens/`
5. **Update Theme**: Modify styling in `lib/theme/app_theme.dart`

### Code Style

- Follow Flutter/Dart best practices
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Maintain consistent formatting with `flutter format`

## 🚀 Deployment

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🔒 Security

- Firebase Security Rules for Firestore
- Role-based access control
- Input validation and sanitization
- Secure API key management
- Data encryption for sensitive information

## 📊 Performance

- Optimized for 60fps performance
- Efficient state management
- Lazy loading for large datasets
- Image caching and optimization
- Minimal network requests

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation and FAQ

## 🔮 Roadmap

### Phase 1 (Current)
- ✅ Basic authentication
- ✅ Dashboard and navigation
- ✅ Case management foundation
- ✅ UI/UX implementation

### Phase 2 (Next)
- 🔄 Advanced case management
- 🔄 Document management
- ✅ AI integration completion
- 🔄 Notification system

### Phase 3 (Future)
- 📋 Advanced analytics
- 📋 Team collaboration
- 📋 Mobile app store deployment
- 📋 Web PWA optimization

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google AI for Gemini API
- Material Design team for design guidelines
- Legal professionals for domain expertise

---

**LaWise** - Empowering Legal Minds with Technology
