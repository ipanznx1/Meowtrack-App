import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/pages/not_implemented_page.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  bool _isManaging = false;

  Future<void> _confirmDelete(Cat cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Cat?"),
        content: Text("Are you sure you want to remove ${cat.name} from your household?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await appState.deleteCat(cat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${cat.name} deleted.")));
      }
    }
  }

  void _editCat(Cat cat) {
    final nameController = TextEditingController(text: cat.name);
    final breedController = TextEditingController(text: cat.breed);
    String selectedGender = cat.gender;
    final List<String> breeds = [
      'British Shorthair',
      'Persian',
      'Domestic Long Hair',
      'Domestic Shorthair',
      'Siamese',
      'Maine Coon',
      'Bengal'
    ];

    if (!breeds.contains(cat.breed)) {
      breeds.add(cat.breed);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Edit Cat Details", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Cat Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: breeds.contains(breedController.text) ? breedController.text : breeds.first,
                  decoration: const InputDecoration(
                    labelText: "Breed",
                    border: OutlineInputBorder(),
                  ),
                  items: breeds.map((b) => DropdownMenuItem(
                    value: b, 
                    child: Text(b, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)
                  )).toList(),
                  onChanged: (v) => setModalState(() => breedController.text = v!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(),
                  ),
                  items: ['Female', 'Male']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedGender = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await appState.updateCat(cat.id, {
                  'name': nameController.text.trim(),
                  'breed': breedController.text.trim(),
                  'gender': selectedGender,
                });
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
            title: const Text("My Household", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isManaging = !_isManaging),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF985BEF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    minimumSize: const Size(200, 45),
                  ),
                  child: Text(
                    _isManaging ? "Done" : "Manage",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: appState.cats.isEmpty 
                  ? const Center(child: Text("No cats in your household yet."))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: appState.cats.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 25,
                        childAspectRatio: 0.47, 
                      ),
                      itemBuilder: (context, index) {
                        return _buildCatCard(appState.cats[index]);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatCard(Cat cat) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isOwner = cat.isOwner(uid);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35), // More rounded as requested
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        children: [
          // 1. IMAGE SECTION (Lighter background like image)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cat.themeColor.withOpacity(0.15), // Very light pastel
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Center(
                child: Transform.scale(
                  scale: cat.imageScale * 1.1,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: (cat.image.startsWith('http')) 
                      ? Image.network(cat.image, fit: BoxFit.contain)
                      : Image.asset(cat.image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. INFO SECTION
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                children: [
                  Text(
                    cat.name.toLowerCase(), // Image shows lowercase name
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87), 
                    textAlign: TextAlign.center, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.breed.toUpperCase(), 
                    style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w900, letterSpacing: 0.5), 
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.gender, 
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                  
                  const Spacer(),
                  
                  // 3. ACTION SECTION
                  if (_isManaging && isOwner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Color(0xFF985BEF)),
                          onPressed: () => _editCat(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(cat),
                        ),
                      ],
                    )
                  else if (isOwner)
                    Container(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => _showShareDialog(cat),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF985BEF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: const Text("Share Access", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    const Text("Shared Profile", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(Cat cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Share Access", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a purrmate to share access to this cat's health profile.", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              if (appState.friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("No purrmates found. Add friends first!"),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: appState.friends.length,
                    itemBuilder: (context, index) {
                      final friend = appState.friends[index];
                      final bool alreadyShared = cat.collaborators.contains(friend.uid);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend.avatarUrl.isNotEmpty ? NetworkImage(friend.avatarUrl) : null,
                          child: friend.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(friend.username, style: const TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: alreadyShared ? null : () async {
                            final updatedCollaborators = List<String>.from(cat.collaborators)..add(friend.uid);
                            await appState.updateCat(cat.id, {'collaborators': updatedCollaborators});
                            if (mounted) {
                              Navigator.pop(ctx);
                              MeowAnimatedDialog.show(
                                context,
                                animationPath: 'assets/animations/save_settings.json',
                                title: "Akses Dikongsi!",
                                description: "Anda telah berkongsi akses ${cat.name} kepada ${friend.name}.",
                                themeColor: Colors.indigo,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: alreadyShared ? Colors.grey : const Color(0xFF985BEF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(alreadyShared ? "Shared" : "Share", style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }
}
