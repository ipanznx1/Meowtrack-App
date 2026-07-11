import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/tutorial_controller.dart';
import 'package:meow_track/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _filter = 'all';
  final TextEditingController _breedFilterController = TextEditingController();
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    _listenToSystemStatus();
    
    // 🎯 AUTO-START TUTORIAL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tutorial = Provider.of<TutorialController>(context, listen: false);
      if (!tutorial.isTutorialCompleted) {
        if (appState.cats.isNotEmpty) {
           tutorial.startFinalTutorial(context);
           // 🎯 Terus tandakan sebagai selesai supaya tak muncul lagi bila masuk balik dashboard
           tutorial.completeTutorial();
        } else {
           tutorial.startDashboardTutorial(context);
        }
      }
    });
  }

  void _listenToSystemStatus() {
    FirebaseFirestore.instance.collection('app_settings').doc('system_status').snapshots().listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      bool isMaintenance = data['maintenanceMode'] ?? false;
      bool isAdmin = appState.sessionRole == 'admin' || appState.sessionRole == 'moderator';

      if (isMaintenance && !isAdmin) {
        _showMaintenanceDialog();
      } else if (!isMaintenance && !_popupShown) {
        _checkAndShowDynamicPopup(data);
      }
    });
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Padding(
            padding: EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.engineering_rounded, size: 80, color: Colors.orange),
                SizedBox(height: 20),
                Text("Sistem Sedang Diselenggara", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                SizedBox(height: 15),
                Text("Meowtrack HQ sedang melakukan naik taraf sistem. Sila cuba sebentar lagi.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkAndShowDynamicPopup(Map<String, dynamic> data) {
    String type = data['popupType'] ?? 'text_only';
    String message = data['flashAnnouncement'] ?? '';
    String imageUrl = data['popupImageUrl'] ?? '';
    if (message.isEmpty && imageUrl.isEmpty) return;

    _popupShown = true;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (type != 'text_only' && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                      },
                      errorBuilder: (context, _, __) => const SizedBox.shrink(),
                    ),
                  if (type != 'poster_only' && message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16.0, 
              right: 16.0, 
              top: 16.0, 
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filter Cats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                RadioListTile<String>(value: 'all', groupValue: _filter, title: const Text('All'), onChanged: (v) { setState(() => _filter = v!); setSheetState(() {}); }),
                RadioListTile<String>(value: 'female', groupValue: _filter, title: const Text('Female'), onChanged: (v) { setState(() => _filter = v!); setSheetState(() {}); }),
                RadioListTile<String>(value: 'male', groupValue: _filter, title: const Text('Male'), onChanged: (v) { setState(() => _filter = v!); setSheetState(() {}); }),
                RadioListTile<String>(value: 'breed', groupValue: _filter, title: const Text('Breed'), onChanged: (v) { setState(() => _filter = v!); setSheetState(() {}); }),
                if (_filter == 'breed')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      controller: _breedFilterController,
                      decoration: InputDecoration(
                        hintText: 'Enter breed name...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)), 
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text('Apply', style: TextStyle(color: Colors.white)))
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

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
              Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 15),
                child: Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48), // Spacer balance
                          const Text(
                            "MEOWTRACK",
                            style: TextStyle(
                              fontFamily: 'Yorkmade',
                              fontSize: 42,
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF985BEF),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 48), // Spacer balance
                        ],
                      ),
                      const SizedBox(height: 4),
                      ListenableBuilder(
                        listenable: appState,
                        builder: (context, _) {
                          final String name = appState.userName ?? "User";
                          final bool isNew = appState.isNewUser;
                          return Text(
                            isNew ? "Welcome to the Family, $name!" : "Welcome back, $name!",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 2. COMMUNITY BANNER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Showcase(
                  key: Provider.of<TutorialController>(context, listen: false).communityFeedKey,
                  description: "Jom kenali pencinta kucing lain di Community Hub!",
                  disposeOnTap: true,
                  onTargetClick: () {
                    context.push(AppRouter.communityHub);
                  },
                  child: GestureDetector(
                    onTap: () => context.push(AppRouter.communityHub),
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
                ),
              ),

              const SizedBox(height: 20),

              // 3. CAT'S PROFILE HEADER (With Add Button)
              _buildHeader('Cat\'s Profile', 'assets/icons/Cat’s Profile.svg', () => context.push('/add-cat-1')),
              const SizedBox(height: 15),
              _buildSearch('Search cat profiles...'),
              const SizedBox(height: 20),

              // CAT'S PROFILE GRID
              ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                    final all = appState.cats;
                    final filtered = _filter == 'all'
                      ? all
                      : _filter == 'female'
                        ? all.where((c) => c.gender.toLowerCase() == 'female').toList()
                        : _filter == 'male'
                          ? all.where((c) => c.gender.toLowerCase() == 'male').toList()
                          : _filter == 'breed'
                            ? all.where((c) => c.breed.toLowerCase().contains(_breedFilterController.text.toLowerCase())).toList()
                            : all;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68, 
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemBuilder: (context, index) => _buildCatCard(context, filtered[index]),
                    ),
                  );
                },
              ),

              const SizedBox(height: 35),
              
              // 🎯 MEOW TOOLS SECTION (After Cat Profile)
              _buildMeowTools(context),

              const SizedBox(height: 35),

              // 4. REMINDERS HEADER
              _buildHeader('Reminders', 'assets/icons/Reminders.svg', () => context.push('/add-appointment')),
              const SizedBox(height: 20),
              
              _buildReminders(context),

              const SizedBox(height: 40),

              // 5. BOTTOM FEATURES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildReportLostFeature("Report Lost cat", "assets/images/Rerport lost cat.png", const Color(0xFFFF1717), Colors.white, () => context.push('/report-lost'))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildAIPawsCard("AI Paws", "assets/images/Ai paws.png", () => context.push('/ai-chat'))),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. MEOWPROTECT HUB
              _buildInsurancePromoBanner(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeowTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tajuk Meow Tools dengan gaya yang sama seperti label bahagian lain
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5), 
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: Color(0xFF985BEF), size: 26),
                const SizedBox(width: 10),
                const Text(
                  "MEOW TOOLS", 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _toolCard(
                context, 
                "Kibble Tracker", 
                Icons.restaurant, 
                const Color(0xFFFFE0B2), 
                const Color(0xFFE65100),
                () => context.push('/kibble-tracker')
              ),
              _toolCard(
                context, 
                "MeowBudget", 
                Icons.account_balance_wallet, 
                const Color(0xFFC8E6C9), 
                const Color(0xFF1B5E20),
                () => context.push('/budget-tracker')
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolCard(BuildContext context, String title, IconData icon, Color bg, Color iconCol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconCol, size: 30),
            const SizedBox(height: 8),
            Text(
              title, 
              style: TextStyle(color: iconCol, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportLostFeature(String title, String asset, Color bg, Color textCol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 260,
          width: double.infinity,
          color: bg,
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                bottom: 60,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1)],
                      ),
                    ),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsurancePromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push(AppRouter.insuranceHub),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MeowProtect Hub",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Protect your furry friend from high vet bills. Explore plans starting from RM5/month.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF985BEF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "Explore Plans",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.shield_outlined, size: 60, color: Color(0xFF985BEF)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIPawsCard(String title, String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 260,
          width: double.infinity,
          color: const Color(0xFFF0F0F5),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Image.asset(asset, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String icon, VoidCallback onAdd) {
    final tutorial = Provider.of<TutorialController>(context, listen: false);
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
            if (title == 'Cat\'s Profile')
              Showcase(
                key: tutorial.addCatKey,
                description: "Tekan sini untuk mula mendaftarkan kucing kesayangan anda!",
                disposeOnTap: true,
                onTargetClick: onAdd,
                child: GestureDetector(
                  onTap: onAdd, 
                  child: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 22)
                ),
              )
            else
              GestureDetector(
                onTap: onAdd, 
                child: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 22)
              ),
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
            child: IconButton(
              icon: SvgPicture.asset('assets/icons/Filter.svg', width: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
              onPressed: _showFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatCard(BuildContext context, Cat cat) {
    return GestureDetector(
      onTap: () => context.push('/cat-profile/${cat.id}', extra: cat),
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
                      padding: const EdgeInsets.all(12), // Ruang tambahan untuk outline
                      child: CatSticker(
                        image: _buildCatImage(cat.image),
                      ),
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

  Widget _buildCatImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => const Icon(Icons.error, size: 30),
      );
    } else if (imagePath.startsWith('/') || imagePath.startsWith('C:') || imagePath.startsWith('E:') || imagePath.startsWith('content:') || imagePath.contains('cat_cutout') || imagePath.contains('cache')) {
      return Image.file(File(imagePath), fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 30, color: Colors.grey));
    }
    return Image.asset(imagePath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 30, color: Colors.grey));
  }

  Widget _info(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))]);

  Widget _buildReminders(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (appState.appointments.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 280,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.75),
            itemCount: appState.appointments.length,
            itemBuilder: (context, index) {
              final appt = appState.appointments[index];
              final List<Color> colors = [const Color(0xFFFFD54F), const Color(0xFFC084FC), const Color(0xFFF48FB1)];
              final Color bg = colors[index % colors.length];

              final difference = appt.scheduledAt.difference(DateTime.now());
              String timeLeft = "";
              if (difference.isNegative) {
                timeLeft = "Passed";
              } else if (difference.inDays > 0) {
                timeLeft = "${difference.inDays} days left";
              } else if (difference.inHours > 0) {
                timeLeft = "${difference.inHours} hours left";
              } else {
                timeLeft = "${difference.inMinutes} mins left";
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(35)),
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.all(15),
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: appt.imageUrl != null 
                            ? CachedNetworkImage(
                                imageUrl: appt.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white24, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
                                errorWidget: (context, url, error) => Image.asset('assets/images/reminders background.png', fit: BoxFit.cover),
                              )
                            : Image.asset('assets/images/reminders background.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text(appt.catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: difference.isNegative ? Colors.grey : Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text(timeLeft, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(appt.type, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(_formatAppointmentDate(appt.scheduledAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  String _formatAppointmentDate(DateTime dateTime) {
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day} ${monthNames[dateTime.month - 1]} ${dateTime.year} at $hour:$minute $suffix';
  }
}

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
        // Setiap salinan dialihkan (offset) ke arah yang berbeza (Atas, Bawah, Kiri, Kanan, & Penjuru).
        for (double i = 0; i < 360; i += 45)
          Transform.translate(
            offset: Offset.fromDirection(i * 0.0174533, outlineThickness),
            child: ColorFiltered(
              // BlendMode.srcIn menukarkan semua pixel yang tidak lutsinar (kucing) 
              // kepada warna outlineColor (putih), manakala bahagian lutsinar kekal kosong.
              colorFilter: ColorFilter.mode(outlineColor, BlendMode.srcIn),
              child: image,
            ),
          ),

        // 2. GAMBAR ASAL (DI HADAPAN)
        // Gambar kucing asal diletakkan di atas lapisan putih tadi.
        image,
      ],
    );
  }
}

