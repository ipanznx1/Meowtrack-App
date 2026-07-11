import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'purrmates_page.dart';

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  bool _isManaging = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFEFEFEF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
              onPressed: () => context.pop(),
            ),
            title: const Text("My Household", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              // 1. MANAGE BUTTON
              Center(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isManaging = !_isManaging),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    minimumSize: const Size(200, 45),
                  ),
                  child: Text(
                    _isManaging ? "Done" : "Manage",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // 2. CAT GRID (Image 3 style)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: appState.cats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 25,
                    childAspectRatio: 0.6, // Taller for Image 3 style
                  ),
                  itemBuilder: (context, index) {
                    return _buildCatCard(appState.cats[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatCard(Cat cat) {
    // Simulated collar colors
    Color collarColor = Colors.grey;
    if (cat.name == "Luna") collarColor = Colors.red;
    if (cat.name == "Oyen") collarColor = Colors.orange;
    if (cat.name == "Bella") collarColor = Colors.blue;
    if (cat.name == "Tuteh") collarColor = Colors.pinkAccent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Top Part: Colored Background + Image
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cat.themeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(cat.image, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          
          // Bottom Part: Info
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const Spacer(),
                  
                  // Management Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: const Text("Edit Details", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      Container(width: 15, height: 15, decoration: BoxDecoration(color: collarColor, shape: BoxShape.circle)),
                      SvgPicture.asset('assets/icons/Delete.svg', width: 18, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Share Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF985BEF),
                      minimumSize: const Size(double.infinity, 35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text("Share", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
