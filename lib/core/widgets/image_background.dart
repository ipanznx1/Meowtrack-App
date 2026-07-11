import 'package:flutter/material.dart';

class ImageBackground extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color color;
  final double imageOpacity;
  final Widget? child;

  const ImageBackground({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    required this.color,
    this.borderRadius = 12.0,
    this.imageOpacity = 1.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double overlayHeight = (height != null) ? (height! * 0.36) : 80.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(child: Opacity(opacity: imageOpacity, child: Image.asset(assetPath, fit: BoxFit.cover))),
            // bottom gradient overlay matching the provided color
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: overlayHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.0), color.withOpacity(0.45)],
                  ),
                ),
              ),
            ),
            if (child != null) Positioned.fill(child: Center(child: child)),
          ],
        ),
      ),
    );
  }
}
