import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:meow_track/core/notification_service.dart';
import 'package:meow_track/core/utils/storage_helper.dart';

enum AppEventState { normal, emergencyNearby, myCatLost }

class Cat {
  final String id;
  final String name;
  final String breed;
  final String gender;
  final Color themeColor;
  final String image;
  final double imageScale;
  final String ownerId;
  final List<String> collaborators;
  double battery;
  String distance;
  bool isLost;
  int activeMinutes;
  int targetMinutes;
  double sleepHours;
  String sleepQuality;
  int heartRate;

  Cat({
    required this.id,
    required this.name,
    required this.breed,
    required this.gender,
    required this.themeColor,
    required this.image,
    required this.ownerId,
    this.collaborators = const [],
    this.imageScale = 1.0,
    this.battery = 50.0,
    this.distance = '200m away',
    this.isLost = false,
    this.activeMinutes = 0,
    this.targetMinutes = 120,
    this.sleepHours = 0.0,
    this.sleepQuality = 'Unknown',
    this.heartRate = 0,
  });

  bool isOwner(String uid) => ownerId == uid;
  bool canEdit(String uid) => ownerId == uid || collaborators.contains(uid);
}

class Appointment {
  final int id;
  final String catName;
  final String type;
  final DateTime scheduledAt;
  final String location;
  final String description;
  final bool notifyBefore;
  final DateTime? notificationDate;
  final double? lat;
  final double? lng;
  final String? imageUrl;

  Appointment({
    required this.id,
    required this.catName,
    required this.type,
    required this.scheduledAt,
    required this.location,
    required this.description,
    this.notifyBefore = true,
    this.notificationDate,
    this.lat,
    this.lng,
    this.imageUrl,
  });
}

class CommunityPost {
  final String id;
  final String author;
  final String title;
  final String content;
  final String category;
  final String locationLabel;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String status;
  final String phone;
  final String ownerId;
  final bool isVerified;
  final String? imageUrl;
  final String? reward;

  CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.category,
    required this.locationLabel,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.status = 'Lost',
    this.phone = '',
    this.ownerId = '',
    this.isVerified = false,
    this.imageUrl,
    this.reward,
  });
}

class CatNote {
  final String title;
  final String content;
  final String date;
  final IconData icon;

  CatNote({
    required this.title,
    required this.content,
    required this.date,
    required this.icon,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({required this.text, required this.isMe, required this.timestamp, this.imagePath});
}

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});
}

class Purrmate {
  final String uid;
  final String name;
  final String username;
  final String avatarUrl;
  final String purrCode;
  final bool isCoOwner;

  Purrmate({
    required this.uid,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.purrCode,
    this.isCoOwner = false,
  });
}

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String fromAvatar;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromUsername,
    required this.fromAvatar,
  });
}

class VetClinic {
  final String name;
  final String rating;
  final String distance;
  final String hours;
  final String phone;
  final String whatsapp;
  final String headerImage;
  final List<String> gallery;
  final String description;
  final double lat;
  final double lng;
  final List<Map<String, dynamic>> reviews;

  VetClinic({
    required this.name,
    required this.rating,
    required this.distance,
    required this.hours,
    required this.phone,
    required this.whatsapp,
    required this.headerImage,
    required this.gallery,
    required this.description,
    required this.lat,
    required this.lng,
    this.reviews = const [],
  });
}

class Expense {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  Expense({required this.id, required this.category, required this.amount, required this.date, this.note = ''});
}

class FoodLog {
  final String id;
  final String catId;
  final double grams;
  final int calories;
  final DateTime timestamp;

  FoodLog({required this.id, required this.catId, required this.grams, required this.calories, required this.timestamp});
}

class AppStateController extends ChangeNotifier {
  AppEventState _currentState = AppEventState.normal;
  AppEventState get currentState => _currentState;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  bool _isDeviceSecure = true;
  bool get isDeviceSecure => _isDeviceSecure;
  
  final _secureStorage = const FlutterSecureStorage();
  bool get isEmailVerified => FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  bool get needsRoleSelection => _isAuthenticated && sessionRole == null && availableRoles.length > 1;

  // Preferences (Persistent)
  bool _isKg = true;
  bool get isKg => _isKg;
  bool _isMeters = true;
  bool get isMeters => _isMeters;
  double _safeZoneRadius = 350.0;
  double get safeZoneRadius => _safeZoneRadius;
  String _trackingFrequency = "Balanced";
  String get trackingFrequency => _trackingFrequency;
  double _monthlyBudgetLimit = 500.0;
  double get monthlyBudgetLimit => _monthlyBudgetLimit;

  // 🎯 NOTIFICATION SETTINGS
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  bool _notifyAppointments = true;
  bool get notifyAppointments => _notifyAppointments;
  bool _notifyChat = true;
  bool get notifyChat => _notifyChat;
  bool _notifyEmergency = true;
  bool get notifyEmergency => _notifyEmergency;
  bool _notifyDailyCare = true;
  bool get notifyDailyCare => _notifyDailyCare;

  // Rank System
  String _currentRank = "Novice Pawrent";
  String get currentRank => _currentRank;
  int _trackingDays = 0;
  int get trackingDays => _trackingDays;

