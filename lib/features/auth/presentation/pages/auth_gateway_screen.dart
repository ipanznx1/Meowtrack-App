import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGatewayScreen extends StatelessWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Main Logo (Cat with Stethoscope)
              Image.asset(
                'assets/images/app_icon.png',
                height: 250,
                width: 250,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.pets,
                  size: 200,
                  color: Color(0xFF985BEF),
                ),
              ),
              const SizedBox(height: 40),
              // Headline
              const Text(
                'Better lives for our feline friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Subtext
              Text(
                'Join us today and start tracking your cat\'s health, habits, and happiness in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Get Started Button
              ElevatedButton(
                onPressed: () => context.push('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sign In Button
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEBEBEB),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF985BEF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
