import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meow_track/core/pages/not_implemented_page.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';

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
                  const Text("App Version 1.1.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Last update : Today", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Checking for updates..."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      Future.delayed(const Duration(seconds: 2), () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Your app is up to date!"),
                            ),
                          );
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF985BEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Check Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("What's New", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPoint("Custom Cat Themes: Choose from 8 pastel colors for cat profiles."),
                  _buildBulletPoint("Edit Cat Profile: New screen to modify cat details anytime."),
                  _buildBulletPoint("UI Improvements: Fixed profile page overflows and added sticker effects."),
                  _buildBulletPoint("Enhanced Stability: Better handling of environment variables and API keys."),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 4. ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    context,
                    "Privacy Policy",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionBtn(
                    context,
                    "Terms & Conditions",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsPage(),
                      ),
                    ),
                  ),
                ),
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
                _techLogo('assets/images/Google__G__logo.svg.png', 45),
                _techLogo('assets/images/Primary_Vertical_Lockup_Full_Color.png', 40),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _techLogo('assets/images/flutter-logo-sharing 1.png', 40),
                _techLogo('assets/images/Figma-logo.svg 1.png', 40),
                _techLogo('assets/images/Visual_Studio_Code_1.35_icon.svg.png', 40),
                _techLogo('assets/images/Google_Gemini_icon_2025.svg 1.png', 40),
                _techLogoSvg('assets/images/Brand-Github-Copilot--Streamline-Tabler.svg', 40),
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

  Widget _buildActionBtn(BuildContext context, String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF985BEF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _techLogo(String asset, double height) {
    return Image.asset(asset, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.code));
  }

  Widget _techLogoSvg(String asset, double height) {
    return SvgPicture.asset(asset, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.code));
  }
}