  // 🎯 DAILY CARE & STREAK SYSTEM
  int pawStreak = 0;
  List<Map<String, dynamic>> dailyTasks = [
    {'id': 'feed', 'title': 'Food & Water', 'icon': Icons.restaurant, 'done': false},
    {'id': 'litter', 'title': 'Clean Litter', 'icon': Icons.cleaning_services, 'done': false},
    {'id': 'play', 'title': 'Playtime (15m)', 'icon': Icons.toys, 'done': false},
    {'id': 'groom', 'title': 'Grooming', 'icon': Icons.brush, 'done': false},
  ];
  DateTime? lastStreakDate;

  bool isNewUser = false;
  String? userEmail;
  String? userName;
  String? userRole; 
  String? sessionRole;
  String? avatarUrl;
  String? purrCode;
  bool isProfileSetup = false;
  String? pendingVerificationPhone;
  List<String> availableRoles = [];
  
  // AI Config
  String _geminiApiKey = "";
  String get geminiApiKey => _geminiApiKey;

  // Usage tracking
  int aiRequestsThisMinute = 0;
  int aiRequestsToday = 0;
  DateTime? _lastResetMinute;
  DateTime? _lastResetDay;

  // Real-time Subscriptions
  StreamSubscription? _userSubscription;
  StreamSubscription? _catsSubscription;
  StreamSubscription? _apptSubscription;
  StreamSubscription? _friendsSubscription;
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _authSubscription;
  StreamSubscription? _prefSubscription;
  StreamSubscription? _chatSubscription;

  // Data Collections
  List<Cat> cats = [];
  List<Appointment> appointments = [];
  List<Purrmate> friends = [];
  List<FriendRequest> pendingRequests = [];
  List<CommunityPost> communityPosts = [];
  Map<String, List<Map<String, dynamic>>> catHealthRecords = {};
  Map<String, List<CatNote>> catNotes = {};
  List<ChatSession> chatHistory = [];
  ChatSession? activeSession;
  List<Expense> expenses = [];
  Map<String, List<FoodLog>> catFoodLogs = {};
  StreamSubscription? _foodLogsSubscription;

