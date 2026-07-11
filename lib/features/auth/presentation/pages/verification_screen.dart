import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 🎯 TUKAR KEPADA: StatefulWidget supaya sistem boleh buat kiraan saat & tukar warna teks secara dinamik
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // 🎯 1. PENGURUS KOTAK INPUT: Sediakan 4 controller dan 4 focus node untuk kawalan lompat
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // 🎯 2. LOGIK STATUS RALAT: Set kepada 'false' asal supaya amaran "Invalid code" tak terlepas keluar awal!
  bool _hasError = false;

  // 🎯 3. ENGIN COUNTDOWN RESEND: Pembuat masa randik 60 saat
  Timer? _timer;
  int _startSeconds = 60;
  bool _isResendAvailable = false;

  @override
  void initState() {
    super.initState();
    _startTimer(); // Mula mengira sebaik sahaja skrin dimuatkan
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

  void _resendCode() {
    if (!_isResendAvailable) return;

    // Sini nanti tempat letak logic hantar SMS OTP baru
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification code has been resent.')),
    );

    // Mulakan semula kiraan 60 saat
    _startTimer();
  }

  void _verifyOtp() {
    // Gabung input dari 4 kotak menjadi 1 text penuh (Contoh: "1234")
    String enteredCode = _controllers.map((c) => c.text).join();

    if (enteredCode.length < 4) {
      setState(() => _hasError = true);
      return;
    }

    // 🔴 SIMULASI PENGESAHAN KOD (Boleh tukar ikut sistem backend awak nanti):
    if (enteredCode == "1234") {
      setState(() => _hasError = false);
      context.push('/create-new-password');
    } else {
      setState(() => _hasError = true); // Jika salah, teks merah "Invalid code" akan dipancarkan
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) { controller.dispose(); }
    for (var node in _focusNodes) { node.dispose(); }
    super.dispose();
  }

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
                  'Verification',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We\'ve sent a 4-digit code to [Phone Number]. Enter it below to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 60),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter Verification Code',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),

                // 🎯 REKAAN BARU PETAK CODE: Guna gelung List.generate bersepadu dengan logik auto-lompat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 65,
                      height: 65,
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
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) {
                          // 🚀 LOGIK TEKAN NO TERUS MASUK SEBELAH
                          if (value.isNotEmpty) {
                            if (index < 3) {
                              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                            } else {
                              _focusNodes[index].unfocus(); // Kotak terakhir, simpan keyboard
                            }
                          } else {
                            // 🚀 LOGIK UNDUR (BACKSPACE): Padam terus masuk kotak sebelah kiri balik
                            if (index > 0) {
                              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                            }
                          }
                          // Padam status ralat kalau user taip balik nombor baharu
                          if (_hasError) setState(() => _hasError = false);
                        },
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // 🎯 BUTANG RESEND PINTAR: Automatik tunjuk baki saat mengikut state pemasa
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('If you didn\'t receive a code, ', style: TextStyle(color: Colors.grey[600])),
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

                // 🎯 RALAT DIKAWAL: Hanya akan dipaparkan jika '_hasError' disahkan 'true'
                if (_hasError)
                  const Text(
                    'Invalid code. Please try again.',
                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  ),

                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verify',
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
}