import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/router/app_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      appState.login(email: user.email ?? '', password: '');
      final route = await appState.resolvePostLoginRoute();
      if (mounted) context.go(route);
      return;
    }

    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. GRADIENT BACKGROUND (Sama macam Onboarding - Image 5, 6, 7)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF985BEF), Colors.white],
                  stops: [0.0, 0.45],
                ),
              ),
            ),
          ),
          
          // 2. LOTTIE ANIMATION & SUPPORTED BY
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Transform.scale(
                  scale: 1.2,
                  child: Lottie.asset(
                    'assets/animations/Meowtrack logo animate.json',
                    width: 300,
                    repeat: false,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                // SUPPORTED BY SECTION
                Column(
                  children: [
                    Text(
                      "Supported by :",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/images/department_of_veterinary_1x.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Department of Veterinary Services",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
