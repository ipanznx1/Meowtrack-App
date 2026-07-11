import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MEOWTRACK HEADER
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Center(
                  child: Text(
                    "MEOWTRACK",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF985BEF),
                    ),
                  ),
                ),
              ),

              // 2. COMMUNITY BANNER (Linear Gradient)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF985BEF), Color(0xFFC084FC)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        left: 10,
                        child: Image.asset('assets/images/Community.png', height: 140, fit: BoxFit.contain),
                      ),
                      Positioned(
                        right: 25,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Community", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: const Text("Explore", style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.w900, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // 3. CAT'S PROFILE HEADER
              _buildHeader('Cat\'s Profile', 'assets/icons/Cat’s Profile.svg', () => context.push('/add-cat-1')),
              const SizedBox(height: 15),
              _buildSearch('Search cat profiles...'),
              const SizedBox(height: 20),

              // CAT'S PROFILE GRID (Matching Image 2 Style)
              ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appState.cats.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemBuilder: (context, index) => _buildCatCard(context, appState.cats[index]),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 4. REMINDERS HEADER
              _buildHeader('Reminders', 'assets/icons/Reminders.svg', () => context.push('/reminders')),
              const SizedBox(height: 20),
              
              // REMINDERS CAROUSEL (Image 2 style)
              _buildReminders(context),

              const SizedBox(height: 40),

              // 5. BOTTOM FEATURES (Image 2 Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildBottomFeature("Report Lost cat", "assets/images/Rerport lost cat.png", const Color(0xFFFF1717), Colors.white, () => context.push('/report-lost'))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildBottomFeature("AI Paws", "assets/images/Ai paws.png", const Color(0xFFF2F2F7), Colors.black, () => context.push('/ai-chat'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 26, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Spacer(),
            GestureDetector(onTap: onAdd, child: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 22)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  SvgPicture.asset('assets/icons/Search....svg', width: 20, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: const TextStyle(color: Colors.grey, fontSize: 14)))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 55, width: 55,
            decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(20)),
            child: IconButton(icon: SvgPicture.asset('assets/icons/Filter.svg', width: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)), onPressed: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCatCard(BuildContext context, Cat cat) {
    return GestureDetector(
      onTap: () => context.push('/cat-profile', extra: cat),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: cat.themeColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                child: Center(
                  child: Transform.scale(
                    scale: cat.imageScale,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(cat.image, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _info('Name', cat.name), _info('Breed', cat.breed.split(' ').first),
                  ]),
                  const SizedBox(height: 10),
                  _info('Gender', cat.gender),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))]);

  Widget _buildReminders(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return SizedBox(
          height: 280,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.75),
            itemCount: appState.appointments.length,
            itemBuilder: (context, index) {
              final appt = appState.appointments[index];
              // Dynamic bg color like screenshot 2
              final List<Color> colors = [const Color(0xFFFFD54F), const Color(0xFFC084FC), const Color(0xFFF48FB1)];
              final Color bg = colors[index % colors.length];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(35)),
                child: Column(
                  children: [
                    // Building Image
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: const DecorationImage(image: AssetImage('assets/images/reminders background.png'), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    // Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text(appt.catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('2 day left', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(appt.type, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    // Tarikh dalam kotak putih
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(appt.date.replaceAll(' ', ' - '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildBottomFeature(String title, String asset, Color bg, Color textCol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(35)),
        child: Column(
          children: [
            Expanded(child: Image.asset(asset, fit: BoxFit.contain)),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.w900, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text("Health tips and alerts summary for your cats.", style: TextStyle(color: textCol.withValues(alpha: 0.6), fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
