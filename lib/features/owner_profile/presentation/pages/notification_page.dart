import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Notification toggle states
  bool _geofencingAlert = true;
  bool _medicalReminders = true;
  bool _batteryStatus = false;
  bool _communityAlerts = true;

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
          "Notification",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            _buildNotificationTile(
              iconAsset: 'assets/icons/Geofencing Alert.svg',
              title: "Geofencing Alert",
              value: _geofencingAlert,
              onChanged: (val) => setState(() => _geofencingAlert = val),
            ),
            const SizedBox(height: 15),
            _buildNotificationTile(
              iconAsset: 'assets/icons/Medical & Vaccine Reminders.svg',
              title: "Medical & Vaccine Reminders",
              value: _medicalReminders,
              onChanged: (val) => setState(() => _medicalReminders = val),
            ),
            const SizedBox(height: 15),
            _buildNotificationTile(
              iconAsset: 'assets/icons/Collar Battery Status.svg',
              title: "Collar Battery Status",
              value: _batteryStatus,
              onChanged: (val) => setState(() => _batteryStatus = val),
            ),
            const SizedBox(height: 15),
            _buildNotificationTile(
              iconAsset: 'assets/icons/Community Alerts.svg',
              title: "Community Alerts",
              value: _communityAlerts,
              onChanged: (val) => setState(() => _communityAlerts = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String iconAsset,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconAsset, width: 28, height: 28, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF985BEF),
            activeTrackColor: Colors.black, // Matching design's black track when ON
          ),
        ],
      ),
    );
  }
}
