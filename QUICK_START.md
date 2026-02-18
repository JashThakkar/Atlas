## 🏋️ Atlas Fitness - Quick Start Guide

### What You've Got
A complete fitness app with 12 core features ready to use!

### Before First Run

#### 1. **Firebase Setup (Required)**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

**In Firebase Console**, enable:
- ✅ Authentication → Email/Password
- ✅ Firestore Database → Create database (test mode for development)
- ✅ Storage → Create default bucket
- ✅ Cloud Messaging → Enable

#### 2. **API Keys (Optional but Recommended)**

Edit `.env` file:
```env
OPENAI_API_KEY=sk-your-actual-key-here
EXERCISE_API_KEY=your-key-here
```

- **OpenAI**: Get from https://platform.openai.com/api-keys
  - Used for AI Diet Coach feature
  - Without it: AI coach will show error message
  
- **Exercise API**: Get from https://api-ninjas.com/
  - Used for workout generator
  - Without it: Uses built-in sample exercises (10 exercises)

#### 3. **Run the App**

```bash
# Check everything is OK
flutter doctor

# Install dependencies (already done)
flutter pub get

# Run on device/emulator
flutter run
```

### First Time User Flow

1. **Register Account**
   - Opens to login screen
   - Tap "Register" to create account
   - Enter name, email, password

2. **Home Dashboard**
   - See your stats (all zeros initially)
   - Current streak starts at 0

3. **Try These Features**
   - 📝 **Log Exercise**: Tap "Log Exercise" → Add an exercise with sets/reps
   - 🤖 **Generate Workout**: Tap "Generate Workout" → Choose difficulty → Get AI workout
   - 💬 **AI Diet Coach**: Tap chat icon → Ask nutrition questions
   - 📊 **Track Body Metrics**: Tap "Track Metrics" → Add weight/measurements
   - 🏆 **View Challenges**: Sidebar → Challenges (admin can create these in Firestore)

### Testing Without Firebase

If you want to test WITHOUT full Firebase setup:
1. Comment out `await Firebase.initializeApp()` in `lib/main.dart`
2. App will run but crash on auth/database operations
3. Not recommended - Firebase is required for the app to function

### Known Limitations

- **No web support** in current config (can be added via `flutterfire configure`)
- **Sample workout generator** data if no Exercise API key
- **AI chat** requires OpenAI key (shows error otherwise)
- **Push notifications** need additional FCM setup per platform

### Project Structure Quick Reference

```
lib/
├── screens/
│   ├── auth/           # Login/Register → /login, /register
│   ├── home/           # Dashboard → /home
│   ├── workouts/       # Workout management → /workouts, /generate-workout
│   ├── exercises/      # Exercise logger → /exercise-logger
│   ├── body_metrics/   # Progress charts → /body-metrics
│   ├── ai_chat/        # AI coach → /ai-chat
│   ├── social/         # Community feed → /feed
│   ├── challenges/     # Weekly challenges → /challenges
│   ├── profile/        # User profile → /profile
│   └── settings/       # Settings → /settings, /bug-report
```

### Troubleshooting

**"Xcode license not accepted"**
```bash
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

**"Firebase not configured"**
```bash
flutterfire configure
```

**"Can't find module"**
```bash
flutter clean
flutter pub get
flutter run
```

**"CocoaPods error" (iOS only)**
```bash
cd ios
pod install
cd ..
flutter run
```

### Creating Sample Data (Optional)

To test challenges and social features, you can manually add data in Firebase Console:

**Sample Challenge** (`challenges` collection):
```json
{
  "title": "7-Day Workout Streak",
  "description": "Complete a workout for 7 consecutive days",
  "type": "Streak Days",
  "targetValue": 7,
  "badgeId": "7_day_warrior",
  "startDate": "<today's date>",
  "endDate": "<7 days from now>",
  "participants": []
}
```

### Advanced: Development Tips

- **Hot Reload**: Press `r` in terminal while app is running
- **Hot Restart**: Press `R` for full restart
- **DevTools**: Run `flutter pub global activate devtools`, then `dart devtools`
- **Logs**: Use `print()` or `debugPrint()` for console logs

### Complete Feature Checklist

Once Firebase is configured, you should be able to:

- ✅ Register and login
- ✅ Log exercises with sets/reps/weight
- ✅ Generate AI workouts (with or without API)
- ✅ Track body metrics with charts
- ✅ Chat with AI diet coach (needs OpenAI key)
- ✅ Post to community feed
- ✅ View and join challenges
- ✅ Maintain workout streaks
- ✅ Receive notifications (after setup)
- ✅ Report bugs
- ✅ View profile with badges

### Need Help?

Check `ATLAS_README.md` for full documentation.
