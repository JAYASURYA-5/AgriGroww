import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with try-catch so that missing configurations don't crash compile/startup
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase successfully initialized!");
  } catch (e) {
    debugPrint("Firebase initialization skipped/failed: $e");
  }
  
  // Initialize AdService
  await AdService.init();
  
  // Initialize AppState (loading persisted theme and language)
  final appState = AppState();
  await appState.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState().themeNotifier,
      builder: (context, themeStr, child) {
        return MaterialApp(
          title: 'AgriGrow',
          debugShowCheckedModeBanner: false,
          
          // Light Theme Design
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9FAFB),
            cardColor: Colors.white,
            dividerColor: const Color(0xFFE5E7EB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF22C55E),
              primary: const Color(0xFF22C55E),
              brightness: Brightness.light,
              outlineVariant: const Color(0xFFF3F4F6),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Dark Theme Design
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF111827), // Deep charcoal background
            cardColor: const Color(0xFF1F2937), // Dark grey container background
            dividerColor: const Color(0xFF374151), // Slate grey dividers
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF22C55E),
              primary: const Color(0xFF22C55E),
              brightness: Brightness.dark,
              surface: const Color(0xFF1F2937),
              onSurface: Colors.white,
              outlineVariant: const Color(0xFF374151),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F2937),
              elevation: 0.5,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Dynamic theme mode selection
          themeMode: themeStr == 'Light'
              ? ThemeMode.light
              : themeStr == 'Dark'
                  ? ThemeMode.dark
                  : ThemeMode.system,
                  
          home: AppState().currentUserId != null
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
