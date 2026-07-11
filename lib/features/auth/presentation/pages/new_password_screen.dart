import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE8DBFB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 80),
                _buildLabel('Enter New Password'),
                _buildTextField(
                  hintText: 'Password',
                  icon: 'assets/icons/Password.svg',
                  isPassword: true,
                ),
                const SizedBox(height: 5),
                // Password Strength Indicator
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(height: 6, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(3))),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 2,
                      child: Container(height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password is too weak',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel('Confirm Password'),
                _buildTextField(
                  hintText: 'Confirm Password',
                  icon: 'assets/icons/Confirm Password.svg',
                  isPassword: true,
                  isCheck: true,
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create New Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
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

  Widget _buildTextField({required String hintText, required Object icon, bool isPassword = false, bool isCheck = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixIcon: (isCheck)
              ? Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF985BEF).withValues(alpha: 0.5))
              : ((icon is String)
                  ? SvgPicture.asset(icon, color: const Color(0xFF985BEF).withValues(alpha: 0.5), width: 22, height: 22)
                  : Icon(icon as IconData, color: const Color(0xFF985BEF).withValues(alpha: 0.5))),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
