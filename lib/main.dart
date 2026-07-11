import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router/app_router.dart';

/// 🎯 EXPERT FIX: REWRITE MAIN INITIALIZATION
/// The app was hanging on splash because of missing Flutter binding initialization
/// and potential unhandled exceptions during the startup sequence.
void main() async {
  // 1. MUST BE FIRST: Initialize Flutter framework bindings
  // Required before any async calls or plugin initializations
  WidgetsFlutterBinding.ensureInitialized();

  // 2. DEFENSIVE INITIALIZATION
  // Wrap in try-catch to prevent infinite hangs and silent crashes
  try {
    // Add a small delay or check for critical dependencies here
    // This ensures the engine is fully warmed up before the first build
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. START APP
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("FATAL STARTUP ERROR: $e");
    debugPrint(stackTrace.toString());
    
    // Fallback: Still try to run the app so the developer sees the error on screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Fatal Startup Error:\n$e")),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Meowtrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF985BEF),
          primary: const Color(0xFF985BEF),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
