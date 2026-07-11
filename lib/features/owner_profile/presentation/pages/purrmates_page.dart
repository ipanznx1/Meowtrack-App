import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class PurrmatesPage extends StatefulWidget {
  const PurrmatesPage({super.key});

  @override
  State<PurrmatesPage> createState() => _PurrmatesPageState();
}

class _PurrmatesPageState extends State<PurrmatesPage> {
  final TextEditingController _searchController = TextEditingController();

  void _showAddPurrmateDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Center(child: Text("Add New Purr-mates", style: TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your friend's unique Purr Code to send a connection request.", 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
              child: TextField(
                controller: codeController,
                keyboardType: TextInputType.text, // Ditukar dari number ke text
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: "Enter 8-digit Code...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isEmpty) return;
                
                try {
                  await appState.sendFriendRequest(code);
                  if (mounted) {
                    Navigator.pop(context);
                    MeowAnimatedDialog.show(
                      context,
                      animationPath: 'assets/animations/purrmates.json',
                      title: "Permintaan Dihantar!",
                      description: "Permintaan Purrmate anda telah dihantar kepada rakan anda.",
                      themeColor: Colors.pinkAccent,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString().split(']').last}")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF985BEF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _copyMyCode() {
    if (appState.purrCode != null) {
      Clipboard.setData(ClipboardData(text: appState.purrCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("My Purr Code ${appState.purrCode} copied to clipboard!")),
      );
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
              onPressed: () => context.pop(),
            ),
            title: const Text("My Purr-mates", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF985BEF)),
                onPressed: _copyMyCode,
              )
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search my Purr-mates...",
                            border: InputBorder.none,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset('assets/icons/Search....svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 20, height: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 35, height: 35, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
                      onPressed: _showAddPurrmateDialog,
                    ),
                  ],
                ),
              ),

              if (appState.pendingRequests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(alignment: Alignment.centerLeft, child: Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: appState.pendingRequests.length,
                    itemBuilder: (context, index) {
                      final req = appState.pendingRequests[index];
                      return _buildRequestAvatar(req);
                    },
                  ),
                ),
                const Divider(),
              ],

              Expanded(
                child: appState.friends.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("No purr-mates yet."),
                          Text("Your Purr Code: ${appState.purrCode ?? '...'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: appState.friends.length,
                      itemBuilder: (context, index) {
                        return _buildContactCard(appState.friends[index]);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestAvatar(FriendRequest req) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: req.fromAvatar.isNotEmpty ? NetworkImage(req.fromAvatar) : null,
                child: req.fromAvatar.isEmpty ? const Icon(Icons.person) : null,
              ),
              Positioned(
                bottom: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () => appState.acceptFriendRequest(req),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(req.fromName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContactCard(Purrmate p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25, 
            backgroundImage: p.avatarUrl.isNotEmpty ? NetworkImage(p.avatarUrl) : null,
            child: p.avatarUrl.isEmpty ? SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 25, height: 25, colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn)) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${p.name} (${p.username})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(p.isCoOwner ? "Co-Parent" : "Purrmate", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text("Purr code : ${p.purrCode}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
