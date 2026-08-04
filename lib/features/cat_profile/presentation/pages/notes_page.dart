import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class NotesPage extends StatefulWidget {
  final Cat cat;
  const NotesPage({super.key, required this.cat});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Color(0xFF985BEF)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.tune, color: Color(0xFF985BEF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Add Notes Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () => context.push('/notes/${widget.cat.id}/add', extra: widget.cat),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Notes', style: TextStyle(color: Color(0xFFFFA23A), fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 25),
          
          // Grid of Notes from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cats')
                  .doc(widget.cat.id)
                  .collection('health_records')
                  .where('type', isEqualTo: 'note')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                
                final allNotes = snapshot.data?.docs ?? [];
                final filteredNotes = allNotes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final content = (data['content'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || content.contains(_searchQuery);
                }).toList();

                if (allNotes.isEmpty) {
                  return const Center(child: Text('No notes found.', style: TextStyle(color: Colors.grey)));
                }

                if (filteredNotes.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text('No matching notes.', style: TextStyle(color: Colors.white)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredNotes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final noteData = filteredNotes[index].data() as Map<String, dynamic>;
                    return _buildNoteCard(context, noteData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF985BEF).withValues(alpha: 0.1),
            child: const Icon(Icons.note, color: Color(0xFF985BEF)),
          ),
          const SizedBox(height: 10),
          Text(note['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
          Text(note['date'] ?? 'No Date', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showNoteDetail(context, note),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('More...', style: TextStyle(fontSize: 10, color: Colors.grey))),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDetail(BuildContext context, Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(note['title'] ?? 'Note Detail', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 15),
              Text(note['content'] ?? 'No content'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
