import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      print('Google Sign-Up Success: ${googleUser.email}');
      appState.login(email: googleUser.email, password: 'google_auth_token');
      if (mounted) {
        context.go(AppRouter.dashboard);
      }
    } catch (error) {
      print('Google Sign-Up Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign up with Google.')),
      );
    }
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 🎯 SENARAI UTAMA: Semua negara dunia tanpa Israel
  final List<Map<String, String>> _countries = [
    {"name": "Malaysia", "code": "+60", "iso": "my"},
    {"name": "Indonesia", "code": "+62", "iso": "id"},
    {"name": "Singapore", "code": "+65", "iso": "sg"},
    {"name": "Brunei", "code": "+673", "iso": "bn"},
    {"name": "Palestine", "code": "+970", "iso": "ps"},
    {"name": "Saudi Arabia", "code": "+966", "iso": "sa"},
    {"name": "Afghanistan", "code": "+93", "iso": "af"},
    {"name": "Albania", "code": "+355", "iso": "al"},
    {"name": "Algeria", "code": "+213", "iso": "dz"},
    {"name": "Andorra", "code": "+376", "iso": "ad"},
    {"name": "Angola", "code": "+244", "iso": "ao"},
    {"name": "Argentina", "code": "+54", "iso": "ar"},
    {"name": "Armenia", "code": "+374", "iso": "am"},
    {"name": "Australia", "code": "+61", "iso": "au"},
    {"name": "Austria", "code": "+43", "iso": "at"},
    {"name": "Azerbaijan", "code": "+994", "iso": "az"},
    {"name": "Bahamas", "code": "+1-242", "iso": "bs"},
    {"name": "Bahrain", "code": "+973", "iso": "bh"},
    {"name": "Bangladesh", "code": "+880", "iso": "bd"},
    {"name": "Barbados", "code": "+1-246", "iso": "bb"},
    {"name": "Belarus", "code": "+375", "iso": "by"},
    {"name": "Belgium", "code": "+32", "iso": "be"},
    {"name": "Belize", "code": "+501", "iso": "bz"},
    {"name": "Benin", "code": "+229", "iso": "bj"},
    {"name": "Bhutan", "code": "+975", "iso": "bt"},
    {"name": "Bolivia", "code": "+591", "iso": "bo"},
    {"name": "Bosnia and Herzegovina", "code": "+387", "iso": "ba"},
    {"name": "Botswana", "code": "+267", "iso": "bw"},
    {"name": "Brazil", "code": "+55", "iso": "br"},
    {"name": "Bulgaria", "code": "+359", "iso": "bg"},
    {"name": "Burkina Faso", "code": "+226", "iso": "bf"},
    {"name": "Burundi", "code": "+257", "iso": "bi"},
    {"name": "Cambodia", "code": "+855", "iso": "kh"},
    {"name": "Cameroon", "code": "+237", "iso": "cm"},
    {"name": "Canada", "code": "+1", "iso": "ca"},
    {"name": "Central African Republic", "code": "+236", "iso": "cf"},
    {"name": "Chad", "code": "+235", "iso": "td"},
    {"name": "Chile", "code": "+56", "iso": "cl"},
    {"name": "China", "code": "+86", "iso": "cn"},
    {"name": "Colombia", "code": "+57", "iso": "co"},
    {"name": "Comoros", "code": "+269", "iso": "km"},
    {"name": "Congo", "code": "+242", "iso": "cg"},
    {"name": "Costa Rica", "code": "+506", "iso": "cr"},
    {"name": "Croatia", "code": "+385", "iso": "hr"},
    {"name": "Cuba", "code": "+53", "iso": "cu"},
    {"name": "Cyprus", "code": "+357", "iso": "cy"},
    {"name": "Czech Republic", "code": "+420", "iso": "cz"},
    {"name": "Denmark", "code": "+45", "iso": "dk"},
    {"name": "Djibouti", "code": "+253", "iso": "dj"},
    {"name": "Dominica", "code": "+1-767", "iso": "dm"},
    {"name": "Dominican Republic", "code": "+1-809", "iso": "do"},
    {"name": "Ecuador", "code": "+593", "iso": "ec"},
    {"name": "Egypt", "code": "+20", "iso": "eg"},
    {"name": "El Salvador", "code": "+503", "iso": "sv"},
    {"name": "Eritrea", "code": "+291", "iso": "er"},
    {"name": "Estonia", "code": "+372", "iso": "ee"},
    {"name": "Ethiopia", "code": "+251", "iso": "et"},
    {"name": "Fiji", "code": "+679", "iso": "fj"},
    {"name": "Finland", "code": "+358", "iso": "fi"},
    {"name": "France", "code": "+33", "iso": "fr"},
    {"name": "Gabon", "code": "+241", "iso": "ga"},
    {"name": "Gambia", "code": "+220", "iso": "gm"},
    {"name": "Georgia", "code": "+995", "iso": "ge"},
    {"name": "Germany", "code": "+49", "iso": "de"},
    {"name": "Ghana", "code": "+233", "iso": "gh"},
    {"name": "Greece", "code": "+30", "iso": "gr"},
    {"name": "Grenada", "code": "+1-473", "iso": "gd"},
    {"name": "Guatemala", "code": "+502", "iso": "gt"},
    {"name": "Guinea", "code": "+224", "iso": "gn"},
    {"name": "Guyana", "code": "+592", "iso": "gy"},
    {"name": "Haiti", "code": "+509", "iso": "ht"},
    {"name": "Honduras", "code": "+504", "iso": "hn"},
    {"name": "Hungary", "code": "+36", "iso": "hu"},
    {"name": "Iceland", "code": "+354", "iso": "is"},
    {"name": "India", "code": "+91", "iso": "in"},
    {"name": "Iran", "code": "+98", "iso": "ir"},
    {"name": "Iraq", "code": "+964", "iso": "iq"},
    {"name": "Ireland", "code": "+353", "iso": "ie"},
    {"name": "Italy", "code": "+39", "iso": "it"},
    {"name": "Jamaica", "code": "+1-876", "iso": "jm"},
    {"name": "Japan", "code": "+81", "iso": "jp"},
    {"name": "Jordan", "code": "+962", "iso": "jo"},
    {"name": "Kazakhstan", "code": "+7", "iso": "kz"},
    {"name": "Kenya", "code": "+254", "iso": "ke"},
    {"name": "Kuwait", "code": "+965", "iso": "kw"},
    {"name": "Kyrgyzstan", "code": "+996", "iso": "kg"},
    {"name": "Laos", "code": "+856", "iso": "la"},
    {"name": "Latvia", "code": "+371", "iso": "lv"},
    {"name": "Lebanon", "code": "+961", "iso": "lb"},
    {"name": "Lesotho", "code": "+266", "iso": "ls"},
    {"name": "Liberia", "code": "+231", "iso": "lr"},
    {"name": "Libya", "code": "+218", "iso": "ly"},
    {"name": "Liechtenstein", "code": "+423", "iso": "li"},
    {"name": "Lithuania", "code": "+370", "iso": "lt"},
    {"name": "Luxembourg", "code": "+352", "iso": "lu"},
    {"name": "Madagascar", "code": "+261", "mg": "mg"},
    {"name": "Malawi", "code": "+265", "iso": "mw"},
    {"name": "Maldives", "code": "+960", "iso": "mv"},
    {"name": "Mali", "code": "+223", "iso": "ml"},
    {"name": "Malta", "code": "+356", "iso": "mt"},
    {"name": "Mauritania", "code": "+222", "iso": "mr"},
    {"name": "Mauritius", "code": "+230", "iso": "mu"},
    {"name": "Mexico", "code": "+52", "iso": "mx"},
    {"name": "Moldova", "code": "+373", "iso": "md"},
    {"name": "Monaco", "code": "+377", "iso": "mc"},
    {"name": "Mongolia", "code": "+976", "iso": "mn"},
    {"name": "Montenegro", "code": "+382", "iso": "me"},
    {"name": "Morocco", "code": "+212", "iso": "ma"},
    {"name": "Mozambique", "code": "+258", "iso": "mz"},
    {"name": "Myanmar", "code": "+95", "iso": "mm"},
    {"name": "Namibia", "code": "+264", "iso": "na"},
    {"name": "Nepal", "code": "+977", "iso": "np"},
    {"name": "Netherlands", "code": "+31", "iso": "nl"},
    {"name": "New Zealand", "code": "+64", "iso": "nz"},
    {"name": "Nicaragua", "code": "+505", "iso": "ni"},
    {"name": "Niger", "code": "+227", "iso": "ne"},
    {"name": "Nigeria", "code": "+234", "iso": "ng"},
    {"name": "North Korea", "code": "+850", "iso": "kp"},
    {"name": "Norway", "code": "+47", "iso": "no"},
    {"name": "Oman", "code": "+968", "iso": "om"},
    {"name": "Pakistan", "code": "+92", "iso": "pk"},
    {"name": "Panama", "code": "+507", "iso": "pa"},
    {"name": "Papua New Guinea", "code": "+675", "iso": "pg"},
    {"name": "Paraguay", "code": "+595", "iso": "py"},
    {"name": "Peru", "code": "+51", "iso": "pe"},
    {"name": "Philippines", "code": "+63", "iso": "ph"},
    {"name": "Poland", "code": "+48", "iso": "pl"},
    {"name": "Portugal", "code": "+351", "iso": "pt"},
    {"name": "Qatar", "code": "+974", "iso": "qa"},
    {"name": "Romania", "code": "+40", "iso": "ro"},
    {"name": "Russia", "code": "+7", "iso": "ru"},
    {"name": "Rwanda", "code": "+250", "iso": "rw"},
    {"name": "Samoa", "code": "+685", "iso": "ws"},
    {"name": "San Marino", "code": "+378", "iso": "sm"},
    {"name": "Senegal", "code": "+221", "iso": "sn"},
    {"name": "Serbia", "code": "+381", "iso": "rs"},
    {"name": "Seychelles", "code": "+248", "iso": "sc"},
    {"name": "Sierra Leone", "code": "+232", "iso": "sl"},
    {"name": "Slovakia", "code": "+421", "iso": "sk"},
    {"name": "Slovenia", "code": "+386", "iso": "si"},
    {"name": "Somalia", "code": "+252", "iso": "so"},
    {"name": "South Africa", "code": "+27", "iso": "za"},
    {"name": "South Korea", "code": "+82", "iso": "kr"},
    {"name": "Spain", "code": "+34", "iso": "es"},
    {"name": "Sri Lanka", "code": "+94", "iso": "lk"},
    {"name": "Sudan", "code": "+249", "iso": "sd"},
    {"name": "Suriname", "code": "+597", "iso": "sr"},
    {"name": "Sweden", "code": "+46", "iso": "se"},
    {"name": "Switzerland", "code": "+41", "iso": "ch"},
    {"name": "Syria", "code": "+963", "iso": "sy"},
    {"name": "Taiwan", "code": "+886", "iso": "tw"},
    {"name": "Tajikistan", "code": "+992", "iso": "tj"},
    {"name": "Tanzania", "code": "+255", "iso": "tz"},
    {"name": "Thailand", "code": "+66", "iso": "th"},
    {"name": "Togo", "code": "+228", "iso": "tg"},
    {"name": "Tonga", "code": "+676", "iso": "to"},
    {"name": "Tunisia", "code": "+216", "iso": "tn"},
    {"name": "Turkey", "code": "+90", "iso": "tr"},
    {"name": "Turkmenistan", "code": "+993", "iso": "tm"},
    {"name": "Uganda", "code": "+256", "iso": "ug"},
    {"name": "Ukraine", "code": "+380", "iso": "ua"},
    {"name": "United Arab Emirates", "code": "+971", "iso": "ae"},
    {"name": "United Kingdom", "code": "+44", "iso": "gb"},
    {"name": "United States", "code": "+1", "iso": "us"},
    {"name": "Uruguay", "code": "+598", "iso": "uy"},
    {"name": "Uzbekistan", "code": "+998", "iso": "uz"},
    {"name": "Venezuela", "code": "+58", "iso": "ve"},
    {"name": "Vietnam", "code": "+84", "iso": "vn"},
    {"name": "Yemen", "code": "+967", "iso": "ye"},
    {"name": "Zambia", "code": "+260", "iso": "zm"},
    {"name": "Zimbabwe", "code": "+263", "iso": "zw"}
  ];

  late Map<String, String> _selectedCountry;
  late TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries[0];
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

  // 🎯 IMPLEMENTASI SEARCH NEGARA SECARA POP-UP MODAL BOTTOM SHEET
  void _showCountrySearchPicker() {
    List<Map<String, String>> filteredCountries = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text('Search Country', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // Kotak Carian Negara
                  Container(
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Type country name or code...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF985BEF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (query) {
                        setModalState(() {
                          filteredCountries = _countries.where((country) {
                            final name = country['name']!.toLowerCase();
                            final code = country['code']!.toLowerCase();
                            final search = query.toLowerCase();
                            return name.contains(search) || code.contains(search);
                          }).toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Senarai Paparan Hasil Carian
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: Image.network(
                            'https://flagcdn.com/w40/${country['iso']}.png',
                            width: 30,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag_outlined, size: 20),
                          ),
                          title: Text(country['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Text(country['code']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          onTap: () {
                            setState(() {
                              _selectedCountry = country;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Agreement Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please read our official documents to understand how we protect your data and the rules of using Meowtrack.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Color(0xFF985BEF)),
                title: const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/terms-conditions');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF985BEF)),
                title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/privacy-policy');
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('I Understand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms of Service and Privacy Policy.')),
      );
      return;
    }

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    
    // ... rest of the signup logic ...

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
        final String role = (email == 'tegarhebat45@gmail.com') ? 'admin' : 'user';

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
          phoneNumber: '${_selectedCountry['code']} $phone',
        );

        // 5. Navigate to VERIFICATION SCREEN
        if (mounted) {
          context.push(AppRouter.verifyOtp);
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred during signup.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create account. Please try again.')),
      );
    }
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 1;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (password.length >= 8 && hasUppercase && hasDigits && hasSpecial) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final int strength = _calculatePasswordStrength(_passwordController.text);

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                const SizedBox(height: 40),
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start your cat\'s health journey today.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // 🎯 KOD SVG DIKEMASKINI KE '-01.svg'
                _buildLabel('Email'),
                _buildTextField(controller: _emailController, hintText: 'Email', icon: Icons.mail_outline),
                const SizedBox(height: 15),
                _buildLabel('Username'),
                _buildTextField(controller: _usernameController, hintText: 'Username', icon: Icons.person_outline),
                const SizedBox(height: 15),
                _buildLabel('Password'),

                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: _obscurePassword,
                  onChanged: (value) => setState(() {}),
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter password' : (v.length < 6 ? 'Min 6 characters' : null),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: strength == 0 ? 0 : (strength == 1 ? 1 : (strength == 2 ? 2 : 3)),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: strength == 1
                              ? Colors.red
                              : (strength == 2 ? Colors.orange : Colors.green),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (strength > 0) const SizedBox(width: 5),
                    Expanded(
                      flex: 3 - strength,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strength == 0
                        ? 'Enter a password'
                        : (strength == 1 ? 'Password is too weak' : (strength == 2 ? 'Password is medium' : 'Password is safe & strong!')),
                    style: TextStyle(
                        color: strength == 1
                            ? Colors.red
                            : (strength == 2 ? Colors.orange : (strength == 3 ? Colors.green : Colors.grey)),
                        fontSize: 11,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildLabel('Confirm Password'),
                _buildTextField(
                  controller: _confirmPasswordController, 
                  hintText: 'Confirm Password', 
                  icon: Icons.lock_outline,
                  isPassword: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildLabel('Phone Number'),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tukar Dropdown lama ke GestureDetector baru yang ada fungsi SEARCH
                    GestureDetector(
                      onTap: _showCountrySearchPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 55,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://flagcdn.com/w40/${_selectedCountry['iso']}.png',
                              width: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag_outlined, size: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(_selectedCountry['code']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Enter phone number',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            suffixIcon: null, // Kekal ghaib mengikut arahan terdahulu
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) => setState(() => _agreeToTerms = value!),
                        activeColor: const Color(0xFF985BEF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'Terms of Service and Privacy Policy',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF985BEF)),
                              recognizer: _termsRecognizer,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('Or continue with', style: TextStyle(color: Colors.grey[600]))),
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
                          color: Colors.black.withOpacity(0.05),
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
                    Text('Already have an account? ', style: TextStyle(color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: const Text('Log In', style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hintText,
    required Object icon,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator:
            validator ?? (v) => (v == null || v.isEmpty) ? 'Cannot be empty' : null,
        onChanged: onChanged,
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
                  )
                : Icon(icon as IconData, color: const Color(0xFF985BEF), size: 20),
          ),
          suffixIcon: onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    isPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF985BEF),
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