  Future<void> addExpense(String category, double amount, String note) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .add({
      'category': category,
      'amount': amount,
      'note': note,
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addFoodLog(String catId, double grams, int calories) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('food_logs')
        .add({
      'grams': grams,
      'calories': calories,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  AppStateController() {
    _initAuthListener();
    _loadPreferences();
  }

  // Generate a unique 8-character Purr Code
  String generatePurrCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O or 0 to avoid confusion
    final rnd = Random();
    return List.generate(8, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> ensurePurrCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists || doc.data()?['purrCode'] == null) {
      final newCode = generatePurrCode();
      await docRef.set({'purrCode': newCode}, SetOptions(merge: true));
      purrCode = newCode;
      notifyListeners();
    }
  }

  Future<void> init() async {
    await _checkSecurity();
    await _initRemoteConfig();
    _setupTokenRefreshListener();
    _loadUsageStats();
    // 🎯 INITIAL FCM SAVE (In case already logged in)
    if (FirebaseAuth.instance.currentUser != null) {
      await _saveDeviceToken();
    }
  }

  Future<void> _checkSecurity() async {
    try {
      bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      bool developerMode = await FlutterJailbreakDetection.developerMode;
      
      _isDeviceSecure = !jailbroken && !developerMode;
      
      if (!_isDeviceSecure) {
        debugPrint("SECURITY WARNING: Device is jailbroken or in developer mode!");
      }
    } catch (e) {
      _isDeviceSecure = true; // Fallback
    }
    notifyListeners();
  }

  Future<void> _initRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero, // Biar update terus nampak masa testing
      ));
      
      // Default value if fetch fails
      await remoteConfig.setDefaults({
        "gemini_api_key": "",
      });

      await remoteConfig.fetchAndActivate();
      _geminiApiKey = remoteConfig.getString("gemini_api_key");
      debugPrint("Remote Config: Gemini Key Fetched");
    } catch (e) {
      debugPrint("Remote Config Error: $e");
    }
  }

  // Example of using Secure Storage for sensitive data
  Future<void> saveSensitiveData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSensitiveData(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> _loadUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    aiRequestsToday = prefs.getInt('aiRequestsToday') ?? 0;
    final lastResetStr = prefs.getString('lastResetDay');
    if (lastResetStr != null) {
      _lastResetDay = DateTime.parse(lastResetStr);
      // Reset if different day
      if (_lastResetDay!.day != DateTime.now().day) {
        aiRequestsToday = 0;
        _lastResetDay = DateTime.now();
      }
    } else {
      _lastResetDay = DateTime.now();
    }
  }

  void incrementAiUsage() async {
    final now = DateTime.now();
    
    // Minute reset logic
    if (_lastResetMinute == null || now.difference(_lastResetMinute!).inMinutes >= 1) {
      aiRequestsThisMinute = 1;
      _lastResetMinute = now;
    } else {
      aiRequestsThisMinute++;
    }

    // Day reset logic
    if (_lastResetDay == null || now.day != _lastResetDay!.day) {
      aiRequestsToday = 1;
      _lastResetDay = now;
    } else {
      aiRequestsToday++;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aiRequestsToday', aiRequestsToday);
    await prefs.setString('lastResetDay', _lastResetDay!.toIso8601String());
    
    notifyListeners();
  }

  // --- PERSISTENT SETTINGS (SharedPreferences) ---

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isKg = prefs.getBool('isKg') ?? true;
    _isMeters = prefs.getBool('isMeters') ?? true;
    _safeZoneRadius = prefs.getDouble('safeZoneRadius') ?? 350.0;
    _trackingFrequency = prefs.getString('trackingFrequency') ?? "Balanced";
    _monthlyBudgetLimit = prefs.getDouble('monthlyBudgetLimit') ?? 500.0;
    
    // Load Notification Settings
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _notifyAppointments = prefs.getBool('notifyAppointments') ?? true;
    _notifyChat = prefs.getBool('notifyChat') ?? true;
    _notifyEmergency = prefs.getBool('notifyEmergency') ?? true;
    _notifyDailyCare = prefs.getBool('notifyDailyCare') ?? true;

    notifyListeners();
  }

  void setWeightUnit(bool isKg) async {
    _isKg = isKg;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKg', isKg);
    _syncPreferences();
  }

  void setDistanceUnit(bool isMeters) async {
    _isMeters = isMeters;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMeters', isMeters);
    _syncPreferences();
  }

  void setSafeZoneRadius(double radius) async {
    _safeZoneRadius = radius;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('safeZoneRadius', radius);
    _syncPreferences();
  }

  void setTrackingFrequency(String freq) async {
    _trackingFrequency = freq;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trackingFrequency', freq);
    _syncPreferences();
  }

  void setMonthlyBudgetLimit(double limit) async {
    _monthlyBudgetLimit = limit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudgetLimit', limit);
    _syncPreferences();
  }

  // 🎯 NOTIFICATION SETTERS
  void setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    _syncPreferences();
  }

  void setNotifyAppointments(bool value) async {
    _notifyAppointments = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyAppointments', value);
    _syncPreferences();
  }

  void setNotifyChat(bool value) async {
    _notifyChat = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyChat', value);
    _syncPreferences();
  }

  void setNotifyEmergency(bool value) async {
    _notifyEmergency = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyEmergency', value);
    _syncPreferences();
  }

  void setNotifyDailyCare(bool value) async {
    _notifyDailyCare = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyDailyCare', value);
    _syncPreferences();
  }

  Future<void> _syncPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('preferences').set({
      'isKg': _isKg,
      'isMeters': _isMeters,
      'safeZoneRadius': _safeZoneRadius,
      'trackingFrequency': _trackingFrequency,
      'monthlyBudgetLimit': _monthlyBudgetLimit,
      'notificationsEnabled': _notificationsEnabled,
      'notifyAppointments': _notifyAppointments,
      'notifyChat': _notifyChat,
      'notifyEmergency': _notifyEmergency,
      'notifyDailyCare': _notifyDailyCare,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- RANK CALCULATION ---

  void _updateRank() {
    // 🎯 NEW SCORE FORMULA:
    // Cats: 30 pts each (Encourage pet profiles)
    // Tracking Days: 5 pts each (Consistency)
    // Streak: 15 pts per day (Daily engagement)
    // Friends: 10 pts each (Social interaction)
    // Appointments: 5 pts each (Responsible care)
    
    int score = (cats.length * 30) + 
                (_trackingDays * 5) + 
                (pawStreak * 15) + 
                (friends.length * 10) +
                (appointments.length * 5);
    
    String oldRank = _currentRank;

    if (score < 50) {
      _currentRank = "Novice Pawrent";
    } else if (score < 150) {
      _currentRank = "Guardian Angel";
    } else if (score < 400) {
      _currentRank = "Cat Whisperer";
    } else if (score < 800) {
      _currentRank = "Professor Meow";
    } else {
      _currentRank = "Cat Royalty";
    }

    // 🎯 Notify if user leveled up
    if (oldRank != _currentRank && _isAuthenticated) {
      NotificationService().showNotification(
        id: 777,
        title: "Tahniah! Pangkat Anda Naik",
        body: "Anda kini berpangkat $_currentRank! Teruskan penjagaan yang baik. 🐾",
      );
    }

    notifyListeners();
  }

  // --- FIREBASE LISTENERS ---

  void _initAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _isAuthenticated = true;
        userEmail = user.email;
        _startListeners();
        // 🎯 SAVE FCM TOKEN AUTOMATICALLY ON LOGIN
        await _saveDeviceToken();
      } else {
        _isAuthenticated = false;
        _stopListeners();
        _clearData();
      }
      notifyListeners();
    });
  }

  // --- FCM & NOTIFICATIONS ---

  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // 1. Request permission (iOS/Android 13+)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get the token
        String? token = await messaging.getToken();
        
        if (token != null) {
          // 3. Update Firestore users/{uid}
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'fcmToken': token,
                'lastTokenUpdate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          
          debugPrint("FCM Token Saved: $token");
        }
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }


  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': newToken,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
        debugPrint("FCM Token Refreshed: $newToken");
      }
    });
  }

  void _startListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 7. Expenses Sync
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          id: doc.id,
          category: data['category'] ?? 'Others',
          amount: (data['amount'] ?? 0.0).toDouble(),
          date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
          note: data['note'] ?? '',
        );
      }).toList();
      notifyListeners();
    });

    // 1. User Profile & Tracking Activity
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        userName = data['username'] ?? user.displayName ?? 'User';
        userEmail = data['email'] ?? user.email ?? '';
        
        // Handle multiple roles
        final rawRole = data['role'];
        if (rawRole is List) {
          availableRoles = List<String>.from(rawRole);
        } else if (rawRole is String) {
          availableRoles = [rawRole];
        } else {
          availableRoles = ['user'];
        }
        
        userRole = availableRoles.first;
        avatarUrl = data['avatarUrl'];
        purrCode = data['purrCode'];

        // 🎯 Load Streak Data
        pawStreak = data['pawStreak'] ?? 0;
        final ts = data['lastStreakDate'] as Timestamp?;
        lastStreakDate = ts?.toDate();
        _checkStreakReset();

        // 🎯 Load Daily Task Completion (stored locally or in a sub-collection)
        // For simplicity in this phase, we use a per-session reset or simple logic
        
        // Auto-generate Purr Code if it doesn't exist in Firestore
        if (purrCode == null || purrCode!.isEmpty) {
          ensurePurrCode();
        }

        // 🎯 LOGIK USER LAMA: Jika ada avatarUrl atau username, kita anggap profile sudah setup
        isProfileSetup = data['isProfileSetup'] ?? 
                        ((avatarUrl != null && avatarUrl!.isNotEmpty) || (userName != null && userName!.isNotEmpty));
        _trackingDays = data['trackingDays'] ?? 0;

        // 🎯 LOGIK PERANAN: Hanya auto-set jika ada SATU sahaja peranan.
        // Jika ada 2 (admin & user), biarkan ia null supaya user boleh pilih di VerificationScreen.
        if (availableRoles.length == 1) {
          sessionRole = availableRoles.first;
        } else {
          // Jika lebih dari 1, pastikan sessionRole tidak diusik melainkan user sudah pilih
          if (sessionRole != null && !availableRoles.contains(sessionRole)) {
            sessionRole = null;
          }
        }
        
        _updateRank(); 
        notifyListeners();
      }
    });

    // 1.1 Preferences Sync from Cloud
    _prefSubscription?.cancel();
    _prefSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _isKg = data['isKg'] ?? _isKg;
        _isMeters = data['isMeters'] ?? _isMeters;
        _safeZoneRadius = (data['safeZoneRadius'] ?? _safeZoneRadius).toDouble();
        _trackingFrequency = data['trackingFrequency'] ?? _trackingFrequency;
        
        _notificationsEnabled = data['notificationsEnabled'] ?? _notificationsEnabled;
        _notifyAppointments = data['notifyAppointments'] ?? _notifyAppointments;
        _notifyChat = data['notifyChat'] ?? _notifyChat;
        _notifyEmergency = data['notifyEmergency'] ?? _notifyEmergency;
        _notifyDailyCare = data['notifyDailyCare'] ?? _notifyDailyCare;

        notifyListeners();
      }
    });

    // 2. Cats Sync (Owner + Collaborator)
    _catsSubscription?.cancel();
    _catsSubscription = FirebaseFirestore.instance
        .collection('cats')
        .where(Filter.or(
          Filter('ownerId', isEqualTo: user.uid),
          Filter('collaborators', arrayContains: user.uid),
        ))
        .snapshots()
        .listen((snapshot) {
      cats = snapshot.docs.map((doc) {
        final data = doc.data();
        return Cat(
          id: doc.id,
          name: data['name'] ?? '',
          breed: data['breed'] ?? '',
          gender: data['gender'] ?? '',
          themeColor: Color(data['themeColor'] ?? 0xFFD0E0FF),
          image: data['image'] ?? 'assets/images/Luna.png',
          ownerId: data['ownerId'] ?? '',
          collaborators: List<String>.from(data['collaborators'] ?? []),
          imageScale: (data['imageScale'] ?? 1.0).toDouble(),
          battery: (data['battery'] ?? 50.0).toDouble(),
          distance: data['distance'] ?? 'Unknown',
          isLost: data['isLost'] ?? false,
          activeMinutes: data['activeMinutes'] ?? 0,
          targetMinutes: data['targetMinutes'] ?? 120,
          sleepHours: (data['sleepHours'] ?? 0.0).toDouble(),
          sleepQuality: data['sleepQuality'] ?? 'Unknown',
          heartRate: data['heartRate'] ?? 0,
        );
      }).toList();
      _updateRank(); 
      notifyListeners();
    });

    // 3. Appointments Sync
    _apptSubscription?.cancel();
    _apptSubscription = FirebaseFirestore.instance
        .collection('appointments')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        final appt = Appointment(
          id: data['id'] ?? 0,
          catName: data['catName'] ?? '',
          type: data['type'] ?? '',
          scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
          location: data['location'] ?? '',
          description: data['description'] ?? '',
          notifyBefore: data['notifyBefore'] ?? true,
          notificationDate: data['notificationDate'] != null ? (data['notificationDate'] as Timestamp).toDate() : null,
          lat: (data['lat'] as num?)?.toDouble(),
          lng: (data['lng'] as num?)?.toDouble(),
          imageUrl: data['imageUrl'] as String?,
        );

        // 🎯 Jadualkan Local Notification jika perlu
        if (appt.notifyBefore && appt.notificationDate != null && notificationsEnabled && notifyAppointments) {
          if (appt.notificationDate!.isAfter(DateTime.now())) {
            NotificationService().scheduleNotification(
              id: appt.id,
              title: "Peringatan: ${appt.type}",
              body: "Temujanji untuk ${appt.catName} di ${appt.location} akan berlangsung tidak lama lagi.",
              scheduledDate: appt.notificationDate!,
            );
          }
        }

        return appt;
      }).toList();
      notifyListeners();
    });

    // 4. Friends Sync
    _friendsSubscription?.cancel();
    _friendsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots()
        .listen((snapshot) {
      friends = snapshot.docs.map((doc) {
        final data = doc.data();
        return Purrmate(
          uid: doc.id,
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          purrCode: data['purrCode'] ?? '',
          isCoOwner: data['isCoOwner'] ?? false,
        );
      }).toList();
      _updateRank(); // 🎯 Update rank when friends change
      notifyListeners();
    });

    // 5. Pending Requests Sync
    _requestsSubscription?.cancel();
    _requestsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pending_requests')
        .snapshots()
        .listen((snapshot) {
      pendingRequests = snapshot.docs.map((doc) {
        final data = doc.data();
        return FriendRequest(
          id: doc.id,
          fromUid: data['fromUid'] ?? '',
          fromName: data['fromName'] ?? '',
          fromUsername: data['fromUsername'] ?? '',
          fromAvatar: data['fromAvatar'] ?? '',
        );
      }).toList();
      notifyListeners();
    });

    // 6. Chat History Sync
    _chatSubscription?.cancel();
    _chatSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_history')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<ChatSession> history = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Fetch sub-collection messages for each session
        final msgSnapshot = await doc.reference.collection('messages').orderBy('timestamp').get();
        final List<ChatMessage> msgs = msgSnapshot.docs.map((mDoc) {
          final mData = mDoc.data();
          return ChatMessage(
            text: mData['text'] ?? '',
            isMe: mData['isMe'] ?? false,
            timestamp: (mData['timestamp'] as Timestamp).toDate(),
            imagePath: mData['imagePath'],
          );
        }).toList();

        history.add(ChatSession(
          id: doc.id,
          title: data['title'] ?? 'Chat Session',
          messages: msgs,
        ));
      }
      chatHistory = history;
      if (activeSession != null) {
        final match = history.where((s) => s.id == activeSession!.id).toList();
        if (match.isNotEmpty) {
          final synced = match.first;
          // Keep locally-added messages if Firestore sync is briefly behind.
          if (synced.messages.length >= activeSession!.messages.length) {
            activeSession = synced;
          }
        }
      }
      notifyListeners();
    });
  }

  void _stopListeners() {
    _userSubscription?.cancel();
    _catsSubscription?.cancel();
    _apptSubscription?.cancel();
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _prefSubscription?.cancel();
    _chatSubscription?.cancel();
    _foodLogsSubscription?.cancel();
  }

  void loadFoodLogs(String catId) {
    _foodLogsSubscription?.cancel();
    _foodLogsSubscription = FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('food_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      catFoodLogs[catId] = snapshot.docs.map((doc) {
        final data = doc.data();
        return FoodLog(
          id: doc.id,
          catId: catId,
          grams: (data['grams'] ?? 0.0).toDouble(),
          calories: data['calories'] ?? 0,
          timestamp: data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate() 
              : DateTime.now(),
        );
      }).toList();
      notifyListeners();
    });
  }
  
  void _clearData() {
    cats = [];
    appointments = [];
    friends = [];
    pendingRequests = [];
    expenses = [];
    catFoodLogs = {};
    userName = null;
    avatarUrl = null;
    userRole = null;
    sessionRole = null;
  }

  // --- AUTH ACTIONS ---

  void login({required String email, required String password}) {
    _isAuthenticated = true;
    userEmail = email;
    notifyListeners();
  }

  /// Returns the route a logged-in user should land on based on verification & profile state.
  Future<String> resolvePostLoginRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '/auth-gateway';

    await user.reload();
    if (!user.emailVerified) return '/verify-otp';

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return '/profile-setup';

    final data = doc.data()!;
    final avatarUrlStr = data['avatarUrl'] as String?;
    final nameStr = data['username'] as String?;
    
    // 🎯 LOGIK USER LAMA: Profile dianggap siap jika:
    // 1. Flag isProfileSetup = true
    // 2. ATAU ada avatarUrl
    // 3. ATAU ada username (User lama mungkin tak set avatar tapi dah ada nama)
    final profileReady = data['isProfileSetup'] == true || 
                        (avatarUrlStr != null && avatarUrlStr.isNotEmpty) ||
                        (nameStr != null && nameStr.isNotEmpty);

    if (!profileReady) return '/profile-setup';

    final rawRole = data['role'];
    List<String> roles;
    if (rawRole is List) {
      roles = List<String>.from(rawRole);
    } else if (rawRole is String) {
      roles = [rawRole];
    } else {
      roles = ['user'];
    }

    availableRoles = roles;
    userName = data['username'] ?? user.displayName ?? 'User';
    avatarUrl = avatarUrlStr;

    // 🎯 LOGIK PERANAN: Jika admin, benarkan pilihan dashboard.
    // Jika user biasa (hanya 1 role 'user'), auto-set.
    if (roles.length == 1 && roles.first == 'user') {
      sessionRole = 'user';
    } else if (sessionRole == null || !roles.contains(sessionRole)) {
      return '/verify-otp';
    }

    final role = sessionRole ?? roles.first;
    notifyListeners();
    return role == 'admin' ? '/admin-dashboard' : '/dashboard';
  }

  void signUp({required String email, required String username, required String password, String phoneNumber = ""}) {
    userEmail = email;
    userName = username;
    pendingVerificationPhone = phoneNumber;
    notifyListeners();
  }

  void completeSignUp() {
    _isAuthenticated = true;
    isNewUser = true;
    pendingVerificationPhone = null;
    notifyListeners();
  }

  void completePasswordReset() {
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> reauthenticateUser(String email, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in");
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  // --- PROFILE ACTIONS ---

  Future<void> updateProfile({String? username, String? newEmail}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (newEmail != null && newEmail != user.email) {
      await user.updateEmail(newEmail);
    }
    if (username != null) {
      await user.updateDisplayName(username);
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      if (username != null) 'username': username,
      if (newEmail != null) 'email': newEmail,
    }, SetOptions(merge: true));

    if (username != null) userName = username;
    if (newEmail != null) userEmail = newEmail;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🎯 Guna StorageHelper untuk kompres & saiz limit
      final downloadUrl = await StorageHelper.processAndUpload(
        originalFile: imageFile,
        folder: 'user_avatars',
        uid: user.uid,
        name: 'profile_pic.jpg',
      );

      if (downloadUrl != null) {
        // 🎯 Update local state immediately for better UX
        avatarUrl = downloadUrl;
        isProfileSetup = true;
        notifyListeners();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'avatarUrl': downloadUrl,
          'isProfileSetup': true,
        });
      }
    } catch (e) {
      debugPrint("Error uploading profile picture: $e");
      rethrow;
    }
  }

  // --- MODERATION ACTIONS (Admin Only) ---

  Future<void> deletePost(String postId) async {
    if (sessionRole != 'admin') throw Exception("Unauthorized");
    await FirebaseFirestore.instance.collection('community_posts').doc(postId).delete();
    
    // Log deletion
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'event': 'Post Deleted by Admin',
      'postId': postId,
      'adminId': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ignoreReport(String postId) async {
    if (sessionRole != 'admin') throw Exception("Unauthorized");
    await FirebaseFirestore.instance.collection('community_posts').doc(postId).update({
      'isFlagged': false,
      'reportCount': 0,
      'reportedBy': [],
      'moderationStatus': 'active'
    });
  }

  Future<void> markCatAsFound(String catId) async {
    if (sessionRole != 'admin') throw Exception("Unauthorized");
    await FirebaseFirestore.instance.collection('cats').doc(catId).update({
      'isLost': false,
      'foundByAdmin': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    
    // Log action
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'event': 'Cat Marked as Found by Admin',
      'catId': catId,
      'adminId': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- SOCIAL ACTIONS ---

  Future<void> reportPost(String postId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      List reportedBy = List.from(data['reportedBy'] ?? []);
      
      if (reportedBy.contains(user.uid)) {
        throw Exception("You have already reported this post.");
      }

      reportedBy.add(user.uid);
      int newCount = (data['reportCount'] ?? 0) + 1;
      bool shouldFlag = newCount >= 5;

      transaction.update(postRef, {
        'reportCount': newCount,
        'reportedBy': reportedBy,
        'isFlagged': shouldFlag,
        if (shouldFlag) 'moderationStatus': 'under_review',
      });

      // Audit Log
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'event': 'Post Reported',
        'postId': postId,
        'reason': reason,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> sendFriendRequest(String targetPurrCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('purrCode', isEqualTo: targetPurrCode)
        .limit(1)
        .get();

    if (targetQuery.docs.isEmpty) throw Exception("User not found");
    final targetUid = targetQuery.docs.first.id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('pending_requests')
        .doc(user.uid)
        .set({
      'fromUid': user.uid,
      'fromName': userName,
      'fromUsername': '@$userName', 
      'fromAvatar': avatarUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(FriendRequest req) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    batch.set(FirebaseFirestore.instance.collection('users').doc(user.uid).collection('friends').doc(req.fromUid), {
      'name': req.fromName,
      'username': req.fromUsername,
      'avatarUrl': req.fromAvatar,
      'uid': req.fromUid,
    });

    batch.set(FirebaseFirestore.instance.collection('users').doc(req.fromUid).collection('friends').doc(user.uid), {
      'name': userName,
      'username': '@$userName',
      'avatarUrl': avatarUrl ?? '',
      'uid': user.uid,
    });

    batch.delete(FirebaseFirestore.instance.collection('users').doc(user.uid).collection('pending_requests').doc(req.fromUid));

    await batch.commit();
    _updateRank(); // 🎯 Update rank after getting a new friend
  }

  // --- FEEDBACK ACTIONS ---

  Future<void> submitFeedback(Map<String, double> ratings, String comment) async {
    await FirebaseFirestore.instance.collection('feedbacks').add({
      'ratings': ratings,
      'comment': comment,
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- CAT ACTIONS ---

  Future<void> performFullCatRegistration({
    required Cat cat,
    required double initialWeight,
    File? imageFile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      String imageUrl = cat.image;

      // 1. Pro-Storage: Upload image to Firebase Storage if a file is provided
      if (imageFile != null && await imageFile.exists()) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('cat_profiles')
            .child('${cat.id}.jpg');
        
        await storageRef.putFile(imageFile);
        imageUrl = await storageRef.getDownloadURL();
      }

      // 2. Simpan data ke Firestore cats/{catId}
      await FirebaseFirestore.instance.collection('cats').doc(cat.id).set({
        'ownerId': user.uid,
        'collaborators': cat.collaborators,
        'name': cat.name,
        'breed': cat.breed,
        'gender': cat.gender,
        'themeColor': cat.themeColor.value,
        'image': imageUrl,
        'imageScale': cat.imageScale,
        'battery': cat.battery,
        'distance': cat.distance,
        'isLost': cat.isLost,
        'activeMinutes': cat.activeMinutes,
        'targetMinutes': cat.targetMinutes,
        'sleepHours': cat.sleepHours,
        'sleepQuality': cat.sleepQuality,
        'heartRate': cat.heartRate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Growth Records: Masukkan rekod berat awal
      await FirebaseFirestore.instance
          .collection('cats')
          .doc(cat.id)
          .collection('health_records')
          .add({
        'type': 'weight',
        'value': initialWeight,
        'unit': _isKg ? 'kg' : 'lbs',
        'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint("Error in full cat registration: $e");
      rethrow;
    }
  }

  Future<void> addCat(Cat cat) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('cats').doc(cat.id).set({
      'ownerId': user.uid,
      'collaborators': cat.collaborators,
      'name': cat.name,
      'breed': cat.breed,
      'gender': cat.gender,
      'themeColor': cat.themeColor.value,
      'image': cat.image,
      'imageScale': cat.imageScale,
      'battery': cat.battery,
      'distance': cat.distance,
      'isLost': cat.isLost,
      'activeMinutes': cat.activeMinutes,
      'targetMinutes': cat.targetMinutes,
      'sleepHours': cat.sleepHours,
      'sleepQuality': cat.sleepQuality,
      'heartRate': cat.heartRate,
    });
  }

  Future<void> updateCat(String catId, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Sila log masuk terlebih dahulu.");

      // Rules akan semak sama ada user.uid == ownerId dalam Firestore
      await FirebaseFirestore.instance.collection('cats').doc(catId).update(data);
      debugPrint("Update berjaya!");
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint("KESELAMATAN: Anda tidak mempunyai izin untuk mengemaskini profil kucing ini.");
        throw Exception("Akses Disekat: Anda bukan pemilik profil ini.");
      }
      rethrow;
    } catch (e) {
      debugPrint("Error: $e");
      rethrow;
    }
  }

  Future<void> updateCatStats(String catId, {int? activeMinutes, double? sleepHours, int? heartRate, double? battery, String? distance}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {
      if (activeMinutes != null) 'activeMinutes': activeMinutes,
      if (sleepHours != null) 'sleepHours': sleepHours,
      if (heartRate != null) 'heartRate': heartRate,
      if (battery != null) 'battery': battery,
      if (distance != null) 'distance': distance,
      'lastSync': FieldValue.serverTimestamp(),
    };

    // 1. Update the main cat document
    await FirebaseFirestore.instance.collection('cats').doc(catId).update(updates);

    // 2. Log daily activity if health stats are provided
    if (activeMinutes != null || sleepHours != null) {
      final today = DateTime.now();
      final dateStr = '${today.day}-${today.month}-${today.year}';
      
      await FirebaseFirestore.instance
          .collection('cats')
          .doc(catId)
          .collection('activity_logs')
          .doc(dateStr)
          .set({
        'activeMinutes': activeMinutes ?? 0,
        'sleepHours': sleepHours ?? 0.0,
        'heartRateAvg': heartRate ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteCat(String catId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Rules akan halang jika bukan ownerId yang delete
      await FirebaseFirestore.instance.collection('cats').doc(catId).delete();
      debugPrint("Kucing berjaya dipadam.");
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint("KESELAMATAN: Cubaan memadam data tanpa kebenaran dikesan.");
        throw Exception("Hanya pemilik asal boleh memadam profil ini.");
      }
      rethrow;
    }
  }

  Future<void> broadcastLostCat({
    required String catName,
    required double lat,
    required double lng,
    required String phone,
    String? imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('community_posts').add({
      'author': userName ?? 'User',
      'ownerId': user.uid,
      'title': 'LOST CAT: $catName',
      'content': 'Help! My cat $catName is missing. Last seen at the pinned location.',
      'category': 'Lost & found',
      'locationLabel': 'Last Seen Location',
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Lost',
      'isFlagged': false,
      'reportCount': 0,
      'reportedBy': [],
      'isVerified': false,
      'imageUrl': imageUrl,
    });

    _currentState = AppEventState.myCatLost;
    notifyListeners();

    // 🎯 Trigger notification for the owner (if enabled)
    if (notificationsEnabled && notifyEmergency) {
      NotificationService().showNotification(
        id: 999,
        title: "Kucing Hilang!",
        body: "Hebahan telah dihantar untuk $catName. Harap kucing anda segera dijumpai.",
      );
    }
  }

  void setMyCatLost() {
    _currentState = AppEventState.myCatLost;
    notifyListeners();

    // 🎯 Trigger notification for the owner (if enabled)
    if (notificationsEnabled && notifyEmergency) {
      NotificationService().showNotification(
        id: 999,
        title: "Kucing Hilang!",
        body: "Hebahan kecemasan telah dihantar. Harap kucing anda segera dijumpai.",
      );
    }
  }

  void addWeightRecord(String catId, double weight) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final date = DateTime.now();
    await FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('health_records')
        .add({
      'type': 'weight',
      'value': weight,
      'unit': _isKg ? 'kg' : 'lbs',
      'date': '${date.day}/${date.month}/${date.year}',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void loadWeightHistory(String catId) {
    FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('health_records')
        .where('type', isEqualTo: 'weight')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      catHealthRecords[catId] = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    });
  }

  // --- APPOINTMENT ACTIONS ---

  void addAppointment(Appointment appt) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance.collection('appointments').doc(appt.id.toString()).set({
        'id': appt.id,
        'uid': user.uid, // SANGAT PENTING: Untuk disemak oleh Security Rules
        'catName': appt.catName,
        'type': appt.type,
        'scheduledAt': Timestamp.fromDate(appt.scheduledAt),
        'location': appt.location,
        'description': appt.description,
        'notifyBefore': appt.notifyBefore,
        'notificationDate': appt.notificationDate != null ? Timestamp.fromDate(appt.notificationDate!) : null,
        'lat': appt.lat,
        'lng': appt.lng,
        'imageUrl': appt.imageUrl,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint("KESELAMATAN: Gagal menambah temujanji. Akses disekat.");
      }
    }
  }

  void removeAppointment(Appointment appt) async {
    await FirebaseFirestore.instance.collection('appointments').doc(appt.id.toString()).delete();
  }

  void updateAppointment(Appointment oldAppt, Appointment newAppt) async {
    await FirebaseFirestore.instance.collection('appointments').doc(oldAppt.id.toString()).update({
      'catName': newAppt.catName,
      'type': newAppt.type,
      'scheduledAt': Timestamp.fromDate(newAppt.scheduledAt),
      'location': newAppt.location,
      'description': newAppt.description,
      'notifyBefore': newAppt.notifyBefore,
      'notificationDate': newAppt.notificationDate != null ? Timestamp.fromDate(newAppt.notificationDate!) : null,
      'lat': newAppt.lat,
      'lng': newAppt.lng,
      'imageUrl': newAppt.imageUrl,
    });
  }

  // --- AI CHAT ACTIONS ---

  Future<void> createNewChatSession({String title = 'New Chat'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_history')
        .add({
      'title': title,
      'lastUpdated': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final newSession = ChatSession(
      id: docRef.id,
      title: title,
      messages: [],
    );
    
    activeSession = newSession;
    notifyListeners();
  }

  void setActiveSession(ChatSession session) {
    activeSession = session;
    notifyListeners();
  }

  Future<void> addMessageToActiveSession(String text, bool isMe, {String? imagePath}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (activeSession == null) {
      await createNewChatSession(title: text.length > 20 ? '${text.substring(0, 20)}...' : text);
    }
    
    final sessionId = activeSession!.id;

    // Add locally for instant UI update
    activeSession!.messages.add(ChatMessage(
      text: text, 
      isMe: isMe, 
      timestamp: DateTime.now(), 
      imagePath: imagePath
    ));
    notifyListeners();

    // Persist to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_history')
        .doc(sessionId)
        .collection('messages')
        .add({
      'text': text,
      'isMe': isMe,
      'imagePath': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 🎯 Trigger notification for AI reply (if enabled)
    if (!isMe && notificationsEnabled && notifyChat) {
      NotificationService().showNotification(
        id: sessionId.hashCode,
        title: "Meow AI",
        body: text,
      );
    }

    // Update session timestamp
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_history')
        .doc(sessionId)
        .update({'lastUpdated': FieldValue.serverTimestamp()});
  }

  void _checkStreakReset() {
    if (lastStreakDate == null) return;
    final now = DateTime.now();
    final diff = now.difference(lastStreakDate!).inDays;
    if (diff > 1) {
      pawStreak = 0;
      // Reset tasks if it's a new day
      for (var t in dailyTasks) { t['done'] = false; }
    } else if (diff == 1) {
      // It's exactly the next day, reset tasks but keep streak until they complete them
      // We'll reset tasks when the day changes
      for (var t in dailyTasks) { t['done'] = false; }
    }
  }

  Future<void> toggleDailyTask(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    dailyTasks[index]['done'] = !dailyTasks[index]['done'];
    
    // Check if all tasks done for today
    bool allDone = dailyTasks.every((t) => t['done'] == true);
    if (allDone) {
      final now = DateTime.now();
      if (lastStreakDate == null || now.difference(lastStreakDate!).inDays >= 1) {
        pawStreak++;
        lastStreakDate = now;
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'pawStreak': pawStreak,
          'lastStreakDate': FieldValue.serverTimestamp(),
        });

        // 🎯 Notification for streak achievement
        if (notificationsEnabled && notifyDailyCare) {
          NotificationService().showNotification(
            id: 888,
            title: "Tahniah! Streak Bertambah",
            body: "Anda telah menyelesaikan semua tugasan hari ini. Streak anda kini $pawStreak!",
          );
        }
      }
    }
    notifyListeners();
  }

  void setSessionRole(String role) {
    sessionRole = role;
    notifyListeners();
  }
}

final appState = AppStateController();
