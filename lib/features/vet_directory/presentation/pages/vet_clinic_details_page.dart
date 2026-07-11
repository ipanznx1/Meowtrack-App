import 'package:flutter/material.dart';
import 'package:meow_track/core/app_state.dart';

class VetClinicDetailsPage extends StatelessWidget {
  final VetClinic clinic;
  const VetClinicDetailsPage({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    final gallery = clinic.gallery;
    final List<String> display = List<String>.generate(3, (i) => i < gallery.length ? gallery[i] : clinic.headerImage);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(clinic.name, style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(clinic.headerImage, height: 220, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(clinic.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGalleryItem(display[0]),
                      const SizedBox(width: 10),
                      _buildGalleryItem(display[1]),
                      const SizedBox(width: 10),
                      _buildGalleryItem(display[2]),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Distance', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(clinic.distance, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Open hours', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(clinic.hours, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: Text('Call ${clinic.phone}'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryItem(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
    );
  }
}
