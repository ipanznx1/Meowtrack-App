import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class AddNotePage extends StatefulWidget {
  final Cat cat;
  const AddNotePage({super.key, required this.cat});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedIconAsset = 'assets/icons/Anything notes.svg';

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'Medical', 'icon': 'assets/icons/Health notes.svg'},
    {'name': 'Food', 'icon': 'assets/icons/Food notes.svg'},
    {'name': 'Medicine', 'icon': 'assets/icons/Ubat notes.svg'},
    {'name': 'Warning', 'icon': 'assets/icons/warning notes.svg'},
    {'name': 'Note', 'icon': 'assets/icons/Anything notes.svg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', color: Colors.black, width: 24, height: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Notes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title notes', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTextField(_titleController, 'Title notes', 'assets/icons/Title notes.svg'),
            
            const SizedBox(height: 25),
            const Text('Icon', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildIconDropdown(),
            
            const SizedBox(height: 25),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              height: 250,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(hintText: 'Title notes', border: InputBorder.none),
              ),
            ),
            
            const SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    appState.addNote(
                      widget.cat.name,
                      CatNote(
                        title: _titleController.text,
                        content: _contentController.text,
                        date: 'Today',
                        icon: Icons.note, // Temporary until CatNote supports SVG asset paths
                      ),
                    );
                    context.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String svgAsset) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(svgAsset, color: const Color(0xFF985BEF).withValues(alpha: 0.5), width: 20, height: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildIconDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedIconAsset,
          isExpanded: true,
          items: _availableIcons.map((item) {
            return DropdownMenuItem<String>(
              value: item['icon'],
              child: Row(
                children: [
                  SvgPicture.asset(item['icon'], color: const Color(0xFF985BEF), width: 24, height: 24),
                  const SizedBox(width: 15),
                  Text(item['name']),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedIconAsset = v!),
        ),
      ),
    );
  }
}
