import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'services/notification_service.dart';

void main() async {
  // Run the app in a guarded zone to catch all errors
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set up global error handling
    _setupErrorHandling();
    
    try {
      // Initialize Firebase
      debugPrint('🚀 Starting Atlas Fitness App...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
      
      // Add detailed Firebase connectivity test
      try {
        final auth = FirebaseAuth.instance;
        debugPrint('🔐 Firebase Auth instance created: ${auth.app.name}');
        debugPrint('📋 Firebase project: ${auth.app.options.projectId}');
        debugPrint('🔑 Firebase API key: ${auth.app.options.apiKey.substring(0, 10)}...');
        
        // Test if we can reach Firebase servers
        await auth.fetchSignInMethodsForEmail('nonexistent-test@example.com');
        debugPrint('✅ Firebase connectivity test successful');
      } catch (e) {
        debugPrint('❌ Firebase connectivity test failed: $e');
        if (e.toString().contains('network-request-failed')) {
          debugPrint('🔥 NETWORK ISSUE: Cannot reach Firebase servers');
          debugPrint('   - Check internet connection');
          debugPrint('   - Check if Firebase project exists');
          debugPrint('   - Check API key permissions');
        }
      }
        
      // Load environment variables
      try {
        await dotenv.load(fileName: ".env");
        debugPrint('📄 .env file loaded successfully');
      } catch (e) {
        // .env file not found or unreadable — initialize with an empty map so
        // that dotenv.env never throws NotInitializedException downstream.
        dotenv.testLoad(fileInput: '');
        debugPrint('⚠️ Warning: .env file not found. Using default configuration.');
      }
      
      // Initialize notifications
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();
      debugPrint('🔔 Notifications initialized successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error during initialization: $e');
      _logError('Initialization Error', e, stackTrace);
    }
    
    debugPrint('🚀 Launching app...');
    runApp(const ProviderScope(child: MyApp()));
    
  }, (error, stack) {
    // This catches any errors that occur outside of Flutter's error handling
    _logError('Unhandled Zone Error', error, stack);
  });
}

void _setupErrorHandling() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('Flutter Error', details.exception, details.stack);
  };
  
  // Catch errors from the platform (iOS/Android/macOS)
  PlatformDispatcher.instance.onError = (error, stack) {
    _logError('Platform Error', error, stack);
    return true;
  };
}

void _logError(String type, Object error, StackTrace? stackTrace) {
  // Print to console with clear formatting
  debugPrint('');
  debugPrint('🔥' * 50);
  debugPrint('❌ $type');
  debugPrint('🔥' * 50);
  debugPrint('Error: $error');
  if (stackTrace != null) {
    debugPrint('Stack Trace:');
    debugPrint(stackTrace.toString());
  }
  debugPrint('🔥' * 50);
  debugPrint('');
  
  // Also log to developer console for debugging
  developer.log(
    '$type: $error',
    name: 'AtlasApp',
    error: error,
    stackTrace: stackTrace,
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🏗️ Building MyApp widget...');
    
    try {
      final router = ref.watch(routerProvider);
      debugPrint('🧭 Router configured successfully');
      
      return MaterialApp.router(
        title: 'Atlas Fitness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        builder: (context, child) {
          // Add error boundary and loading handling
          return _AppErrorBoundary(
            child: child ?? const _LoadingScreen(),
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error building MyApp: $e');
      _logError('App Build Error', e, stackTrace);
      
      // Return a basic error screen if app build fails
      return MaterialApp(
        home: _ErrorScreen(error: e.toString()),
      );
    }
  }
}

class _AppErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const _AppErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 Showing loading screen...');
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Atlas Fitness...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    debugPrint('❌ Showing error screen: $error');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Atlas Fitness Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  debugPrint('🔄 Restarting app...');
                  // In a real app, you might want to restart or retry initialization
                },
                child: const Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
