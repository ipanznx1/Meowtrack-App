import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF985BEF), Colors.white, Colors.white],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to continue your cat\'s care.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 60),
                _buildLabel('Email / Username'),
                _buildTextField(
                  hintText: 'Email / Username',
                  icon: 'assets/icons/Email.svg',
                ),
                const SizedBox(height: 20),
                _buildLabel('Password'),
                _buildTextField(
                  hintText: 'Password',
                  icon: 'assets/icons/Password.svg',
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                          activeColor: const Color(0xFF985BEF),
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Color(0xFF985BEF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.push('/verify-number'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF985BEF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hintText, required Object icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(14.0), // Increased padding to make icon smaller
            child: (icon is String)
                ? SvgPicture.asset(icon, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 18, height: 18)
                : Icon(icon as IconData, color: const Color(0xFF985BEF), size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
