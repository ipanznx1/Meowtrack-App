import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meow_track/core/app_state.dart';

class GalleryPage extends StatefulWidget {
  final Cat cat;
  const GalleryPage({super.key, required this.cat});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();
  
  // Simulated gallery data grouped by date
  Map<String, List<String>> galleryData = {
    'Today': [
      'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=500',
    ],
    'Yesterday': [
      'https://images.unsplash.com/photo-1573865526739-10659fec78a5?q=80&w=500',
    ],
    '3 January': [
      'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?q=80&w=500',
    ],
  };

  Future<void> _addImage(ImageSource source) async {
    // 1. Handle Permissions
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // For modern Android/iOS, storage permission handling varies, 
      // but image_picker handles most basic cases. We'll check general status.
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          // In a real app, we'd save the local path. 
          // For this demo, we add the path to our 'Today' list.
          galleryData['Today']?.insert(0, image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added to "Today"')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera/Gallery permission is required to add photos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic theme color mapping based on cat profile
    Color backgroundColor = widget.cat.themeColor;
    if (widget.cat.name == "Luna") {
      backgroundColor = const Color(0xFFC4D4EC); // Soft Pastel Blue/Grey
    }

    return Scaffold(
      backgroundColor: backgroundColor,
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Color(0xFF985BEF)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.tune, color: Color(0xFF985BEF)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: galleryData.keys.length,
              itemBuilder: (context, index) {
                String date = galleryData.keys.elementAt(index);
                List<String> images = galleryData[date]!;
                return _buildGallerySection(date, images);
              },
            ),
          ),

          // Bottom Action Bar
          _buildBottomActions(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGallerySection(String date, List<String> images) {
    return Column(
      children: [
        Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return _buildStackedImage(images[index]);
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStackedImage(String imagePath) {
    bool isUrl = imagePath.startsWith('http');
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: isUrl 
          ? Image.network(imagePath, fit: BoxFit.cover)
          : Image.file(File(imagePath), fit: BoxFit.cover),
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
          Container(height: 40, width: 1, color: Colors.black26), // Vertical Divider
          IconButton(
            icon: const Icon(Icons.add, size: 40),
            onPressed: () => _addImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
