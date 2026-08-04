import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meow_track/core/app_state.dart';

class ModeratorPlatformDashboard extends StatefulWidget {
  const ModeratorPlatformDashboard({super.key});

  @override
  State<ModeratorPlatformDashboard> createState() => _ModeratorPlatformDashboardState();
}

class _ModeratorPlatformDashboardState extends State<ModeratorPlatformDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  String _selectedPopupType = 'text_only';

  @override
  void dispose() {
    _announcementController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // --- LOGIK KEMASKINI SISTEM ---
  Future<void> _updateSystemStatus(bool maintenance) async {
    await FirebaseFirestore.instance.collection('app_settings').doc('system_status').set({
      'maintenanceMode': maintenance,
      'flashAnnouncement': _announcementController.text.trim(),
      'popupImageUrl': _imageUrlController.text.trim(),
      'popupType': _selectedPopupType,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': 'SuperAdmin'
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status Sistem Berjaya Dikemaskini!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: !isWide ? Drawer(child: _buildSidebar()) : null,
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBodyContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, color: Color(0xFF985BEF), size: 35),
              SizedBox(width: 15),
              Text("MEOWTRACK HQ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 50),
          _sidebarItem(0, Icons.analytics_outlined, 'Overview & Stats'),
          _sidebarItem(5, Icons.settings_suggest_outlined, 'System Controls'), // Tab System Settings
          const Spacer(),
          _sidebarItem(99, Icons.logout_rounded, 'Logout'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        onTap: () => setState(() => _selectedIndex = index),
        leading: Icon(icon, color: isSelected ? const Color(0xFF985BEF) : Colors.blueGrey[300]),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey[300], fontSize: 14)),
        tileColor: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("HQ Platform Control Centre", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text("SuperAdmin Meowtrack", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Color(0xFF0F172A))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedIndex == 5) return _viewSystemControls();
    return const Center(child: Text("Select a tab from Sidebar"));
  }

  // --- SUB-VIEW: SYSTEM CONTROLS (REAL-TIME) ---
  Widget _viewSystemControls() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('app_settings').doc('system_status').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        bool maintenance = data['maintenanceMode'] ?? false;
        
        // Update controllers if not focused
        if (!_announcementController.selection.isValid) {
          _announcementController.text = data['flashAnnouncement'] ?? '';
          _imageUrlController.text = data['popupImageUrl'] ?? '';
          _selectedPopupType = data['popupType'] ?? 'text_only';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Global Maintenance & Announcement Control", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              // MAINTENANCE SWITCH
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: SwitchListTile.adaptive(
                  activeColor: Colors.red,
                  title: Text(maintenance ? "MAINTENANCE ACTIVE (Mobile Blocked)" : "SYSTEM ONLINE", style: TextStyle(fontWeight: FontWeight.w900, color: maintenance ? Colors.red : Colors.green)),
                  subtitle: const Text("Apabila dihidupkan, pengguna aplikasi telefon tidak dapat masuk ke sistem."),
                  value: maintenance,
                  onChanged: (val) => _updateSystemStatus(val),
                ),
              ),
              
              const SizedBox(height: 30),

              // DYNAMIC POP-UP CONTROLS
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Dynamic Pop-up Configuration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedPopupType,
                      decoration: const InputDecoration(labelText: "Pop-up Content Type", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'text_only', child: Text("Text Only")),
                        DropdownMenuItem(value: 'poster_only', child: Text("Poster Only")),
                        DropdownMenuItem(value: 'text_and_poster', child: Text("Text & Poster Hybrid")),
                      ],
                      onChanged: (v) => setState(() => _selectedPopupType = v!),
                    ),
                    
                    const SizedBox(height: 20),
                    TextField(
                      controller: _announcementController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: "Announcement Message", border: OutlineInputBorder(), hintText: "Enter message here..."),
                    ),
                    
                    const SizedBox(height: 20),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: "Poster Image URL", border: OutlineInputBorder(), hintText: "https://example.com/poster.jpg"),
                    ),
                    
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () => _updateSystemStatus(maintenance),
                        child: const Text("Save & Publish to Mobile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
