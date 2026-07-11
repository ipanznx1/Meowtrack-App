import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // 1. Initialize GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🎯 FUNGSI SEMAK ROLE DAN NAVIGASI (DEBUG)
  Future<void> _checkRoleAndNavigate(User user, String email, String password) async {
    try {
      print("DEBUG: Memulakan semakan role untuk UID: ${user.uid}");
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        print("DEBUG: Dokumen user tidak dijumpai di Firestore. Default ke 'user'.");
        _navigateBasedOnRole('user', email, password);
        return;
      }

      final rawRole = doc.data()?['role'];
      print("DEBUG: Role mentah dari Firestore: $rawRole");

      // Logik semakan fleksibel (String atau Array)
      bool hasAdminAccess = false;
      if (rawRole is String) {
        hasAdminAccess = rawRole == 'admin';
      } else if (rawRole is List) {
        hasAdminAccess = rawRole.contains('admin');
      }

      final String finalRole = hasAdminAccess ? 'admin' : 'user';
      print("DEBUG: Akses ditentukan sebagai: '$finalRole'");

      // Hanya panggil login asas, biarkan listener Firestore tentukan availableRoles
      appState.login(email: email, password: password);
    } catch (e) {
      print("DEBUG: Ralat semasa semakan role: $e");
      _showError("Failed to verify user role.");
    }
  }

  void _navigateBasedOnRole(String role, String email, String password) {
    appState.login(email: email, password: password);
  }

  void _showRoleSelectionDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pilih Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Akaun anda mempunyai akses Admin. Sila pilih dashboard untuk sesi ini:"),
        actions: [
          TextButton(
            onPressed: () {
              appState.login(email: email, password: password);
              appState.setSessionRole('user');
              Navigator.pop(ctx);
              context.go(AppRouter.dashboard);
            },
            child: const Text("User Dashboard", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              appState.login(email: email, password: password);
              appState.setSessionRole('admin');
              Navigator.pop(ctx);
              context.go(AppRouter.adminDashboard);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            child: const Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. Functional logic for Google Sign In
  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _checkRoleAndNavigate(user, user.email ?? '', 'google_auth_token');
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
      _showError('Google Sign-In failed.');
    }
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    try {
      // 1. Firebase Sign In
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        await user.reload();
        appState.login(email: email, password: password);

        if (mounted) {
          final route = await appState.resolvePostLoginRoute();
          context.go(route);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Authentication failed.');
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    }
  }

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
                _buildLabel('Email'),
                _buildTextField(
                  hintText: 'Email',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                _buildLabel('Password'),
                _buildTextField(
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      onPressed: () => context.push(AppRouter.forgotPassword),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Color(0xFF985BEF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleSignIn,
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
                const SizedBox(height: 30),
                // --- ADDED GOOGLE SIGN IN UI ---
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Or continue with', style: TextStyle(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _handleGoogleSignIn,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/Google__G__logo.svg.png',
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () => context.push(AppRouter.signup),
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

  Widget _buildTextField({
    required String hintText,
    required Object icon,
    bool isPassword = false,
    TextEditingController? controller,
    VoidCallback? onToggleVisibility,
  }) {
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
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: (icon is String)
                ? SvgPicture.asset(
                    icon,
                    colorFilter:
                        const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn),
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  )
                : Icon(icon as IconData, color: const Color(0xFF985BEF), size: 20),
          ),
          suffixIcon: onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    isPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF985BEF),
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
