import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ArScanPage extends StatefulWidget {
  const ArScanPage({super.key});

  @override
  State<ArScanPage> createState() => _ArScanPageState();
}

class _ArScanPageState extends State<ArScanPage> {
  // 🎯 SAMA DENGAN PACKAGE NAME APK UNITY ANDA
  final String unityPackageName = "com.CompanyName.KUCINGARBARU";
  
  static const platform = MethodChannel('meowtrack/ar_channel');
  bool _isLaunching = false;

  Future<void> _launchARApp() async {
    setState(() => _isLaunching = true);

    try {
      // Kita hantar package name ke MainActivity.kt untuk dilancarkan
      await platform.invokeMethod('openUnity', {"packageName": unityPackageName});
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ralat AR: ${e.message}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
        title: const Text("AR Experience", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_in_ar_outlined, size: 100, color: Color(0xFF985BEF)),
            const SizedBox(height: 30),
            const Text("Launch Cat AR", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                "Pastikan anda telah install APK AR dengan Package Name: $unityPackageName",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isLaunching ? null : _launchARApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF985BEF),
                minimumSize: const Size(220, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: _isLaunching 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Open AR App", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
