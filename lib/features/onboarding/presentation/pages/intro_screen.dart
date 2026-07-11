import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

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
    // Tunggu 4 saat untuk tunjuk animasi logo
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.go('/onboarding');
    }
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
          
          // 2. LOTTIE ANIMATION
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
