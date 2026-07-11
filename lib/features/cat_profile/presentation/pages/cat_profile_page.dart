import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';

class CatProfilePage extends StatelessWidget {
  final Cat cat;
  const CatProfilePage({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. GRADIENT BACKGROUND (Soft theme color to white)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cat.themeColor, Colors.white],
                stops: const [0.0, 0.4],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // CUSTOM APP BAR
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: SvgPicture.asset('assets/icons/Back.svg', width: 40, height: 40, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(cat.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 36)),
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // 2. MAIN CAT CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: cat.imageScale,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(cat.image, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 3. BREED & GENDER
                  _textInfo('Breed', cat.breed),
                  const SizedBox(height: 20),
                  _textInfo('Gender', cat.gender),
                  
                  const SizedBox(height: 35),
                  
                  // 4. MENU GRID (Clean & Centered - Gaya Image 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        _buildStyledMenu(context, 'Health', 'assets/images/Health button.png', () => context.push('/health-overview', extra: cat), 130),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildStyledMenu(context, 'Gallery', 'assets/images/Gallery button.png', () => context.push('/gallery', extra: cat), 180)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildStyledMenu(context, 'Notes', 'assets/images/Notes button.png', () => context.push('/notes', extra: cat), 180)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStyledMenu(context, 'Documentation', 'assets/images/Documentation button.png', () => context.push('/documentation', extra: cat), 130),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textInfo(String l, String v) => Column(children: [
    Text(l, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
    Text(v, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
  ]);

  // 🎯 WIDGET BARU: Butang Menu dengan Gradient & Gambar di dalam
  Widget _buildStyledMenu(BuildContext context, String title, String asset, VoidCallback onTap, double height) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, cat.themeColor.withValues(alpha: 0.15)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            // Gambar diletakkan di tengah dengan padding supaya tidak penuh satu butang
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            ),
            // Teks di bawah gambar
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
