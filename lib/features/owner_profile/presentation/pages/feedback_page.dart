import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final Map<String, double> _ratings = {
    'Meowtrack Usage': 5.0,
    'AR Education': 5.0,
    'Real-Time Tracking': 5.0,
    'Emergency Button': 5.0,
    'Vet Dictionary': 5.0,
    'Battery & Device': 5.0,
    'Overall Design': 5.0,
  };

  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      await appState.submitFeedback(_ratings, _commentController.text.trim());
      if (mounted) {
        MeowAnimatedDialog.show(
          context,
          animationPath: 'assets/animations/feedback.json',
          title: "Terima Kasih!",
          description: "Maklum balas anda sangat membantu kami memperbaiki aplikasi.",
          themeColor: Colors.teal,
          onConfirm: () => context.pop(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
        title: const Text("Feedback", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            ..._ratings.keys.map((key) => _buildRatingSection(key, _getLabelForKey(key))),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Anything else?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: TextField(controller: _commentController, maxLines: 4, decoration: const InputDecoration(hintText: "Tell us...", border: InputBorder.none)),
            ),
            const SizedBox(height: 40),
            Center(
              child: _isSubmitting ? const CircularProgressIndicator(color: Color(0xFF985BEF)) : ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF), minimumSize: const Size(200, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: const Text("Submit Feedback", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String key, String title) {
    int rating = _ratings[key]!.toInt();
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(
            children: List.generate(5, (index) {
              int scale = index + 1;
              bool isSelected = scale == rating;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _ratings[key] = scale.toDouble()),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: isSelected ? 1.0 : 0.3,
                        child: SvgPicture.asset('assets/icons/FEEDBACK $scale.svg', width: 40, height: 40),
                      ),
                      const SizedBox(height: 4),
                      Text("$scale", style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF985BEF) : Colors.grey)),
                    ],
                  ),
                ),
              );
            }),
          ),
          Slider(value: _ratings[key]!, min: 1, max: 5, divisions: 4, activeColor: const Color(0xFF985BEF), onChanged: (val) => setState(() => _ratings[key] = val)),
        ],
      ),
    );
  }

  String _getLabelForKey(String key) {
    switch (key) {
      case 'Meowtrack Usage': return "How do you feel using Meowtrack today?";
      case 'AR Education': return "Interactive experience of AR Software and Overlays";
      case 'Real-Time Tracking': return "Reliability of location updates";
      case 'Emergency Button': return "Trust in safety features";
      case 'Vet Dictionary': return "Usefulness of medical information";
      case 'Battery & Device': return "Overall stability and connection";
      default: return "Look and feel of the interface";
    }
  }
}
