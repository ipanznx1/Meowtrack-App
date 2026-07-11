import 'package:flutter/material.dart';

class AuthBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const AuthBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF985BEF), Colors.white, Colors.white],
          stops: [0.0, 0.25, 1.0],
        ),
      ),
      child: child,
    );
  }
}
