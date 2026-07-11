import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class Purrmate {
  final String name;
  final String username;
  final String purrCode;
  final bool isCoOwner;
  final String bio;

  Purrmate({
    required this.name,
    required this.username,
    required this.purrCode,
    this.isCoOwner = false,
    this.bio = "",
  });
}

class PurrmatesPage extends StatefulWidget {
  const PurrmatesPage({super.key});

  @override
  State<PurrmatesPage> createState() => _PurrmatesPageState();
}

class _PurrmatesPageState extends State<PurrmatesPage> {
  final List<Purrmate> _allPurrmates = [
    Purrmate(name: "Sarah Amelia", username: "@sarah_cats", purrCode: "19080287", isCoOwner: true),
    Purrmate(name: "Ahmad Syafiq", username: "@ahmad_syafiq1", purrCode: "29080287"),
    Purrmate(name: "Nadia Rosli", username: "@nad_fluffy", purrCode: "29046587"),
    Purrmate(name: "Faiz Subri", username: "@faiz_99", purrCode: "45380287"),
  ];

  void _showAddPurrmateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Center(child: Text("Add New Purr-mates", style: TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your friend's unique Username or Care Code to send a connection request.", 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Enter Username / Code...",
                  border: InputBorder.none,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset('assets/icons/Search....svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 20, height: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF985BEF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coOwners = _allPurrmates.where((p) => p.isCoOwner).toList();
    final friends = _allPurrmates.where((p) => !p.isCoOwner).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
        title: const Text("My Purr-mates", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search my Purr-mates...",
                      border: InputBorder.none,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SvgPicture.asset('assets/icons/Search....svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 20, height: 20),
                      ),
                    ),
                  ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 35, height: 35, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
                  onPressed: _showAddPurrmateDialog,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filterChip("All Friends (12)", true),
                _filterChip("Paws Pending (2)", false),
                _filterChip("Co-Owners", false),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Co-Owners (1)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...coOwners.map((p) => _buildContactCard(p)),
                const SizedBox(height: 25),
                const Text("All Friends (12)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...friends.map((p) => _buildContactCard(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[300] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildContactCard(Purrmate p) {
    return GestureDetector(
      onTap: () => context.push('/purrmate-profile', extra: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            if (p.name == "Sarah Amelia")
              const CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/images/Sarah amelia.png'))
            else
              CircleAvatar(
                radius: 25, 
                backgroundColor: const Color(0xFFF5F5F5), 
                child: SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 25, height: 25, colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn))
              ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${p.name} (${p.username})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(p.isCoOwner ? "Co-Parent for 'Luna'" : "Owner of Oyen & Tom", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text("Purr code : ${p.purrCode}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              child: SvgPicture.asset('assets/icons/Back.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
            ),
          ],
        ),
      ),
    );
  }
}
