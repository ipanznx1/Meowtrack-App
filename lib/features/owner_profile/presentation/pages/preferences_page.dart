import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/pages/not_implemented_page.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30, height: 30),
          onPressed: () => context.pop(),
        ),
        title: const Text("Preferences", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            // Unit Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  _buildUnitRow(
                    "Weight Unit", 
                    'assets/icons/Weight Unit.svg', 
                    "Kilograms (kg)", 
                    "Pounds (lbs)", 
                    state.isKg, 
                    (val) => state.setWeightUnit(val)
                  ),
                  const SizedBox(height: 25),
                  _buildUnitRow(
                    "Distance Unit", 
                    'assets/icons/Distance Unit.svg', 
                    "Meters / Kilometers", 
                    "Feet / Miles", 
                    state.isMeters, 
                    (val) => state.setDistanceUnit(val)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("System", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            // System Card
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  _buildNavRow("Safe Zone Radius", 'assets/icons/Safe Zone Radius.svg', () => context.push('/preferences/safe-zone')),
                  const Divider(height: 1, indent: 60),
                  _buildNavRow("Tracking Frequency", 'assets/icons/Tracking Frequency.svg', () => context.push('/preferences/tracking-freq')),
                  const Divider(height: 1, indent: 60),
                  _buildNavRow("Notifications", 'assets/icons/Notification.svg', () => context.push('/preferences/notifications')),
                  const Divider(height: 1, indent: 60),
                  _buildNavRow("My privacy", 'assets/icons/My privacy.svg', () => context.push('/preferences/privacy')),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotImplementedPage(title: 'Preferences - Action'))),
              icon: SvgPicture.asset('assets/icons/Delete.svg', colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 20, height: 20),
              label: const Text("Delete Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitRow(String label, String svgAsset, String option1, String label2, bool isFirstActive, Function(bool) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(svgAsset, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _unitBtn(option1, isFirstActive, () => onChanged(true))),
            Expanded(child: _unitBtn(label2, !isFirstActive, () => onChanged(false))),
          ],
        ),
      ],
    );
  }

  Widget _unitBtn(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF985BEF) : Colors.grey[300],
          borderRadius: label.contains("kg") || label.contains("Kilometers") 
              ? const BorderRadius.horizontal(left: Radius.circular(10)) 
              : const BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Center(
          child: Text(
            label, 
            style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }

  Widget _buildNavRow(String title, String svgAsset, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: SvgPicture.asset(svgAsset, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

// --------------------------------------------------------------------------
// SUB-SCREEN 1: SAFE ZONE RADIUS
// --------------------------------------------------------------------------
class SafeZoneRadiusPage extends StatelessWidget {
  const SafeZoneRadiusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: IconButton(
                  icon: SvgPicture.asset('assets/icons/Back.svg', color: const Color(0xFF985BEF), width: 40, height: 40),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Safe Zone Radius", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const Text("0m", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: state.safeZoneRadius,
                      min: 0,
                      max: 500,
                      activeColor: const Color(0xFF985BEF),
                      inactiveColor: Colors.grey[300],
                      onChanged: (v) => state.setSafeZoneRadius(v),
                    ),
                  ),
                  const Text("500m", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Center(child: Text(state.safeZoneRadius.toInt().toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 15),
                const Text("m", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// SUB-SCREEN 2: TRACKING FREQUENCY
// --------------------------------------------------------------------------
class TrackingFrequencyPage extends StatelessWidget {
  const TrackingFrequencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: IconButton(
                  icon: SvgPicture.asset('assets/icons/Back.svg', color: const Color(0xFF985BEF), width: 40, height: 40),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tracking Frequency", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  _buildRadioCard(context, "High Accuracy (Every 1 min)", "High Accuracy", state),
                  _buildRadioCard(context, "Balanced (5 mins)", "Balanced", state),
                  _buildRadioCard(context, "Power Saving (15 mins)", "Power Saving", state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioCard(BuildContext context, String label, String value, AppStateController state) {
    bool isSelected = state.trackingFrequency == value;
    return GestureDetector(
      onTap: () => state.setTrackingFrequency(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                color: isSelected ? const Color(0xFF985BEF) : Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// SUB-SCREEN 4: NOTIFICATION SETTINGS
// --------------------------------------------------------------------------
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30, height: 30),
          onPressed: () => context.pop(),
        ),
        title: const Text("Notification Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildToggleCard(
              title: "Master Notifications",
              subtitle: "Enable or disable all app notifications",
              value: state.notificationsEnabled,
              onChanged: (v) => state.setNotificationsEnabled(v),
              isMaster: true,
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: state.notificationsEnabled ? 1.0 : 0.5,
              child: AbsorbPointer(
                absorbing: !state.notificationsEnabled,
                child: Column(
                  children: [
                    _buildToggleCard(
                      title: "Appointment Reminders",
                      subtitle: "Notifications for vet visits and tasks",
                      value: state.notifyAppointments,
                      onChanged: (v) => state.setNotifyAppointments(v),
                    ),
                    const SizedBox(height: 15),
                    _buildToggleCard(
                      title: "Chat Messages",
                      subtitle: "Get alerts when you receive a message",
                      value: state.notifyChat,
                      onChanged: (v) => state.setNotifyChat(v),
                    ),
                    const SizedBox(height: 15),
                    _buildToggleCard(
                      title: "Emergency Alerts",
                      subtitle: "Lost cat reports nearby",
                      value: state.notifyEmergency,
                      onChanged: (v) => state.setNotifyEmergency(v),
                    ),
                    const SizedBox(height: 15),
                    _buildToggleCard(
                      title: "Daily Care Reminders",
                      subtitle: "Reminders to feed and groom your cat",
                      value: state.notifyDailyCare,
                      onChanged: (v) => state.setNotifyDailyCare(v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isMaster = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isMaster ? const Color(0xFF985BEF).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isMaster ? Border.all(color: const Color(0xFF985BEF), width: 1) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isMaster ? const Color(0xFF985BEF) : Colors.black)),
                const SizedBox(height: 5),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF985BEF),
          ),
        ],
      ),
    );
  }
}
// --------------------------------------------------------------------------
// SUB-SCREEN 3: MY PRIVACY
// --------------------------------------------------------------------------
class MyPrivacyPage extends StatelessWidget {
  const MyPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30, height: 30),
          onPressed: () => context.pop(),
        ),
        title: const Text("My Privacy", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: const Center(child: Text("Privacy settings and data management.")),
    );
  }
}
