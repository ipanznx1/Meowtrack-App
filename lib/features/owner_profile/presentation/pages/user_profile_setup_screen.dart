import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/permission_service.dart';
import 'package:meow_track/router/app_router.dart';
import 'package:meow_track/core/utils/storage_helper.dart';

class UserProfileSetupScreen extends StatefulWidget {
  final bool isEditing;
  const UserProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<UserProfileSetupScreen> createState() => _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState extends State<UserProfileSetupScreen> {
  File? _imageFile;
  String? _currentAvatarUrl;
  bool _isLoading = false;
  final String _defaultCatAvatar = 'assets/images/Luna.png'; // Guna asset sedia ada

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentAvatarUrl = doc.data()?['avatarUrl'];
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.requestCameraPermission(context);
    } else {
      hasPermission = await PermissionService.requestGalleryPermission(context);
    }

    if (hasPermission) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _imageFile = null;
      _currentAvatarUrl = 'DEFAULT_CAT'; // Flag untuk guna avatar kucing
    });
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalUrl = _currentAvatarUrl;

      // 1. Proses & Upload menggunakan StorageHelper jika ada gambar baru
      if (_imageFile != null) {
        finalUrl = await StorageHelper.processAndUpload(
          originalFile: _imageFile!,
          folder: 'user_avatars',
          uid: user.uid,
          name: 'profile_pic.jpg',
        );
      } else if (_currentAvatarUrl == 'DEFAULT_CAT') {
        finalUrl = '';
      }

      // 2. Update Firestore
      final purrCode = appState.purrCode ?? appState.generatePurrCode();
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'avatarUrl': finalUrl,
        'isProfileSetup': true,
        'purrCode': purrCode,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 🎯 Update global state immediately supaya UI refresh serta-merta
      appState.avatarUrl = finalUrl;
      appState.isProfileSetup = true;
      appState.notifyListeners();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        if (widget.isEditing) {
          context.pop();
        } else {
          context.go(AppRouter.dashboard);
        }
      }
    } catch (e) {
      print("Error saving profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'Setup Your Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty && _currentAvatarUrl != 'DEFAULT_CAT'
                            ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                            : AssetImage(_defaultCatAvatar)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showPickerOptions(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Color(0xFF985BEF), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildOptionTile(
                icon: Icons.pets,
                label: 'Use Default Cat Avatar',
                onTap: _resetToDefault,
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save & Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF985BEF)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[300]!)),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
          ],
        ),
      ),
    );
  }
}
