import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meow_track/features/onboarding/presentation/pages/intro_screen.dart';
import 'package:meow_track/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:meow_track/features/dashboard/presentation/pages/community_hub_page.dart';
import 'package:meow_track/features/dashboard/presentation/pages/insurance_hub_page.dart';
import 'package:meow_track/features/dashboard/presentation/pages/create_post_screen.dart';
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
import 'package:meow_track/features/owner_profile/presentation/pages/privacy_policy_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/terms_conditions_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/preferences_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/feedback_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/notification_page.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/qr_tag_screen.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/user_profile_edit_screen.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/user_profile_setup_screen.dart';
import 'package:meow_track/features/ar_scan/presentation/pages/ar_scan_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/cat_profile_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/edit_cat_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/add_cat_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/report_lost_cat_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/health_overview_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/medical_history_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/document_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/gallery_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/notes_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/add_note_page.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/cat_stats_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/medical_records_screen.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/kibble_tracker_screen.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/budget_tracker_screen.dart';
import 'package:meow_track/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:meow_track/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:meow_track/features/admin/presentation/pages/user_detail_screen.dart';
import 'package:meow_track/features/reminders/presentation/pages/add_appointment_screen.dart';
import 'package:meow_track/features/reminders/presentation/pages/appointment_details_screen.dart';
import 'package:meow_track/features/reminders/presentation/pages/appointment_list_screen.dart';
import 'package:meow_track/features/reminders/presentation/pages/edit_appointment_screen.dart';
import 'package:meow_track/router/main_scaffold.dart';
import 'package:meow_track/core/app_state.dart';

// NEW WEB DASHBOARDS
import 'package:meow_track/features/admin/presentation/pages/moderator_platform_dashboard.dart';
import 'package:meow_track/features/admin/presentation/pages/vet_clinic_multi_role_dashboard.dart';

