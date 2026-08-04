import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomAppBar(
        height: 80,
        notchMargin: 10,
        color: Colors.white,
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildNavItem(context, 'assets/icons/Dashboard Nav Bar.svg', "Dashboard", location == '/dashboard', '/dashboard')),
            Expanded(child: _buildNavItem(context, 'assets/icons/GPS Track Nav Bar.svg', "Track", location == '/gps-tracking', '/gps-tracking')),
            const SizedBox(width: 70), // Center gap for FAB
            Expanded(child: _buildNavItem(context, 'assets/icons/Vet Nav Bar.svg', "Vet", location == '/vet-directory', '/vet-directory')),
            Expanded(child: _buildNavItem(context, 'assets/icons/Profile Nav Bar.svg', "Profile", location == '/owner-profile', '/owner-profile')),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () => context.push('/ar-scan'),
          backgroundColor: const Color(0xFF985BEF),
          elevation: 5,
          shape: const CircleBorder(),
          child: SvgPicture.asset('assets/icons/Camera.svg', color: Colors.white, width: 32, height: 32),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String svgAsset, String label, bool isActive, String route) {
    return GestureDetector(
      onTap: () {
        if (!isActive) context.go(route);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgAsset,
            color: isActive ? const Color(0xFF985BEF) : Colors.grey[400],
            width: 26,
            height: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF985BEF) : Colors.grey[400],
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
