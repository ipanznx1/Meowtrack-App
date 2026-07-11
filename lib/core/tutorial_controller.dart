import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class TutorialController extends ChangeNotifier {
  static const String _tutorialCompletedKey = 'tutorial_completed_v1';
  
  bool _isTutorialCompleted = false;
  bool get isTutorialCompleted => _isTutorialCompleted;

  // Global Keys for Dashboard
  final GlobalKey addCatKey = GlobalKey();
  final GlobalKey communityFeedKey = GlobalKey();
  
  // Global Keys for Add Cat Screen
  final GlobalKey catNameKey = GlobalKey();
  final GlobalKey saveProfileKey = GlobalKey();

  TutorialController() {
    _loadTutorialStatus();
  }

  Future<void> _loadTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isTutorialCompleted = prefs.getBool(_tutorialCompletedKey) ?? false;
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    _isTutorialCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    _isTutorialCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, false);
    notifyListeners();
  }

  // Alur 1: Start Dashboard Tutorial
  void startDashboardTutorial(BuildContext context) {
    if (!_isTutorialCompleted) {
      ShowCaseWidget.of(context).startShowCase([addCatKey]);
    }
  }

  // Alur 2: Start Add Cat Tutorial
  void startAddCatTutorial(BuildContext context) {
    if (!_isTutorialCompleted) {
      ShowCaseWidget.of(context).startShowCase([catNameKey, saveProfileKey]);
    }
  }

  // Alur 3: Final Dashboard Tutorial
  void startFinalTutorial(BuildContext context) {
    if (!_isTutorialCompleted) {
      ShowCaseWidget.of(context).startShowCase([communityFeedKey]);
    }
  }
}
