import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class PurrmateProfilePage extends StatelessWidget {
  final Purrmate purrmate;
  const PurrmateProfilePage({super.key, required this.purrmate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CircleAvatar(radius: 60, backgroundColor: Colors.white, child: SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 80, height: 80, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn))),
            const SizedBox(height: 15),
            Text(purrmate.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Senior Cat Owner", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => context.push('/owner-chat', extra: purrmate.name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 25),
            _buildStatBar(),
            const SizedBox(height: 25),
            _buildSection("Care Credibility & Experiences", _buildCredibilityCard()),
            const SizedBox(height: 25),
            _buildSection("Rank", _buildRankCard()),
            const SizedBox(height: 25),
            _buildSection("Total pets", _buildPetsRow()),
            if (purrmate.isCoOwner) ...[
              const SizedBox(height: 25),
              _buildSection("Co- owners", _buildCoOwnerGrid()),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(child: Column(children: [const Text("Username", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(purrmate.username, style: const TextStyle(fontSize: 12))])),
          Container(height: 30, width: 1, color: Colors.grey[300]),
          Expanded(child: Column(children: [const Text("Purr code", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(purrmate.purrCode, style: const TextStyle(fontSize: 12))])),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildCredibilityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Experience", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text("Cat Owner for 4+ Years", style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 15),
          Text("Home Environment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text("Fully Indoor, No Kids, Air-Conditioned", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRankCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn)),
          const SizedBox(width: 10),
          const Text("Cat Guardian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          Column(
            children: [
              SizedBox(width: 100, child: LinearProgressIndicator(value: 0.3, color: Colors.purple[300], backgroundColor: Colors.grey[200])),
              const Text("30%", style: TextStyle(fontSize: 8)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPetsRow() {
    return Row(
      children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("2", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 10),
        _petMiniCard("Tom", Colors.blue[100]!),
        const SizedBox(width: 10),
        _petMiniCard("Oyen", Colors.orange[100]!),
      ],
    );
  }

  Widget _petMiniCard(String name, Color color) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCoOwnerGrid() {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(color: Colors.yellow[100], borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 24, height: 24, color: Colors.white),
          const SizedBox(height: 5),
          Text("Luna", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
