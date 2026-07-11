import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MeowAnimatedDialog extends StatelessWidget {
  final String animationPath;
  final String title;
  final String description;
  final String buttonText;
  final Color themeColor;
  final VoidCallback? onConfirm;

  const MeowAnimatedDialog({
    super.key,
    required this.animationPath,
    required this.title,
    required this.description,
    this.buttonText = "Okey!",
    this.themeColor = const Color(0xFF985BEF),
    this.onConfirm,
  });

  /// Fungsi static untuk panggil dialog dengan kesan pantulan (Elastic)
  static void show(
    BuildContext context, {
    required String animationPath,
    required String title,
    required String description,
    String buttonText = "Okey!",
    Color themeColor = const Color(0xFF985BEF),
    VoidCallback? onConfirm,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // Kesan Curves.elasticOut untuk pop-in memantul
        final curvedValue = Curves.elasticOut.transform(anim1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -200, 0.0),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: MeowAnimatedDialog(
                animationPath: animationPath,
                title: title,
                description: description,
                buttonText: buttonText,
                themeColor: themeColor,
                onConfirm: onConfirm,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logik pengesanan fail (Lottie vs GIF)
    bool isLottie = animationPath.toLowerCase().endsWith('.json');

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bahagian Animasi
          SizedBox(
            height: 180,
            width: 180,
            child: isLottie
                ? Lottie.asset(animationPath, repeat: true)
                : Image.asset(animationPath),
          ),
          const SizedBox(height: 20),
          
          // Tajuk
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Penerangan
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          
          // Butang Confirm
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onConfirm != null) onConfirm!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
