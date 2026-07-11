import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  // Mock Data State
  String name = "Irfan Kasfi";
  String email = "Irfan.Kasfi@gmail.com";
  String password = "**********";
  String phone = "012-3456789";

  // Editing States
  bool isEditingName = false;
  bool isEditingEmail = false;
  bool isEditingPassword = false;
  bool isEditingPhone = false;

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
          "Account Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // 1. PROFILE PICTURE WITH EDIT ICON
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 100, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF985BEF),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset('assets/icons/Camera.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 2. DATA ROWS
            _buildEditableRow("Name", name, isEditingName, (val) => name = val, () {
              setState(() => isEditingName = !isEditingName);
            }),
            const SizedBox(height: 20),
            _buildEditableRow("Email", email, isEditingEmail, (val) => email = val, () {
              setState(() => isEditingEmail = !isEditingEmail);
            }),
            const SizedBox(height: 20),
            _buildEditableRow("Password", password, isEditingPassword, (val) => password = val, () {
              setState(() => isEditingPassword = !isEditingPassword);
            }, isPassword: true),
            const SizedBox(height: 20),
            _buildEditableRow("Number Phone", phone, isEditingPhone, (val) => phone = val, () {
              setState(() => isEditingPhone = !isEditingPhone);
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(
      String label, 
      String value, 
      bool isEditing, 
      Function(String) onSave, 
      VoidCallback onToggle, 
      {bool isPassword = false}
    ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
                        autofocus: true,
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: onSave,
                        obscureText: isPassword,
                      )
                    : Text(
                        value,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
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
