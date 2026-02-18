# Atlas Fitness App

A comprehensive AI-powered fitness tracking application built with Flutter.

## Features

### Category 1: AI-Driven Personalization
1. **Intelligent Diet Coach (AI Chatbot)** - Conversational AI that provides nutritional guidance and meal tracking
2. **Dynamic Workout Optimizer** - ML-based intensity adjustment based on post-workout feedback
3. **Automated Workout Generator** - API-integrated exercise plan generation

### Category 2: Core Fitness Tracking
4. **Precision Exercise Logger** - Detailed exercise tracking with sets, reps, and weights
5. **Body Metric Analytics & Visualization** - Interactive progress charts for weight and measurements
6. **Consistency Tracking** - Streak system to maintain daily workout habits

### Category 3: Social & Community Features
7. **Community Content Feed** - Share posts, likes, and comments
8. **Social Connectivity** - Friends system for peer support
9. **Gamified Weekly Challenges** - Competitive challenges with badge rewards

### Category 4: System & Engagement Utilities
10. **Integrated User Management** - Secure Firebase authentication
11. **Smart Engagement Notifications** - Daily tips and workout reminders
12. **Bug Reporting & Feedback** - Direct issue reporting to admin

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK
- Firebase account
- iOS development: Xcode and CocoaPods
- Android development: Android Studio
- OpenAI API key (for AI Diet Coach)
- Exercise API key (optional - API Ninjas or similar)

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
cd /Users/ran/cs/Atlas
flutter pub get
```

### 2. Firebase Setup

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase for your project:
```bash
flutterfire configure
```

3. Follow the prompts to:
   - Create or select a Firebase project
   - Enable platforms (iOS, Android, macOS)
   - The CLI will automatically generate `lib/firebase_options.dart`

4. Enable Firebase services in Firebase Console:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging
   - Cloud Functions (optional)

### 3. Environment Variables

1. Update the `.env` file with your API keys:
```env
OPENAI_API_KEY=your_actual_openai_api_key
EXERCISE_API_KEY=your_exercise_api_key (optional)
EXERCISE_API_BASE_URL=https://api.api-ninjas.com/v1
```

2. Get API keys:
   - **OpenAI**: https://platform.openai.com/api-keys
   - **Exercise API**: https://api-ninjas.com/ (or use the built-in sample data)

### 4. Platform-Specific Setup

#### iOS/macOS
1. Accept Xcode license:
```bash
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

2. Install CocoaPods dependencies:
```bash
cd ios
pod install
cd ..
```

#### Android
1. Ensure Android SDK is installed in Android Studio
2. Accept Android licenses:
```bash
flutter doctor --android-licenses
```

### 5. Run the App

```bash
# Check for issues
flutter doctor

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Or specify a device
flutter devices
flutter run -d <device_id>
```

## Project Structure

```
lib/
├── core/               # App constants, theme, router
├── models/             # Data models
├── providers/          # Riverpod state management
├── services/           # Firebase, AI, API services
├── screens/            # UI screens
│   ├── auth/          # Login/Register
│   ├── home/          # Dashboard
│   ├── workouts/      # Workout management
│   ├── exercises/     # Exercise logging
│   ├── body_metrics/  # Progress tracking
│   ├── ai_chat/       # AI coach chat
│   ├── social/        # Feed and posts
│   ├── challenges/    # Weekly challenges
│   ├── profile/       # User profile
│   └── settings/      # Settings and bug reports
└── widgets/            # Reusable components
```

## Tech Stack

- **Framework**: Flutter 3.9.2
- **State Management**: Riverpod
- **Navigation**: go_router
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **AI**: OpenAI GPT-4o-mini
- **Charts**: fl_chart
- **HTTP**: http, dio
- **Local Storage**: shared_preferences
- **Notifications**: flutter_local_notifications

## Firebase Firestore Collections

- `users` - User profiles and streaks
- `workouts` - Generated and completed workouts
- `exercise_logs` - Individual exercise records
- `body_metrics` - Weight and measurements
- `posts` - Community posts
- `comments` - Post comments
- `friends` - Friend relationships
- `challenges` - Weekly challenges
- `user_challenge_progress` - User progress tracking
- `bug_reports` - User-reported issues
- `chat_history` - AI chat conversations

## Key Features Implementation

### AI Diet Coach
- Uses OpenAI GPT-4o-mini for conversational nutrition guidance
- Maintains chat history for context-aware responses
- Provides meal analysis and daily tips

### Dynamic Workout Optimizer
- Post-workout intensity survey (1-5 rating)
- Automatically adjusts future workout difficulty
- Tracks duration and user feedback

### Workout Generator
- Integrates with Exercise API for diverse exercises
- Customizable by difficulty (Beginner/Intermediate/Advanced)
- Target specific muscle groups
- Adjustable exercise count

### Streak System
- Automatic streak calculation based on workout completion
- Tracks current and longest streaks
- Grace period for streak maintenance

### Notifications
- Daily nutrition tips
- Workout reminders
- Streak alerts
- Challenge completion notifications

## Troubleshooting

### Xcode License Not Accepted
```bash
sudo xcodebuild -license accept
```

### Firebase Not Configured
```bash
flutterfire configure
```

### Missing Dependencies
```bash
flutter pub get
flutter pub upgrade
```

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## Development

### Adding New Features
1. Create models in `lib/models/`
2. Add services in `lib/services/`
3. Create providers in `lib/providers/`
4. Build UI in `lib/screens/`
5. Update router in `lib/core/router.dart`

### Testing
```bash
flutter test
```

### Building for Release

#### iOS
```bash
flutter build ios --release
```

#### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Private project - All rights reserved

## Support

For bugs and issues, use the in-app bug reporting feature or contact the development team.
