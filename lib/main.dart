import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/tutorial_controller.dart';
import 'package:meow_track/core/notification_service.dart';
import 'router/app_router.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🎯 BACKGROUND MESSAGE HANDLER
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background Message Received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. AI features might not work without key.");
  }

  // 1. Initialize Firebase with Options for Web
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCFskSLhi8YyQbKE-34FrRxbnuhaUM2aZs",
          appId: "1:501455160941:web:placeholder", 
          messagingSenderId: "501455160941",
          projectId: "meowtrack-61f45",
          storageBucket: "meowtrack-61f45.firebasestorage.app",
          authDomain: "meowtrack-61f45.firebaseapp.com",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // 2. Register Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Foreground Listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("Foreground Message: ${message.notification?.title}");
    
    // 🎯 Tunjukkan Local Notification jika app sedang dibuka
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb && appState.notificationsEnabled) {
      // Logic to filter based on notification type could be added here if payload includes category
      NotificationService().showNotification(
        id: notification.hashCode,
        title: notification.title ?? "Meowtrack",
        body: notification.body ?? "",
      );
    }
  });

  // 4. Initialize timezone
  tz_data.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
  } catch (e) {
    print('Failed to set timezone: $e');
  }

  // 3. Initialize App State (FCM, etc.) after Firebase
  await appState.init();

  // 4. Initialize Notification Service
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appState),
        ChangeNotifierProvider(create: (_) => TutorialController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () {
        // 🎯 Tandakan tutorial sebagai selesai apabila mana-mana fasa tamat
        Provider.of<TutorialController>(context, listen: false).completeTutorial();
      },
      builder: (context) => MaterialApp.router(
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
      ),
    );
  }
}
