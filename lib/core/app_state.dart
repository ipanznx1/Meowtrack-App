import 'package:flutter/material.dart';

enum AppEventState { normal, emergencyNearby, myCatLost }

class Cat {
  final String name;
  final String breed;
  final String gender;
  final Color themeColor;
  final String image;
  final double imageScale; // New field for manual adjustment
  double battery;
  String distance;

  Cat({
    required this.name,
    required this.breed,
    required this.gender,
    required this.themeColor,
    required this.image,
    this.imageScale = 1.0, // Default to original size
    this.battery = 50.0,
    this.distance = '200m away',
  });
}

class Appointment {
  final String catName;
  final String type;
  final String date;
  final String time;
  final String location;
  final String description;

  Appointment({
    required this.catName,
    required this.type,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
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

  ChatMessage({required this.text, required this.isMe, required this.timestamp});
}

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});
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
  });
}

class AppStateController extends ChangeNotifier {
  AppEventState _currentState = AppEventState.normal;
  AppEventState get currentState => _currentState;

  // Chat History State
  List<ChatSession> chatHistory = [
    ChatSession(
      id: '1',
      title: "Oyen's Diet Plan",
      messages: [
        ChatMessage(text: "What should I feed Oyen?", isMe: true, timestamp: DateTime.now()),
        ChatMessage(text: "Based on Oyen's weight, high protein kibbles are best.", isMe: false, timestamp: DateTime.now()),
      ],
    ),
    ChatSession(
      id: '2',
      title: "Vaccine Deadlines 2026",
      messages: [
        ChatMessage(text: "When is the next vaccine?", isMe: true, timestamp: DateTime.now()),
        ChatMessage(text: "Luna is due for FVRCP on 21 Dec 2026.", isMe: false, timestamp: DateTime.now()),
      ],
    ),
  ];

  ChatSession? activeSession;

  void setActiveSession(ChatSession session) {
    activeSession = session;
    notifyListeners();
  }

  void addMessageToActiveSession(String text, bool isMe) {
    if (activeSession != null) {
      activeSession!.messages.add(ChatMessage(text: text, isMe: isMe, timestamp: DateTime.now()));
      notifyListeners();
    }
  }

  // Map to store notes per cat name
  Map<String, List<CatNote>> catNotes = {
    'Luna': [
      CatNote(title: 'Checkup', content: 'Normal checkup', date: 'Today', icon: Icons.local_hospital_outlined),
      CatNote(title: 'Food', content: 'Bought new kibbles', date: 'Today', icon: Icons.restaurant_menu),
    ],
    'Oyen': [
      CatNote(title: 'Medical', content: 'Fever treatment', date: 'Today', icon: Icons.favorite_border_rounded),
      CatNote(title: 'Warning', content: 'Aggressive today', date: 'Today', icon: Icons.warning_amber_rounded),
    ],
  };

  void addNote(String catName, CatNote note) {
    if (!catNotes.containsKey(catName)) {
      catNotes[catName] = [];
    }
    catNotes[catName]!.insert(0, note);
    notifyListeners();
  }

  List<Cat> cats = [
    Cat(name: 'Luna', breed: 'British Shorthair', gender: 'Female', themeColor: const Color(0xFFD0E0FF), image: 'assets/images/Luna.png', imageScale: 1.0),
    Cat(name: 'Oyen', breed: 'Domestic Long Hair', gender: 'Male', themeColor: const Color(0xFFFFD5A1), image: 'assets/images/Oyen.png', imageScale: 1.2),
    Cat(name: 'Bella', breed: 'Persian', gender: 'Female', themeColor: const Color(0xFFFFF4CC), image: 'assets/images/Bella.png', imageScale: 1.4),
    Cat(name: 'Tuteh', breed: 'Domestic Shorthair', gender: 'Male', themeColor: const Color(0xFFFFC0CB), image: 'assets/images/Tuteh.png', imageScale: 1.0),
  ];

  List<Appointment> appointments = [
    Appointment(
      catName: 'Harry',
      type: 'Annual Vaccination',
      date: '12 June 2026',
      time: '10:30 AM',
      location: 'Global Pets Clinic, Kuala Lumpur',
      description: 'Annual booster for FVRCP. Remember to bring the medical card!',
    ),
  ];

  void setEmergencyNearby() {
    _currentState = AppEventState.emergencyNearby;
    notifyListeners();
  }

  void setMyCatLost() {
    _currentState = AppEventState.myCatLost;
    notifyListeners();
  }

  void setNormal() {
    _currentState = AppEventState.normal;
    notifyListeners();
  }

  void addCat(Cat cat) {
    cats.add(cat);
    notifyListeners();
  }

  void addAppointment(Appointment appt) {
    appointments.add(appt);
    notifyListeners();
  }

  void removeAppointment(Appointment appt) {
    appointments.remove(appt);
    notifyListeners();
  }

  void updateAppointment(Appointment oldAppt, Appointment newAppt) {
    int index = appointments.indexOf(oldAppt);
    if (index != -1) {
      appointments[index] = newAppt;
      notifyListeners();
    }
  }
}

// Global instance for the sake of this architectural demo
final appState = AppStateController();
