import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meow_track/router/app_router.dart';
import 'package:meow_track/core/app_state.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // 🎯 1. PENGURUS KOTAK INPUT (Optional for email flow, but keeping UI same)
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _hasError = false;

  // 🎯 2. ENGIN COUNTDOWN RESEND
  Timer? _timer;
  int _startSeconds = 60;
  bool _isResendAvailable = false;

  // 🎯 3. EMAIL VERIFICATION TIMER
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _startTimer(); // Resend timer
    _startEmailVerificationCheck(); // Auto-check if verified
    
    // Jika sudah verified tapi peranan belum pilih, tunjuk dialog terus
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        final nextRoute = await appState.resolvePostLoginRoute();
        if (nextRoute == '/verify-otp') {
          if (mounted) _showRoleSelectionDialog();
        } else if (nextRoute != '/verify-otp' && nextRoute != '/auth-gateway') {
          if (mounted) context.go(nextRoute);
        }
      }
    });
  }

  void _startTimer() {
    setState(() {
      _startSeconds = 60;
      _isResendAvailable = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds == 0) {
        setState(() {
          _isResendAvailable = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _startSeconds--;
        });
      }
    });
  }

  // 🎯 AUTO CHECK LOGIC
  void _startEmailVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        await user.reload(); // Refresh user data from Firebase

        if (user.emailVerified) {
          timer.cancel();
          _handlePostVerification();
        }
      }
    });
  }

  Future<void> _handlePostVerification() async {
    final nextRoute = await appState.resolvePostLoginRoute();
    if (nextRoute == '/verify-otp') {
      if (mounted) _showRoleSelectionDialog();
    } else {
      if (mounted) context.go(nextRoute);
    }
  }

  void _showRoleSelectionDialog() {
    final bool hasAdmin = appState.availableRoles.contains('admin');
    // Admin secara automatik boleh akses User Dashboard
    final bool hasUser = appState.availableRoles.contains('user') || hasAdmin;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pilih Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Sila pilih dashboard untuk memulakan sesi:"),
        actions: [
          if (hasUser)
            TextButton(
              onPressed: () async {
                appState.setSessionRole('user');
                Navigator.pop(ctx);
                final nextRoute = await appState.resolvePostLoginRoute();
                if (mounted) context.go(nextRoute);
              },
              child: const Text("User Dashboard", style: TextStyle(color: Colors.grey)),
            ),
          if (hasAdmin)
            ElevatedButton(
              onPressed: () async {
                appState.setSessionRole('admin');
                Navigator.pop(ctx);
                final nextRoute = await appState.resolvePostLoginRoute();
                if (mounted) context.go(nextRoute);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
              child: const Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _resendCode() async {
    if (!_isResendAvailable) return;

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email has been resent.')),
        );
      }
      
      _startTimer(); // Restart 60s countdown
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend. Please try again later.')),
        );
      }
    }
  }

  void _verifyOtp() async {
    // For real email verification, the user clicks a link. 
    // This button can be used for "Manual Refresh" check.
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      _handlePostVerification();
    } else {
      setState(() => _hasError = true); // Shows "Invalid" or "Not verified yet"
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _verificationCheckTimer?.cancel();
    for (var controller in _controllers) { controller.dispose(); }
    for (var node in _focusNodes) { node.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "[Your Email]";
    final bool isVerifiedButNeedsRole = FirebaseAuth.instance.currentUser?.emailVerified == true && appState.needsRoleSelection;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF985BEF), Colors.white, Colors.white],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  isVerifiedButNeedsRole ? 'Account Ready' : 'Verification',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isVerifiedButNeedsRole 
                      ? 'Email verified! Please select your preferred dashboard access.'
                      : 'We\'ve sent a verification link to $userEmail. Please check your inbox and click the link to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 60),
                if (!isVerifiedButNeedsRole) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Checking status...',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF985BEF)),
                      const SizedBox(width: 20),
                      Text("Waiting for verification...", style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ] else ...[
                   const Icon(Icons.check_circle, color: Colors.green, size: 80),
                   const SizedBox(height: 20),
                   const Text("Status: Verified", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
                
                  const SizedBox(height: 60),
                if (!isVerifiedButNeedsRole) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tips: Sila semak folder SPAM jika emel pengesahan tidak dijumpai di Inbox.',
                            style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('If you didn\'t receive the email, ', style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: _isResendAvailable ? _resendCode : null,
                        child: Text(
                          _isResendAvailable ? 'Resend' : 'Resend (${_startSeconds}s)',
                          style: TextStyle(
                              color: _isResendAvailable ? const Color(0xFF985BEF) : Colors.grey,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 15),

                if (_hasError)
                  const Text(
                    'Email not verified yet. Please click the link in your email.',
                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  ),

                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: isVerifiedButNeedsRole ? _showRoleSelectionDialog : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isVerifiedButNeedsRole ? 'Select Role' : 'Check Verification Status',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go(AppRouter.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to sign in',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
