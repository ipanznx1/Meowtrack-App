import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // State for each rating category (1 to 5)
  final Map<String, double> _ratings = {
    'Meowtrack Usage': 1.0,
    'AR Education': 1.0,
    'Real-Time Tracking': 1.0,
    'Emergency Button': 1.0,
    'Vet Dictionary': 1.0,
    'Battery & Device': 1.0,
    'Overall Design': 1.0,
  };

  final TextEditingController _commentController = TextEditingController();

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
        title: const Text(
          "Feedback",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingSection(
              "How do you feel using Meowtrack today?",
              "",
              'Meowtrack Usage',
            ),
            _buildRatingSection(
              "Augmented Reality (AR) Education",
              "How would you rate the interactive experience of the AR Software and AR Overlays?",
              'AR Education',
            ),
            _buildRatingSection(
              "Real-Time Tracking",
              "How reliable do you find the location updates when monitoring your cat's movement?",
              'Real-Time Tracking',
            ),
            _buildRatingSection(
              "Emergency Button & Safety",
              "How much do you trust the app's safety features to protect your cat in case of an emergency?",
              'Emergency Button',
            ),
            _buildRatingSection(
              "Vet Dictionary",
              "How useful is the vet directory and medical information in managing your cat's healthcare?",
              'Vet Dictionary',
            ),
            _buildRatingSection(
              "Battery & Device Management",
              "How satisfied are you with the app's overall stability and device connection?",
              'Battery & Device',
            ),
            _buildRatingSection(
              "Overall Design",
              "How would you rate the overall look and feel of the Meowtrack interface?",
              'Overall Design',
            ),
            const SizedBox(height: 20),
            const Text(
              "Anything else you want to tell us?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Tell us...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thank you for your feedback!")),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, String subtitle, String key) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
          const SizedBox(height: 15),
          _buildCatEmojiRow(_ratings[key]!.toInt()),
          Slider(
            value: _ratings[key]!,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: const Color(0xFF985BEF),
            inactiveColor: Colors.grey[200],
            onChanged: (val) {
              setState(() {
                _ratings[key] = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCatEmojiRow(int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        bool isActive = (index + 1) == rating;
        return SvgPicture.asset(
          'assets/icons/FEEDBACK ${index + 1}.svg',
          width: 40,
          height: 40,
          colorFilter: ColorFilter.mode(
            isActive ? const Color(0xFF985BEF) : const Color(0xFF985BEF).withValues(alpha: 0.3), 
            BlendMode.srcIn
          ),
        );
      }),
    );
  }
}
