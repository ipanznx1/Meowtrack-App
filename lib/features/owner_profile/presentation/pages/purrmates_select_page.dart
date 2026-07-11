import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/features/owner_profile/presentation/pages/purrmates_page.dart';

class PurrmatesSelectPage extends StatelessWidget {
  PurrmatesSelectPage({super.key});

  final List<Purrmate> _friends = [
    Purrmate(name: "Sarah Amelia", username: "@sarah_cats", purrCode: "19080287"),
    Purrmate(name: "Ahmad Syafiq", username: "@ahmad_syafiq1", purrCode: "29080287"),
    Purrmate(name: "Nadia Rosli", username: "@nad_fluffy", purrCode: "29046587"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
        title: const Text("Select Friend", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return GestureDetector(
                  onTap: () => context.pop(friend),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        if (friend.name == "Sarah Amelia")
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
                              Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend.username, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
