import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/permission_service.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class ReportLostCatScreen extends StatefulWidget {
  const ReportLostCatScreen({super.key});

  @override
  State<ReportLostCatScreen> createState() => _ReportLostCatScreenState();
}

class _ReportLostCatScreenState extends State<ReportLostCatScreen> {
  LatLng? _pinnedLocation;
  GoogleMapController? _mapController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  bool _isRegistered = true;
  String? _selectedCatName;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _pinnedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _handleBroadcast() async {
    final catName = _isRegistered ? _selectedCatName : _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descriptionController.text.trim();
    final reward = _rewardController.text.trim();

    if (catName == null || catName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila masukkan atau pilih nama kucing')));
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila masukkan nombor telefon')));
      return;
    }
    if (_pinnedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila tandakan lokasi di peta')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      bool isVerified = false;
      
      // If image selected manually, upload it
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('community_posts')
            .child('lost_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      } else if (_isRegistered) {
        // Use cat's profile image if registered and no manual image picked
        final cat = appState.cats.firstWhere((c) => c.name == catName);
        imageUrl = cat.image;
        isVerified = true;
      }

      final fullContent = "Bantu kami! Kucing bernama $catName telah hilang. ${description.isNotEmpty ? '\n\nMaklumat tambahan: $description' : ''} ${reward.isNotEmpty ? '\n\n💰 Ganjaran: RM$reward' : ''}";

      await FirebaseFirestore.instance.collection('community_posts').add({
        'author': appState.userName ?? 'User',
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'title': 'KUCING HILANG: $catName',
        'content': fullContent,
        'category': 'Lost & found',
        'locationLabel': 'Lokasi Terakhir Dilihat',
        'lat': _pinnedLocation!.latitude,
        'lng': _pinnedLocation!.longitude,
        'phone': phone,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Lost',
        'isFlagged': false,
        'reportCount': 0,
        'reportedBy': [],
        'isVerified': isVerified,
        'imageUrl': imageUrl,
        'reward': reward,
      });

      appState.setMyCatLost();

      if (mounted) {
        MeowAnimatedDialog.show(
          context,
          animationPath: 'assets/animations/lost_cat.json',
          title: "Hebahan Dibuat!",
          description: "Info kehilangan $catName sedang disebarkan kepada komuniti Meowtrack berdekatan.",
          buttonText: "Moga Cepat Jumpa",
          themeColor: Colors.redAccent,
          onConfirm: () => context.pop(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ralat: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD0E0FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const Text('Help Us Find Your Cat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                
                // Map for Pinning Location
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: _pinnedLocation == null 
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(target: _pinnedLocation!, zoom: 15),
                          onMapCreated: (controller) => _mapController = controller,
                          onTap: (pos) => setState(() => _pinnedLocation = pos),
                          markers: {
                            Marker(
                              markerId: const MarkerId('lost_cat_pin'),
                              position: _pinnedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                          },
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Tap on map to pin exact last seen location', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),

                const SizedBox(height: 30),
                _buildLabel('Status'),
                Row(
                  children: [
                    _choiceChip('Registered Cat', _isRegistered, () => setState(() => _isRegistered = true)),
                    const SizedBox(width: 10),
                    _choiceChip('Unregistered Cat', !_isRegistered, () => setState(() => _isRegistered = false)),
                  ],
                ),

                const SizedBox(height: 20),
                if (_isRegistered) ...[
                  _buildLabel('Select your cat'),
                  _buildCatDropdown(),
                ] else ...[
                  _buildLabel('Cat\'s Name (Temporary)'),
                  _buildInputBox(_nameController, 'Enter cat name...'),
                ],

                const SizedBox(height: 20),
                _buildLabel('Nombor Telefon Kecemasan'),
                _buildInputBox(_phoneController, 'Contoh: 0123456789', keyboardType: TextInputType.phone),

                const SizedBox(height: 20),
                _buildLabel('Ganjaran (Opsional)'),
                _buildInputBox(_rewardController, 'Contoh: 500', keyboardType: TextInputType.number, suffixText: 'RM'),

                const SizedBox(height: 20),
                _buildLabel('Keterangan Tambahan'),
                _buildInputBox(_descriptionController, 'Warna kolar, lokasi spesifik, perwatakan, dll...', maxLines: 3),

                const SizedBox(height: 30),
                _buildLabel('Muat Naik Gambar Terkini (PENTING)'),
                _buildImagePicker(),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleBroadcast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, 
                    minimumSize: const Size(double.infinity, 56), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                  ),
                  child: const Text('Broadcast Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _choiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF985BEF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildCatDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('Select cat'),
        value: _selectedCatName,
        items: appState.cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
        onChanged: (v) => setState(() => _selectedCatName = v),
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, String? suffixText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller, 
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint, 
          border: InputBorder.none,
          suffixText: suffixText,
          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        )
      ),
    );
  }

  Widget _buildLabel(String l) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () async {
        if (await PermissionService.requestGalleryPermission(context)) {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
          if (image != null) {
            setState(() => _selectedImage = File(image.path));
          }
        }
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: _selectedImage != null
          ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_selectedImage!, fit: BoxFit.cover))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text('Tap to select photo', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
      ),
    );
  }
}
