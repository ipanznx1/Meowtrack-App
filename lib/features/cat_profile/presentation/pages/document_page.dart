import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentPage extends StatefulWidget {
  final Cat cat;
  const DocumentPage({super.key, required this.cat});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  bool _isUploading = false;

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final File file = File(result.files.single.path!);
      final String fileName = result.files.single.name;

      setState(() => _isUploading = true);

      try {
        // 1. Upload to Firebase Storage - Using Cat ID
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('documents')
            .child(widget.cat.id)
            .child(fileName);
        
        await storageRef.putFile(file);
        final String downloadUrl = await storageRef.getDownloadURL();

        // 2. Save to Firestore
        await FirebaseFirestore.instance.collection('documents').add({
          'catId': widget.cat.id,
          'name': fileName,
          'url': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document "$fileName" uploaded successfully!')),
          );
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Upload failed: ${e.toString().split(']').last}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _viewDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (_isUploading) const LinearProgressIndicator(color: Color(0xFF985BEF)),
            const SizedBox(height: 10),
            
            // Upload Card
            GestureDetector(
              onTap: _isUploading ? null : _uploadDocument,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFFFFA23A), shape: BoxShape.circle),
                      child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 60),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _isUploading ? 'Uploading...' : 'Upload a document', 
                      style: const TextStyle(color: Color(0xFFFFA23A), fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Dynamic Folder Grid from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('documents')
                    .where('catId', isEqualTo: widget.cat.id)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No documents found.', style: TextStyle(color: Colors.grey)));
                  }

                  return GridView.builder(
                    itemCount: docs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final docData = docs[index].data() as Map<String, dynamic>;
                      final String url = docData['url'] ?? '';
                      return GestureDetector(
                        onTap: url.isNotEmpty ? () => _viewDocument(url) : null,
                        child: _buildFolderCard(docData['name'] ?? 'Doc', textColor),
                      );
                    },
                  );
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
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
