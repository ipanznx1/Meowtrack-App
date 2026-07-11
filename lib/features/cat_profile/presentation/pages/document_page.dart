import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';

class DocumentPage extends StatefulWidget {
  final Cat cat;
  const DocumentPage({super.key, required this.cat});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  // 1. Stateful list for documents
  List<String> uploadedDocs = [
    "Medical_Record_2024",
    "Vaccine_Cert",
    "Insurance_Policy",
    "Ownership_Doc",
  ];

  void _simulateUpload() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Document'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter document name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  uploadedDocs.insert(0, nameController.text);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document "${nameController.text}" uploaded successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic theme color based on cat
    Color textColor = widget.cat.name == "Oyen" ? const Color(0xFFE67E22) : Colors.pink.shade700;

    return Scaffold(
      backgroundColor: widget.cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Document', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: const TextField(
                      decoration: InputDecoration(
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
            const SizedBox(height: 25),

            // 2. Upload Card
            GestureDetector(
              onTap: _simulateUpload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFFFFA23A), shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 60),
                    ),
                    const SizedBox(height: 15),
                    const Text('Upload a document', style: TextStyle(color: Color(0xFFFFA23A), fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 3. Dynamic Folder Grid
            Expanded(
              child: GridView.builder(
                itemCount: uploadedDocs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  return _buildFolderCard(uploadedDocs[index], textColor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(String name, Color textColor) {
    return Stack(
      children: [
        // Folder Tab
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 70,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
          ),
        ),
        // Folder Body
        Container(
          margin: const EdgeInsets.only(top: 15),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
