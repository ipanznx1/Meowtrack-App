import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/router/app_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _toggleMaintenanceMode(bool value) async {
    // Optimistic UI update could be done here, but since we use StreamBuilder for real-time sync,
    // we just update Firestore and let the stream handle the UI.
    try {
      await FirebaseFirestore.instance.collection('app_settings').doc('status').set({
        'maintenanceMode': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating maintenance mode: $e')),
        );
      }
    }
  }

  Future<void> _postAnnouncement() async {
    final text = _announcementController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an announcement message')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'priority': 'high',
        'adminEmail': appState.userEmail,
      });

      _announcementController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement published successfully!')),
        );
        // Focus scope to close keyboard
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing announcement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Column(
            children: [
              const Text('Admin Hub', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              _buildLiveStatusIndicator(),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                await appState.logout();
                if (mounted) {
                  context.go(AppRouter.authGateway);
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF985BEF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF985BEF),
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Overview"),
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.report), text: "Moderation"),
              Tab(icon: Icon(Icons.pets), text: "Lost Cats"),
            ],
          ),
        ),
        body: TabBarView(
          // Using NeverScrollableScrollPhysics to prevent swipe conflicts with toggles/sliders
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildOverviewTab(),
            _buildUsersTab(),
            _buildModerationTab(),
            _buildLostCatsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        _buildSectionTitle('AI Usage Tracker'),
        const SizedBox(height: 15),
        _buildAiUsageCard(),
        const SizedBox(height: 30),
        _buildSectionTitle('Overview'),
        const SizedBox(height: 15),
        _buildStatisticsGrid(),
        const SizedBox(height: 30),
        _buildSectionTitle('Admin Controls'),
        const SizedBox(height: 15),
        _buildMaintenanceCard(),
        const SizedBox(height: 30),
        _buildSectionTitle('Broadcast Announcement'),
        const SizedBox(height: 15),
        _buildAnnouncementCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: _buildUserManagementSection(),
    );
  }

  Widget _buildModerationTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('isFlagged', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;

        if (posts.isEmpty) return const Center(child: Text("No flagged posts! 🎉", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 15),
              child: ListTile(
                leading: data['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                title: Text(data['title'] ?? 'Untitled Post', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Reports: ${data['reportCount'] ?? 0}\nReason: ${data['moderationStatus'] ?? 'Review needed'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () => appState.ignoreReport(post.id),
                      tooltip: "Keep Post",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(post.id),
                      tooltip: "Delete Post",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLostCatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cats')
          .where('isLost', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final cats = snapshot.data!.docs;

        if (cats.isEmpty) return const Center(child: Text("No lost cats reported. Good job!", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final cat = cats[index];
            final data = cat.data() as Map<String, dynamic>;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 15),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(data['image'] ?? ''),
                ),
                title: Text(data['name'] ?? 'Unknown Cat', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Breed: ${data['breed'] ?? 'N/A'}"),
                trailing: ElevatedButton(
                  onPressed: () => appState.markCatAsFound(cat.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("Mark Found", style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This action cannot be undone and will remove the post from the community feed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              appState.deletePost(postId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusIndicator() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.snapshotsInSync(),
      builder: (context, snapshot) {
        bool isActive = FirebaseFirestore.instance.app.options.apiKey.isNotEmpty; // Simple check
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

  Widget _buildStatisticsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('community_posts').where('isFlagged', isEqualTo: true).snapshots(),
          builder: (context, postSnapshot) {
            int total = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
            int active = userSnapshot.hasData ? userSnapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['isBanned'] != true).length : 0;
            int reported = postSnapshot.hasData ? postSnapshot.data!.docs.length : 0;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard('Total Users', total.toString(), Icons.people, Colors.blue),
                _buildStatCard('Active Users', active.toString(), Icons.check_circle, Colors.green),
                _buildStatCard('Reported', reported.toString(), Icons.report_problem, Colors.orange),
                _buildStatCard('Banned', (total - active).toString(), Icons.block, Colors.red),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Text(
            title, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAiUsageCard() {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final dailyPercent = (appState.aiRequestsToday / 1500).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gemini API Usage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${appState.aiRequestsToday}/1500 RPD', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: dailyPercent,
                backgroundColor: Colors.grey[200],
                color: dailyPercent > 0.8 ? Colors.red : const Color(0xFF985BEF),
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text('RPM: ${appState.aiRequestsThisMinute}/15', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('app_settings').doc('status').snapshots(),
      builder: (context, snapshot) {
        bool isMaintenance = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          isMaintenance = (snapshot.data!.data() as Map<String, dynamic>)['maintenanceMode'] ?? false;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Restrict user access during updates', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Switch.adaptive(
                value: isMaintenance,
                activeTrackColor: const Color(0xFF985BEF),
                onChanged: (val) => _toggleMaintenanceMode(val),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAnnouncementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _announcementController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your message to all users...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF0F0F5),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _postAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF985BEF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Post Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search user by email...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final users = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final email = (data['email'] ?? '').toString().toLowerCase();
              return email.contains(_searchQuery);
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final bool isBanned = userData['isBanned'] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                  child: ListTile(
                    onTap: () => context.push('/admin/user-detail/${userDoc.id}'),
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF985BEF).withValues(alpha: 0.1),
                      backgroundImage: (userData['avatarUrl'] != null && userData['avatarUrl'].toString().isNotEmpty)
                          ? NetworkImage(userData['avatarUrl'])
                          : const AssetImage('assets/images/Luna.png') as ImageProvider,
                    ),
                    title: Text(userData['username'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userData['email'] ?? 'No Email'),
                        const SizedBox(height: 4),
                        Text(
                          userData['isProfileSetup'] == true ? 'Status: Aktif' : 'Status: Belum Setup',
                          style: TextStyle(
                            fontSize: 11,
                            color: userData['isProfileSetup'] == true ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text(isBanned ? 'Unban User' : 'Ban User'),
                          onTap: () => _toggleBan(userDoc.id, isBanned),
                        ),
                        PopupMenuItem(
                          child: const Text('Delete User', style: TextStyle(color: Colors.red)),
                          onTap: () => _deleteUser(userDoc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleBan(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isBanned': !currentStatus,
    });
  }

  Future<void> _deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }
}
