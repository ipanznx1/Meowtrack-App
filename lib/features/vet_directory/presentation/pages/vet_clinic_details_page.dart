import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class VetClinicDetailsPage extends StatelessWidget {
  final VetClinic clinic;
  const VetClinicDetailsPage({super.key, required this.clinic});

  Future<void> _launchWaze() async {
    final url = Uri.parse("https://waze.com/ul?ll=${clinic.lat},${clinic.lng}&navigate=yes");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchGoogleMaps() async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${clinic.lat},${clinic.lng}");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchCall() async {
    if (clinic.phone.isEmpty) return;
    final url = Uri.parse("tel:${clinic.phone.replaceAll(RegExp(r'\D'), '')}");
    await launchUrl(url);
  }

  Future<void> _launchWhatsApp() async {
    var phone = clinic.phone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return;
    if (phone.startsWith('0')) phone = '6$phone';
    final url = Uri.parse("https://wa.me/$phone");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF985BEF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(clinic.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImage(clinic.headerImage),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(clinic.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 10),
                      Row(children: [const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 4), Text(clinic.rating, style: const TextStyle(fontWeight: FontWeight.bold))]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // 🎯 FIX OVERFLOW: Menggunakan Column untuk susunan panjang ke bawah
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Today: ${clinic.hours}", 
                              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(clinic.distance, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionBtn(_launchCall, 'assets/icons/Phone Number-01.svg', 'Call', null),
                      _actionBtn(_launchWhatsApp, 'assets/images/Logo whatsapp.svg', 'WhatsApp', null),
                      _actionBtn(_launchWaze, 'assets/images/waze.png', 'Waze', null),
                      _actionBtn(_launchGoogleMaps, 'assets/images/Google_Maps_icon_(2020).svg', 'Maps', null),
                    ],
                  ),

                  const SizedBox(height: 30),
                  // 🎯 BOOK APPOINTMENT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/add-appointment', extra: {
                          'title': 'Visit to ${clinic.name}',
                          'location': clinic.description, // Vicinity is stored here in the model
                          'lat': clinic.lat,
                          'lng': clinic.lng,
                        });
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.white),
                      label: const Text("Schedule Visit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF985BEF),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(clinic.description, style: const TextStyle(color: Colors.black87, height: 1.5)),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews from Google', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${clinic.reviews.length} reviews', style: const TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (clinic.reviews.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No reviews found for this clinic.', style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    ...clinic.reviews.map((r) => _reviewCard(r)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) return Container(height: 220, color: Colors.grey[200], child: const Icon(Icons.pets, size: 50));
    return Image.network(
      url, 
      height: 220, 
      width: double.infinity, 
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(height: 220, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 50)),
    );
  }

  Widget _actionBtn(VoidCallback onTap, String asset, String label, Color? tint) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 60, width: 60,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: (asset.endsWith('.svg'))
              ? SvgPicture.asset(asset, width: 30, height: 30, colorFilter: tint != null ? ColorFilter.mode(tint, BlendMode.srcIn) : null)
              : Image.asset(asset, width: 30, height: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final double rating = (r['rating'] is num) ? (r['rating'] as num).toDouble() : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 15, backgroundColor: Color(0xFF985BEF), child: Icon(Icons.person, size: 15, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(child: Text(r['name'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Text(r['time'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating ? Colors.amber : Colors.grey[300]))),
          const SizedBox(height: 8),
          Text(r['comment'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
