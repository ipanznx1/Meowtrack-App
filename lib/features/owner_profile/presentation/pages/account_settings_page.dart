import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/router/app_router.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isEditingName = false;
  bool isEditingEmail = false;
  bool isEditingPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...')));
      await appState.uploadProfilePicture(File(pickedFile.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    }
  }

  Future<void> _handleReauth() async {
    final passwordController = TextEditingController();
    bool success = false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Security Verification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please enter your current password to continue."),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await appState.reauthenticateUser(appState.userEmail ?? '', passwordController.text);
                success = true;
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password.')));
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );

    if (!success) throw Exception("Verification failed");
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    await appState.updateProfile(username: _nameController.text.trim());
    setState(() => isEditingName = false);
    if (mounted) {
      MeowAnimatedDialog.show(
        context,
        animationPath: 'assets/animations/save_settings.json',
        title: "Nama Dikemaskini",
        description: "Nama profil anda telah berjaya ditukar.",
        themeColor: Colors.green,
      );
    }
  }

  Future<void> _saveEmail() async {
    if (_emailController.text.trim().isEmpty) return;
    try {
      await _handleReauth();
      await appState.updateProfile(newEmail: _emailController.text.trim());
      setState(() => isEditingEmail = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated!')));
    } catch (e) {
      // Reauth failed or error updating
    }
  }

  Future<void> _savePassword() async {
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
      return;
    }
    try {
      await _handleReauth();
      await FirebaseAuth.instance.currentUser?.updatePassword(_passwordController.text.trim());
      setState(() => isEditingPassword = false);
      _passwordController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!')));
    } catch (e) {
      // Reauth failed or error updating
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFEFEFEF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Account Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        backgroundImage: (appState.avatarUrl != null && appState.avatarUrl!.isNotEmpty)
                            ? NetworkImage(appState.avatarUrl!)
                            : const AssetImage('assets/images/Luna.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFF985BEF), shape: BoxShape.circle),
                            child: SvgPicture.asset('assets/icons/Camera.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                _buildEditableRow(
                  label: "Name",
                  value: appState.userName ?? "User",
                  isEditing: isEditingName,
                  controller: _nameController,
                  onToggle: () {
                    if (isEditingName) {
                      _saveName();
                    } else {
                      _nameController.text = appState.userName ?? "";
                      setState(() => isEditingName = true);
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildEditableRow(
                  label: "Email",
                  value: appState.userEmail ?? "",
                  isEditing: isEditingEmail,
                  controller: _emailController,
                  onToggle: () {
                    if (isEditingEmail) {
                      _saveEmail();
                    } else {
                      _emailController.text = appState.userEmail ?? "";
                      setState(() => isEditingEmail = true);
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildEditableRow(
                  label: "Password",
                  value: "**********",
                  isEditing: isEditingPassword,
                  controller: _passwordController,
                  isPassword: true,
                  onToggle: () {
                    if (isEditingPassword) {
                      _savePassword();
                    } else {
                      _passwordController.clear();
                      setState(() => isEditingPassword = true);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 🎯 BAHAGIAN TUKAR ROLE (Hanya muncul jika ada > 1 role)
                if (appState.availableRoles.length > 1) ...[
                  _buildRoleSwitcher(),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleSwitcher() {
    final currentRole = appState.sessionRole ?? "user";
    final otherRole = appState.availableRoles.firstWhere((r) => r != currentRole, orElse: () => "");

    if (otherRole.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Role Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sesi Semasa: ${currentRole.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF985BEF))),
                    const Text("Akaun anda mempunyai pelbagai peranan akses.",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  appState.setSessionRole(otherRole);
                  final nextRoute = await appState.resolvePostLoginRoute();
                  if (mounted) context.go(nextRoute);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                ),
                child: Text("Tukar ke $otherRole", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow({
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onToggle,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(border: InputBorder.none),
                        obscureText: isPassword,
                      )
                    : Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ),
              ElevatedButton(
                onPressed: onToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? "Save" : "Change",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
