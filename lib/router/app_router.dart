import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meow_track/features/onboarding/presentation/pages/intro_screen.dart';
import 'package:meow_track/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:meow_track/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/auth_gateway_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/login_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/signup_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/verification_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/verify_number_screen.dart';
import 'package:meow_track/features/auth/presentation/pages/new_password_screen.dart';
import 'package:meow_track/features/gps_tracking/presentation/pages/gps_tracking_page.dart';
import 'package:meow_track/features/vet_directory/presentation/pages/vet_clinic_details_page.dart';
import 'package:meow_track/features/vet_directory/presentation/pages/vet_directory_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/owner_profile_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/purrmates_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/purrmates_select_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/purrmate_profile_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/owner_chat_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/household_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/account_settings_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/about_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/preferences_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/feedback_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/notification_page.dart';
import 'package:meow_track/features/ar_scan/presentation/pages/ar_scan_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/cat_profile_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/add_cat_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/report_lost_cat_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/health_overview_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/medical_history_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/document_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/gallery_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/notes_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/add_note_page.dart';
import 'package:meow_track/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:meow_track/features/reminders/presentation/pages/add_appointment_screen.dart';
import 'package:meow_track/features/reminders/presentation/pages/appointment_details_screen.dart';
import 'package:meow_track/router/main_scaffold.dart';
import 'package:meow_track/core/app_state.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authGateway = '/auth-gateway';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String verifyNumber = '/verify-number';
  static const String createNewPassword = '/create-new-password';

  static const String dashboard = '/dashboard';
  static const String gpsTracking = '/gps-tracking';
  static const String vetDirectory = '/vet-directory';
  static const String ownerProfile = '/owner-profile';
  static const String vetClinicDetails = '/vet-clinic-details';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const IntroScreen()),
      GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: authGateway, builder: (context, state) => const AuthGatewayScreen()),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: signup, builder: (context, state) => const SignupScreen()),
      GoRoute(path: forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: verifyOtp, builder: (context, state) => const VerificationScreen()),
      GoRoute(path: verifyNumber, builder: (context, state) => const VerifyNumberScreen()),
      GoRoute(path: createNewPassword, builder: (context, state) => const NewPasswordScreen()),
      
      // Core Screens with persistent Bottom Navigation Bar
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: dashboard, builder: (context, state) => const DashboardPage()),
          GoRoute(path: gpsTracking, builder: (context, state) => const GpsTrackingPage()),
          GoRoute(path: vetDirectory, builder: (context, state) => const VetDirectoryPage()),
          GoRoute(path: ownerProfile, builder: (context, state) => const OwnerProfilePage()),
        ],
      ),

      GoRoute(
        path: vetClinicDetails,
        builder: (context, state) => VetClinicDetailsPage(clinic: state.extra as VetClinic),
      ),

      // Social & Household Routes
      GoRoute(path: '/purrmates', builder: (context, state) => const PurrmatesPage()),
      GoRoute(path: '/purrmates-select', builder: (context, state) => PurrmatesSelectPage()),
      GoRoute(path: '/purrmate-profile', builder: (context, state) => PurrmateProfilePage(purrmate: state.extra as Purrmate)),
      GoRoute(path: '/owner-chat', builder: (context, state) => OwnerChatPage(ownerName: state.extra as String)),
      GoRoute(path: '/household', builder: (context, state) => const HouseholdPage()),
      GoRoute(path: '/account-settings', builder: (context, state) => const AccountSettingsPage()),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      GoRoute(path: '/feedback', builder: (context, state) => const FeedbackPage()),
      GoRoute(path: '/notification', builder: (context, state) => const NotificationPage()),

      // Preferences Routes
      GoRoute(path: '/preferences', builder: (context, state) => const PreferencesPage()),
      GoRoute(path: '/preferences/safe-zone', builder: (context, state) => const SafeZoneRadiusPage()),
      GoRoute(path: '/preferences/tracking-freq', builder: (context, state) => const TrackingFrequencyPage()),
      GoRoute(path: '/preferences/privacy', builder: (context, state) => const MyPrivacyPage()),

      GoRoute(
        path: '/cat-profile',
        builder: (context, state) => CatProfilePage(cat: state.extra as Cat),
      ),
      GoRoute(
        path: '/health-overview',
        builder: (context, state) => HealthOverviewPage(cat: state.extra as Cat),
      ),
      GoRoute(
        path: '/medical-history',
        builder: (context, state) => MedicalHistoryPage(
          cat: (state.extra as Map<String, dynamic>)['cat'] as Cat,
          diagnosis: (state.extra as Map<String, dynamic>)['diagnosis'] as String,
        ),
      ),
      GoRoute(
        path: '/documentation',
        builder: (context, state) => DocumentPage(cat: state.extra as Cat),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => GalleryPage(cat: state.extra as Cat),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => NotesPage(cat: state.extra as Cat),
      ),
      GoRoute(
        path: '/add-note',
        builder: (context, state) => AddNotePage(cat: state.extra as Cat),
      ),
      GoRoute(path: '/add-cat-1', builder: (context, state) => const AddCatIdentityScreen()),
      GoRoute(
        path: '/add-cat-2',
        builder: (context, state) => AddCatHealthScreen(identityData: state.extra as Map<String, dynamic>),
      ),
      GoRoute(path: '/report-lost', builder: (context, state) => const ReportLostCatScreen()),
      GoRoute(path: '/ai-chat', builder: (context, state) => const AiChatScreen()),
      GoRoute(path: '/reminders', builder: (context, state) => const AddAppointmentScreen()),
      GoRoute(
        path: '/appointment-details',
        builder: (context, state) => AppointmentDetailsScreen(appointment: state.extra as Appointment),
      ),
      GoRoute(path: '/ar-scan', builder: (context, state) => const ArScanPage()),
    ],
  );
}
