import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/permission_service.dart';

class GalleryPage extends StatefulWidget {
  final Cat cat;
  const GalleryPage({super.key, required this.cat});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _addImage(ImageSource source) async {
    bool hasPermission = false;

    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.requestCameraPermission(context);
    } else {
      hasPermission = await PermissionService.requestGalleryPermission(context);
    }

    if (hasPermission) {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() => _isUploading = true);

        try {
          final File file = File(image.path);
          final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('galleries')
              .child(widget.cat.id)
              .child(fileName);
          
          await storageRef.putFile(file);
          final String downloadUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance.collection('galleries').add({
            'catId': widget.cat.id,
            'url': downloadUrl,
            'date': _getFormattedDate(),
            'timestamp': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo added successfully!')),
            );
          }
        } catch (e) {
          debugPrint("Gallery Upload Error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${e.toString().split(']').last}')),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      }
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day} ${_getMonthName(now.month)}';
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gallery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: Color(0xFF985BEF)),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('galleries')
                  .where('catId', isEqualTo: widget.cat.id)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No photos yet. Tap add to start!', style: TextStyle(color: Colors.grey)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String url = data['url'] ?? '';
                    return _buildGridImage(url);
                  },
                );
              },
            ),
          ),

          _buildBottomActions(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGridImage(String imagePath) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imagePath),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: imagePath, 
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 80),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 40),
            onPressed: () => _addImage(ImageSource.camera),
          ),
          Container(height: 40, width: 1, color: Colors.black26),
          IconButton(
            icon: const Icon(Icons.add, size: 40),
            onPressed: () => _addImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
