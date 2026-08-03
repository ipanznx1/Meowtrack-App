import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:meow_track/core/app_state.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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
            // 1. MASTER SWITCH
            _buildToggleCard(
              title: "Master Notifications",
              subtitle: "Enable or disable all app notifications",
              value: state.notificationsEnabled,
              onChanged: (v) => state.setNotificationsEnabled(v),
              isMaster: true,
              svgAsset: 'assets/icons/Notification.svg',
            ),
            const SizedBox(height: 25),
            
            // 2. KATEGORI DARI PREFERENCES (DIBAWA KE SINI)
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
                      svgAsset: 'assets/icons/Medical & Vaccine Reminders.svg',
                    ),
                    const SizedBox(height: 15),
                    _buildToggleCard(
                      title: "Chat Messages",
                      subtitle: "Get alerts when you receive a message",
                      value: state.notifyChat,
                      onChanged: (v) => state.setNotifyChat(v),
                      svgAsset: 'assets/icons/Community Alerts.svg',
                    ),
                    const SizedBox(height: 15),
                    _buildToggleCard(
                      title: "Emergency Alerts",
                      subtitle: "Lost cat reports nearby",
                      value: state.notifyEmergency,
                      onChanged: (v) => state.setNotifyEmergency(v),
                      svgAsset: 'assets/icons/Geofencing Alert.svg',
                    ),
                    const SizedBox(height: 15),
                    _buildToggleCard(
                      title: "Daily Care Reminders",
                      subtitle: "Reminders to feed and groom your cat",
                      value: state.notifyDailyCare,
                      onChanged: (v) => state.setNotifyDailyCare(v),
                      svgAsset: 'assets/icons/Collar Battery Status-01.svg',
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
    required String svgAsset,
    bool isMaster = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isMaster ? const Color(0xFF985BEF).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isMaster ? Border.all(color: const Color(0xFF985BEF), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            svgAsset, 
            width: 28, height: 28, 
            colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isMaster ? const Color(0xFF985BEF) : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF985BEF),
          ),
        ],
      ),
    );
  }
}
