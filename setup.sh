#!/bin/bash

# Atlas Fitness Quick Setup Script
# This script helps set up the Atlas Fitness app quickly

echo "🏋️ Atlas Fitness - Quick Setup"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    echo "Visit: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check if FlutterFire CLI is installed
echo "📦 Checking FlutterFire CLI..."
if ! command -v flutterfire &> /dev/null; then
    echo "Installing FlutterFire CLI..."
    dart pub global activate flutterfire_cli
fi

echo "✅ FlutterFire CLI ready"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  .env file not found"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "✅ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env file and add your API keys:"
    echo "   - OPENAI_API_KEY (required for AI Diet Coach)"
    echo "   - EXERCISE_API_KEY (optional - uses sample data if not provided)"
    echo ""
else
    echo "✅ .env file exists"
    echo ""
fi

# Firebase setup
echo "🔥 Firebase Configuration"
echo "=========================="
echo ""
echo "Run the following command to configure Firebase:"
echo "  flutterfire configure"
echo ""
echo "This will:"
echo "  1. Create or select a Firebase project"
echo "  2. Enable platforms (iOS, Android, macOS)"
echo "  3. Generate lib/firebase_options.dart"
echo ""

# Platform-specific setup
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 macOS Detected - iOS/macOS Setup"
    echo "==================================="
    echo ""
    
    # Check Xcode
    if command -v xcodebuild &> /dev/null; then
        echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
        
        # Check if Xcode license is accepted
        if ! xcodebuild -checkFirstLaunchStatus &> /dev/null; then
            echo "⚠️  Xcode license not accepted"
            echo "Run: sudo xcodebuild -license accept"
        else
            echo "✅ Xcode license accepted"
        fi
    else
        echo "⚠️  Xcode not found. Install from App Store for iOS/macOS development."
    fi
    
    # Check CocoaPods
    if command -v pod &> /dev/null; then
        echo "✅ CocoaPods found"
    else
        echo "⚠️  CocoaPods not found"
        echo "Install: sudo gem install cocoapods"
    fi
    echo ""
fi

# Check available devices
echo "📱 Available Devices"
echo "==================="
flutter devices
echo ""

# Final instructions
echo "✨ Setup Complete!"
echo "==================="
echo ""
echo "Next steps:"
echo "1. Configure Firebase: flutterfire configure"
echo "2. Update .env with your API keys"
echo "3. Enable Firebase services:"
echo "   - Authentication (Email/Password)"
echo "   - Cloud Firestore"
echo "   - Cloud Storage"
echo "   - Cloud Messaging"
echo "4. Run the app: flutter run"
echo ""
echo "For detailed instructions, see ATLAS_README.md"
echo ""
