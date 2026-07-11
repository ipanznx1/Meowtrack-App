import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('User Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            _buildLiveStatusIndicator(),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No data found for this user', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(userData),
                const SizedBox(height: 30),
                _buildSectionTitle('Account Details'),
                const SizedBox(height: 15),
                _buildInfoCard(userData),
                const SizedBox(height: 30),
                _buildSectionTitle('Recent Activity'),
                const SizedBox(height: 15),
                _buildActivityLog(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveStatusIndicator() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.snapshotsInSync(),
      builder: (context, snapshot) {
        bool isActive = FirebaseFirestore.instance.app.options.apiKey.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isActive ? 'Live Connection: Active' : 'Offline',
              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF985BEF)),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30, // Reduced from 40
            backgroundColor: const Color(0xFF985BEF).withValues(alpha: 0.1),
            backgroundImage: (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty)
                ? NetworkImage(data['avatarUrl'])
                : const AssetImage('assets/images/Luna.png') as ImageProvider,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['username'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(data['email'] ?? 'No Email', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                _buildRoleBadge(data['role'] ?? 'user'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(dynamic role) {
    String roleText = role is String ? role : 'User';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: roleText == 'admin' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: roleText == 'admin' ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.pin, 'Purr Code', data['purrCode'] ?? 'N/A'),
          const Divider(height: 30),
          _buildInfoRow(Icons.calendar_today, 'Tracking Days', (data['trackingDays'] ?? 0).toString()),
          const Divider(height: 30),
          _buildInfoRow(Icons.verified_user, 'Profile Setup', (data['isProfileSetup'] == true) ? 'Complete' : 'Pending'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildActivityLog() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data!.docs;
        if (logs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No recent activity recorded', style: TextStyle(color: Colors.grey)),
          ));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final DateTime timestamp = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF985BEF).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.bolt, color: Color(0xFF985BEF), size: 16),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['event'] ?? 'System Event', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(DateFormat('MMM dd, yyyy - HH:mm').format(timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
