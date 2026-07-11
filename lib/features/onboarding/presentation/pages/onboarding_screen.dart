import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/widgets/image_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Learn & Explore in Augmented Reality (AR)',
      'description':
          'Discover the world of cats like never before. Use Augmented Reality to learn about health in an interactive, 3D environment.',
      'image': 'assets/images/Unity.png',
    },
    {
      'title': 'Smart Tracking & Records',
      'description':
          'Never lose sight of your furry friends. Monitor their Live Location and keep a digital diary of their medical history, vaccinations, and daily weight.',
      'image': 'assets/images/SPLASH 2 LATEST.png',
    },
    {
      'title': 'Emergency & Vet Support',
      'description':
          'Peace of mind in your pocket. Instantly find Nearby Vet Clinics and use the SOS Alert to get help from the community if your cat ever goes missing.',
      'image': 'assets/images/SPLASH 3 LATEST.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND LAYER
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _currentPage == 0
                  ? Container(
                      key: const ValueKey('bg_gradient'),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF985BEF), Colors.white],
                          stops: [0.0, 0.45],
                        ),
                      ),
                    )
                  : Image.asset(
                      _onboardingData[_currentPage]['image']!,
                      key: ValueKey('bg_image_$_currentPage'),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),

          // 2. CONTENT LAYER
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          // Only show centered image for the first page (Unity)
                          // For page 2 & 3, the image is already the background
                          index == 0
                              ? SizedBox(
                                  height: 350,
                                  child: Image.asset(
                                    _onboardingData[index]['image']!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const SizedBox(height: 350),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              children: [
                                Text(
                                  _onboardingData[index]['title']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: index == 0 ? Colors.black : Colors.black, // Tetap hitam jika background cerah, atau putih jika gelap
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _onboardingData[index]['description']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: index == 0 ? Colors.grey[800] : Colors.grey[800],
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 3),
                        ],
                      );
                    },
                  ),
                ),
                
                // BOTTOM ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _onboardingData.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            context.go('/auth-gateway');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF985BEF),
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                          elevation: 0,
                        ),
                        child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 40),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => buildDot(index: index),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot({required int index}) {
    final bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 12),
      height: isActive ? 20 : 12,
      width: isActive ? 20 : 12,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF985BEF) : const Color(0xFFD9D9D9),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
