import 'package:flutter/material.dart';

/// Widget untuk menghasilkan kesan "Sticker Outline" pada gambar kucing.
class CatSticker extends StatelessWidget {
  final Widget image;
  final double outlineThickness;
  final Color outlineColor;

  const CatSticker({
    super.key,
    required this.image,
    this.outlineThickness = 2.5, // Ketebalan garisan putih
    this.outlineColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. LAPISAN OUTLINE (DI BELAKANG)
        // Kita hasilkan 8 salinan gambar kucing yang dicat putih sepenuhnya.
        // Setiap salinan dialihkan (offset) ke arah yang berbeza.
        for (double i = 0; i < 360; i += 45)
          Transform.translate(
            offset: Offset.fromDirection(i * 0.0174533, outlineThickness),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(outlineColor, BlendMode.srcIn),
              child: image,
            ),
          ),

        // 2. GAMBAR ASAL (DI HADAPAN)
        image,
      ],
    );
  }
}
