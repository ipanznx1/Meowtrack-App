import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/image_background.dart';
import 'package:meow_track/core/widgets/cat_sticker.dart';

class CatProfilePage extends StatelessWidget {
  final Cat cat;
  const CatProfilePage({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    final currentCat = cat;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [currentCat.themeColor, Colors.white],
                stops: const [0.0, 0.4],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: SvgPicture.asset('assets/icons/Back.svg', width: 40, height: 40, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            currentCat.name, 
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 28)
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 35, color: Colors.black),
                          onPressed: () => context.push('/edit-cat/${currentCat.id}', extra: currentCat),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
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
                          scale: currentCat.imageScale,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: CatSticker(
                              image: _buildCatImage(currentCat.image),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // QUICK STATS BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _quickStat(Icons.battery_full_rounded, '${currentCat.battery.toStringAsFixed(0)}%', Colors.green),
                        _quickStat(Icons.favorite_rounded, '${currentCat.heartRate > 0 ? currentCat.heartRate : '--'} bpm', Colors.red),
                        _quickStat(Icons.location_on_rounded, currentCat.distance, Colors.blue),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _textInfo('Breed', currentCat.breed.toUpperCase()),
                        const SizedBox(width: 20),
                        _textInfo('Gender', currentCat.gender),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 35),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStyledMenu(context, 'Health', 'assets/images/Health button.png', () => context.push('/health-overview/${currentCat.id}', extra: currentCat), 160, currentCat)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStyledMenu(context, 'Gallery', 'assets/images/Gallery button.png', () => context.push('/gallery/${currentCat.id}', extra: currentCat), 160, currentCat)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _buildStyledMenu(context, 'Notes', 'assets/images/Notes button.png', () => context.push('/notes/${currentCat.id}', extra: currentCat), 160, currentCat)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStyledMenu(context, 'Documents', 'assets/images/Documentation button.png', () => context.push('/documentation/${currentCat.id}', extra: currentCat), 160, currentCat)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildStyledMenu(context, 'Passport', 'assets/icons/Cat’s Profile.svg', () => context.push('/medical-history/${currentCat.id}', extra: currentCat), 110, currentCat, isSvg: true),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
      );
    } else if (imagePath.startsWith('/') || imagePath.startsWith('C:') || imagePath.startsWith('E:') || imagePath.startsWith('content:') || imagePath.contains('cat_cutout') || imagePath.contains('cache')) {
      return Image.file(File(imagePath), fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 50, color: Colors.grey));
    }
    return Image.asset(imagePath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 50, color: Colors.grey));
  }

  Widget _textInfo(String l, String v) => Expanded(
    child: Column(children: [
      Text(l, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey)),
      Text(v, 
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)
      ),
    ]),
  );

  Widget _quickStat(IconData icon, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value, 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildStyledMenu(BuildContext context, String title, String asset, VoidCallback onTap, double height, Cat c, {bool isSvg = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Container(
          height: height,
          width: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              if (isSvg)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: SvgPicture.asset(asset, colorFilter: ColorFilter.mode(c.themeColor.withValues(alpha: 0.3), BlendMode.srcIn)),
                  ),
                )
              else
                Positioned.fill(child: ImageBackground(assetPath: asset, color: c.themeColor, imageOpacity: 0.78)),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, c.themeColor.withValues(alpha: 0.28)],
                      ),
                    ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black54), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
