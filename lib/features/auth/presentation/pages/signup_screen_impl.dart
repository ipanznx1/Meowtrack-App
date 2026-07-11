import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/router/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _agreeToTerms = false;

  // Set default Malaysia
  Country _selectedCountry = Country(
    phoneCode: '60',
    countryCode: 'MY',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Malaysia',
    example: 'Malaysia',
    displayName: 'Malaysia',
    displayNameNoCountryCode: 'Malaysia',
    e164Key: '',
  );

  late TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsSheet;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Terms of Service & Privacy Policy',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'By creating an account, you agree to Meowtrack’s Terms of Service and Privacy Policy. We only use your data to provide personalized cat health and GPS tracking features.',
                style: TextStyle(fontSize: 14, height: 1.8),
              ),
              const SizedBox(height: 16),
              const Text('• Your information is stored securely.', style: TextStyle(fontSize: 14, height: 1.6)),
              const Text('• We will not sell or share your personal data without permission.', style: TextStyle(fontSize: 14, height: 1.6)),
              const Text('• You can delete your account any time from settings.', style: TextStyle(fontSize: 14, height: 1.6)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCreateAccount() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phone = _phoneController.text.trim();

    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty || phone.isEmpty) {
      _showError('Please complete all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }

    try {
      // 1. Create User with Firebase
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // 🎯 2. ASSIGN ROLE IN FIRESTORE
        // Check if admin email
        final String role = (email == 'adminketua456.meowtrack@gmail.com') ? 'admin' : 'user';

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Update Display Name (Username)
        await user.updateDisplayName(username);

        // 4. Send Email Verification
        await user.sendEmailVerification();

        appState.signUp(
          email: email,
          username: username,
          password: password,
          phoneNumber: '', 
        );

        // 5. Navigate to VERIFICATION SCREEN
        if (mounted) {
          context.push(AppRouter.verifyOtp);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'An error occurred during signup.');
    } catch (e) {
      _showError('Failed to create account. Please try again.');
    }
  }

  int _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%\^&*(),.?":{}|<>]'));
    if (password.length >= 8 && hasUpper && hasDigit && hasSpecial) return 3;
    if (password.length >= 6) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_passwordController.text);
    final strengthColor = strength == 1 ? Colors.red : (strength == 2 ? Colors.orange : (strength == 3 ? Colors.green : Colors.grey));
    final strengthLabel = strength == 0
        ? 'Enter a password'
        : (strength == 1 ? 'Weak password' : (strength == 2 ? 'Fair password' : 'Strong password'));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF985BEF), Colors.white, Colors.white],
            stops: [0, 0.32, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Create an account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 10),
                Text('Start tracking your cat’s health, habits, and safety in one place.', style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                const SizedBox(height: 34),

                _buildLabel('Email'),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: 'assets/icons/Email-01.svg',
                  iconSize: 22.0,
                ),
                const SizedBox(height: 16),

                _buildLabel('Username'),
                _buildTextField(
                  controller: _usernameController,
                  hintText: 'Username',
                  icon: 'assets/icons/Username-01.svg',
                  iconSize: 22.0,
                ),
                const SizedBox(height: 16),

                _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: 'assets/icons/Password-01.svg',
                  isPassword: true,
                  iconSize: 15.0,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: strength, child: Container(height: 6, decoration: BoxDecoration(color: strengthColor, borderRadius: BorderRadius.circular(3)))),
                    if (strength < 3) const SizedBox(width: 6),
                    Expanded(flex: 3 - strength, child: Container(height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3)))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(strengthLabel, style: TextStyle(fontSize: 12, color: strengthColor)),
                const SizedBox(height: 16),

                _buildLabel('Confirm password'),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm password',
                  icon: 'assets/icons/Password-01.svg',
                  isPassword: true,
                  iconSize: 15.0,
                ),
                const SizedBox(height: 16),

                _buildLabel('Phone number'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          exclude: <String>['IL'],
                          countryListTheme: CountryListThemeData(
                            borderRadius: BorderRadius.circular(20),
                            inputDecoration: InputDecoration(
                              hintText: 'Search country...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF985BEF)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country;
                            });
                          },
                        );
                      },
                      child: Container(
                        width: 112,
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedCountry.flagEmoji} +${_selectedCountry.phoneCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        hintText: 'Phone number',
                        icon: '', // <--- DI SINI KITA KOSONGKAN IKON TELEFON! Tiada lagi ikon telefon degil.
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      activeColor: const Color(0xFF985BEF),
                      onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'Terms of Service and Privacy Policy',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF985BEF)),
                              recognizer: _termsRecognizer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _handleCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Create account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: TextStyle(color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: const Text('Log in', style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
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
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    double iconSize = 20.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),

          // Semak jika ikon kosong (seperti input telefon), jangan letak suffixIcon terus
          suffixIcon: icon.isEmpty
              ? null
              : Container(
            margin: const EdgeInsets.only(right: 14.0),
            child: Transform.scale(
              scale: isPassword ? 0.75 : 1.0,
              child: SvgPicture.asset(
                icon,
                colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn),
                width: iconSize,
                height: iconSize,
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}