import 'package:meow_track/features/cat_profile/presentation/pages/cat_health_passport_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authGateway = '/auth-gateway';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String verifyNumber = '/verify-number';
  static const String verifyEmail = '/verify-email';
  static const String createNewPassword = '/create-new-password';

  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String communityHub = '/community-hub';
  static const String insuranceHub = '/insurance-hub';
  static const String gpsTracking = '/gps-tracking';
  static const String vetDirectory = '/vet-directory';
  static const String ownerProfile = '/owner-profile';
  static const String vetClinicDetails = '/vet-clinic-details';
  static const String preferences = '/preferences';

  // WEB CONSTANTS
  static const String moderatorHQ = '/moderator-hq';
  static const String vetPortal = '/vet-portal';

  static Cat? _findCat(String? id, Object? extra) {
    if (extra is Cat) return extra;
    if (id == null) return null;
    try {
      return appState.cats.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    refreshListenable: appState,
    redirect: (context, state) {
      final loggedIn = appState.isAuthenticated;
      final emailVerified = appState.isEmailVerified;
      final currentLocation = state.uri.path;
      
      // BANTUAN WEB: Benarkan akses terus ke dashboard HQ/Vet tanpa login untuk tujuan testing
      if (currentLocation == moderatorHQ || currentLocation == vetPortal) return null;

      final goingToAuth = [splash, onboarding, authGateway, login, signup, forgotPassword, verifyOtp, verifyNumber, createNewPassword].contains(currentLocation);
      final isVerifying = currentLocation == verifyOtp;
      
      final goingToCore = [dashboard, communityHub, gpsTracking, vetDirectory, ownerProfile, insuranceHub, preferences].contains(currentLocation) || currentLocation.startsWith('/purrmates') || currentLocation.startsWith('/preferences') || currentLocation.startsWith('/cat-profile') || currentLocation.startsWith('/cat-stats') || currentLocation.startsWith('/medical-records') || currentLocation.startsWith('/health-overview') || currentLocation.startsWith('/medical-history') || currentLocation.startsWith('/documentation') || currentLocation.startsWith('/gallery') || currentLocation.startsWith('/notes') || currentLocation.startsWith('/add-note') || currentLocation.startsWith('/add-cat') || currentLocation.startsWith('/report-lost') || currentLocation.startsWith('/create-post') || currentLocation.startsWith('/ai-chat') || currentLocation.startsWith('/add-appointment') || currentLocation.startsWith('/edit-appointment') || currentLocation.startsWith('/appointment-list') || currentLocation.startsWith('/appointment-details') || currentLocation.startsWith('/ar-scan') || currentLocation.startsWith('/owner-chat') || currentLocation.startsWith('/household') || currentLocation.startsWith('/account-settings') || currentLocation.startsWith('/user-profile-edit') || currentLocation.startsWith('/about') || currentLocation.startsWith('/feedback') || currentLocation.startsWith('/notification');

      if (!loggedIn && goingToCore) return authGateway;

      if (loggedIn) {
        if (!emailVerified && !isVerifying) return verifyOtp;
        if (emailVerified && appState.needsRoleSelection && currentLocation != verifyOtp) return verifyOtp;
        if (emailVerified && appState.needsRoleSelection && currentLocation == verifyOtp) return null;
        if (emailVerified && !appState.isProfileSetup && currentLocation != '/profile-setup') return '/profile-setup';

        if (emailVerified && appState.isProfileSetup && (currentLocation == splash || currentLocation == onboarding)) {
          if (appState.needsRoleSelection) return verifyOtp; // Paksa pilih role dlu
          final role = appState.sessionRole ?? 'user';
          return role == 'admin' ? adminDashboard : dashboard;
        }

        if (goingToAuth && emailVerified && appState.isProfileSetup) {
          if (appState.needsRoleSelection) return verifyOtp; // Paksa pilih role dlu
          final role = appState.sessionRole ?? 'user';
          return role == 'admin' ? adminDashboard : dashboard;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: splash, builder: (context, state) => const IntroScreen()),
      GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: authGateway, builder: (context, state) => const AuthGatewayScreen()),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: signup, builder: (context, state) => const SignupScreen()),
      GoRoute(path: forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: verifyOtp, builder: (context, state) => const VerificationScreen()),
      GoRoute(path: verifyNumber, builder: (context, state) => const VerifyNumberScreen()),
      GoRoute(path: verifyEmail, builder: (context, state) => const VerifyNumberScreen()),
      GoRoute(path: createNewPassword, builder: (context, state) => const NewPasswordScreen()),
      GoRoute(path: adminDashboard, builder: (context, state) => const AdminDashboardScreen()),
      
      // NEW WEB ROUTES
      GoRoute(path: moderatorHQ, builder: (context, state) => const ModeratorPlatformDashboard()),
      GoRoute(path: vetPortal, builder: (context, state) => const VetClinicMultiRoleDashboard()),

      GoRoute(
        path: '/admin/user-detail/:uid',
        builder: (context, state) => UserDetailScreen(userId: state.pathParameters['uid'] ?? ''),
      ),
      
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: dashboard, builder: (context, state) => const DashboardPage()),
          GoRoute(path: communityHub, builder: (context, state) => const CommunityHubPage()),
          GoRoute(path: insuranceHub, builder: (context, state) => const InsuranceHubPage()),
          GoRoute(path: gpsTracking, builder: (context, state) => const GpsTrackingPage()),
          GoRoute(path: vetDirectory, builder: (context, state) => const VetDirectoryPage()),
          GoRoute(path: ownerProfile, builder: (context, state) => const OwnerProfilePage()),
        ],
      ),

      GoRoute(
        path: vetClinicDetails,
        builder: (context, state) {
          final clinic = state.extra as VetClinic?;
          if (clinic == null) return const Scaffold(body: Center(child: Text('Clinic data missing')));
          return VetClinicDetailsPage(clinic: clinic);
        },
      ),

      GoRoute(path: '/purrmates', builder: (context, state) => const PurrmatesPage()),
      GoRoute(path: '/purrmates-select', builder: (context, state) => PurrmatesSelectPage()),
      GoRoute(path: '/owner-chat', builder: (context, state) => OwnerChatPage(ownerName: state.extra as String? ?? 'User')),
      GoRoute(path: '/household', builder: (context, state) => const HouseholdPage()),
      GoRoute(path: '/account-settings', builder: (context, state) => const AccountSettingsPage()),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      GoRoute(path: '/feedback', builder: (context, state) => const FeedbackPage()),
      GoRoute(path: '/notification', builder: (context, state) => const NotificationPage()),
      GoRoute(path: '/preferences/notifications', builder: (context, state) => const NotificationPage()),
      GoRoute(path: '/qr-tag', builder: (context, state) => const QrTagScreen()),
      GoRoute(path: '/profile-setup', builder: (context, state) => UserProfileSetupScreen(isEditing: state.extra as bool? ?? false)),

      // --- PREFERENCES ROUTES ---
      GoRoute(path: preferences, builder: (context, state) => const PreferencesPage()),
      GoRoute(path: '/preferences/safe-zone', builder: (context, state) => const SafeZoneRadiusPage()),
      GoRoute(path: '/preferences/tracking-freq', builder: (context, state) => const TrackingFrequencyPage()),
      // GoRoute(path: '/preferences/notifications', builder: (context, state) => const NotificationSettingsPage()),
      GoRoute(path: '/preferences/privacy', builder: (context, state) => const MyPrivacyPage()),

      // --- CAT ROUTES DENGAN ID ---
      GoRoute(
        path: '/cat-profile/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing. Please go back to Dashboard.')));
          return CatProfilePage(cat: cat);
        },
      ),
      GoRoute(
        path: '/edit-cat/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing')));
          return EditCatScreen(cat: cat);
        },
      ),
      GoRoute(
        path: '/health-overview/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) {
             return const Scaffold(body: Center(child: Text('Cat data missing. Please go back.')));
          }
          return HealthOverviewPage(cat: cat);
        },
      ),
      GoRoute(
        path: '/medical-history/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing')));
          return CatHealthPassportScreen(cat: cat);
        },
      ),
      GoRoute(
        path: '/documentation/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing')));
          return DocumentPage(cat: cat);
        },
      ),
      GoRoute(
        path: '/gallery/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing')));
          return GalleryPage(cat: cat);
        },
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing')));
          return NotesPage(cat: cat);
        },
      ),
      GoRoute(
        path: '/notes/:id/add',
        builder: (context, state) {
          final cat = _findCat(state.pathParameters['id'], state.extra);
          if (cat == null) return const Scaffold(body: Center(child: Text('Cat data missing')));
          return AddNotePage(cat: cat);
        },
      ),

      GoRoute(path: '/add-cat-1', builder: (context, state) => const AddCatIdentityScreen()),
      GoRoute(path: '/add-cat-2', builder: (context, state) => AddCatHealthScreen(identityData: state.extra as Map<String, dynamic>)),
      GoRoute(path: '/kibble-tracker', builder: (context, state) => const KibbleTrackerScreen()),
      GoRoute(path: '/budget-tracker', builder: (context, state) => const BudgetTrackerScreen()),
      GoRoute(path: '/report-lost', builder: (context, state) => const ReportLostCatScreen()),
      GoRoute(path: '/create-post', builder: (context, state) => const CreatePostScreen()),
      GoRoute(path: '/ai-chat', builder: (context, state) => const AiChatScreen()),
      GoRoute(path: '/appointment-list', builder: (context, state) => const AppointmentListScreen()),
      GoRoute(path: '/add-appointment', builder: (context, state) => AddAppointmentScreen(prefillData: state.extra as Map<String, dynamic>?)),
      GoRoute(
        path: '/edit-appointment',
        builder: (context, state) {
          final appt = state.extra as Appointment?;
          if (appt == null) return const Scaffold(body: Center(child: Text('Appointment data missing')));
          return EditAppointmentScreen(appointment: appt);
        },
      ),
      GoRoute(
        path: '/appointment-details',
        builder: (context, state) {
          final appt = state.extra as Appointment?;
          if (appt == null) return const Scaffold(body: Center(child: Text('Appointment data missing')));
          return AppointmentDetailsScreen(appointment: appt);
        },
      ),
      GoRoute(path: '/ar-scan', builder: (context, state) => const ArScanPage()),
    ],
  );
}
