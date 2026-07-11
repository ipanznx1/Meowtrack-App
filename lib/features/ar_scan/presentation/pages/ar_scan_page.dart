import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ArScanPage extends StatelessWidget {
  const ArScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AR Scan (Under Maintenance)"),
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text("Fungsi AR dimatikan sementara waktu."),
      ),
    );
  }
}
