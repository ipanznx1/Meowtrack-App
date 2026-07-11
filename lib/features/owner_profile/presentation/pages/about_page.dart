import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
        title: const Text("About", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. MEOWTRACK LOGO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                'assets/images/app_icon.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 80, color: Color(0xFF985BEF)),
              ),
            ),
            const SizedBox(height: 30),

            // 2. SUBTITLES
            _buildSubtitle("What is meowtrack"),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Meowtrack was created to provide cat owners with peace of mind through affordable and smart tracking technology.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 25),

            // 3. UPDATE CARD
            _buildSubtitle("Update"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Text("App Version 1.0.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Last update : 21 January 2026", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF985BEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Check Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("What's New (14 May 2026)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPoint("Enhanced Bluetooth Sync: Faster and more stable connection with Mi Tag devices."),
                  _buildBulletPoint("Precision GPS: Improved location accuracy for outdoor tracking."),
                  _buildBulletPoint("Battery Saver Mode: New algorithm to make your cat's collar last longer."),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 4. ACTION BUTTONS
            Row(
              children: [
                Expanded(child: _buildActionBtn("Privacy Policy")),
                const SizedBox(width: 15),
                Expanded(child: _buildActionBtn("Contact Developer")),
              ],
            ),
            const SizedBox(height: 30),

            // 5. TECH STACK (Image 8 style)
            const Text("Powered by", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _techLogo('assets/images/Unity.png', 70),
                _techLogo('assets/images/Android_Studio.png', 50),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _techLogo('assets/images/flutter-logo-sharing 1.png', 40),
                _techLogo('assets/images/Figma-logo.svg 1.png', 40),
                _techLogo('assets/images/Google_Gemini_icon_2025.svg 1.png', 40),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, height: 1.3))),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF985BEF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _techLogo(String asset, double height) {
    return Image.asset(asset, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.code));
  }
}
