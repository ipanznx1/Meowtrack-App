import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:meow_track/core/widgets/image_background.dart';
import 'package:meow_track/core/app_state.dart';

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

  Widget getRankBadge(String rank, {double size = 40}) {
    final Map<String, String> badgeAssets = {
      'Novice Pawrent': 'assets/rank/Newbie Pawrent.png',
      'Guardian Angel': 'assets/rank/Guardian Angel.png',
      'Cat Whisperer': 'assets/rank/Cat Whisperer.png',
      'Professor Meow': 'assets/rank/Professor Meow.png',
      'Cat Royalty': 'assets/rank/Cat Royalty.png',
    };
    final asset = badgeAssets[rank] ?? 'assets/rank/Newbie Pawrent.png';
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();
    final totalPets = state.cats.length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 70),
              GestureDetector(
                onTap: () => context.push('/account-settings'),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.white,
                      backgroundImage: (state.avatarUrl != null && state.avatarUrl!.isNotEmpty)
                          ? NetworkImage(state.avatarUrl!)
                          : const AssetImage('assets/images/Luna.png') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF985BEF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(state.userName ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 5),
              const Text('Cat Owner', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // 🎯 PROMINENT PURR CODE DISPLAY
              if (state.purrCode != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: state.purrCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Purr Code ${state.purrCode} copied!")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF985BEF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF985BEF).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy, size: 14, color: Color(0xFF985BEF)),
                            const SizedBox(width: 8),
                            Text(
                              'Code: ${state.purrCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF985BEF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context.push('/qr-tag'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code, size: 16, color: Color(0xFF985BEF)),
                            SizedBox(width: 8),
                            Text("Pet Tag", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 25),

              // STATS BOX
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            const Text('Total Pets', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('$totalPets', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      Container(height: 80, width: 1, color: Colors.grey[200]),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            const Text('Rank', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            getRankBadge(state.currentRank, size: 65),
                            const SizedBox(height: 8),
                            Text(state.currentRank, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: const LinearProgressIndicator(
                                      value: 0.4, // Simplified for now
                                      backgroundColor: Color(0xFFF2F2F7),
                                      color: Color(0xFF985BEF),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Progress', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      Text('Next Rank', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildListItem(context, 'My Purr-mates', () => context.push('/purrmates')),
              const SizedBox(height: 12),
              _buildListItem(context, 'My Household', () => context.push('/household')),
              const SizedBox(height: 12),
              _buildListItem(context, 'Account Settings', () => context.push('/account-settings')),

              const SizedBox(height: 40),
              const Text('Others', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                  children: [
                    _buildGridIllustration(context, 'Preferences', 'assets/images/Preferences.png', () => context.push('/preferences')),
                    _buildGridIllustration(context, 'Feedback', 'assets/images/Feedback.png', () => context.push('/feedback')),
                    _buildGridIllustration(context, 'About', 'assets/images/About.png', () => context.push('/about')),
                    _buildGridIllustration(context, 'Notification', 'assets/images/Notification.png', () => context.push('/notification')),
                  ],
                ),
              ),

              const SizedBox(height: 45),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () async {
                    await state.logout();
                    if (context.mounted) {
                      context.go('/auth-gateway');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridIllustration(BuildContext context, String title, String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Container(
          height: 160,
          color: Colors.white,
          child: Stack(
            children: [
              Positioned.fill(child: ImageBackground(assetPath: asset, color: Colors.white, imageOpacity: 0.7)),
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
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(1.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black, shadows: [Shadow(color: Colors.white70, blurRadius: 2)]), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
