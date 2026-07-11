import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  int level = 2; 
  double currentXP = 20.0;
  final double maxXP = 100.0;
  int totalPets = 5;

  String getRankTitle(int level) {
    switch (level) {
      case 1: return 'Newbie Pawrent';
      case 2: return 'Guardian Angel';
      case 3: return 'Cat Whisperer';
      case 4: return 'Professor Meow';
      case 5: return 'Cat Royalty';
      default: return 'Newbie Pawrent';
    }
  }

  Widget getRankBadge(int level, {double size = 40}) {
    final List<String> badgeAssets = [
      'assets/rank/Newbie Pawrent.png',
      'assets/rank/Guardian Angel.png',
      'assets/rank/Cat Whisperer.png',
      'assets/rank/Professor Meow.png',
      'assets/rank/Cat Royalty.png',
    ];
    return Image.asset(badgeAssets[level - 1], width: size, height: size, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70),
            const CircleAvatar(
              radius: 75,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/images/Profile picture.png'),
            ),
            const SizedBox(height: 20),
            const Text('Irfan Kasfi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
            const Text('Senior Cat Owner', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 35),

            // STATS BOX
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
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
                          getRankBadge(level, size: 65),
                          const SizedBox(height: 8),
                          Text(getRankTitle(level), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: currentXP / maxXP,
                                    backgroundColor: const Color(0xFFF2F2F7),
                                    color: const Color(0xFF985BEF),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Level $level', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text('${currentXP.toInt()}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text('Level ${level + 1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
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

            _buildListItem('My Purr-mates', () => context.push('/purrmates')),
            const SizedBox(height: 12),
            _buildListItem('My Household', () => context.push('/household')),
            const SizedBox(height: 12),
            _buildListItem('Account Settings', () => context.push('/account-settings')),

            const SizedBox(height: 40),
            const Text('Others', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 25),

            // OTHERS GRID (Matching Image 4 illustrations with internal images)
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
                  _buildGridIllustration('Preferences', 'assets/images/Preferences.png', () => context.push('/preferences')),
                  _buildGridIllustration('Feedback', 'assets/images/Feedback.png', () => context.push('/feedback')),
                  _buildGridIllustration('About', 'assets/images/About.png', () => context.push('/about')),
                  _buildGridIllustration('Notification', 'assets/images/Notification.png', () => context.push('/notification')),
                ],
              ),
            ),

            const SizedBox(height: 45),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => context.go('/auth-gateway'),
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
    );
  }

  Widget _buildListItem(String title, VoidCallback onTap) {
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

  Widget _buildGridIllustration(String title, String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(35),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F5F7)],
          ),
        ),
        child: Column(
          children: [
            // Gambar di dalam kotak dengan padding kemas
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15), child: Image.asset(asset, fit: BoxFit.contain))),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
