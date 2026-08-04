import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QrTagScreen extends StatefulWidget {
  const QrTagScreen({super.key});

  @override
  State<QrTagScreen> createState() => _QrTagScreenState();
}

class _QrTagScreenState extends State<QrTagScreen> {
  Cat? _selectedCat;
  final GlobalKey _globalKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateController>(context, listen: false);
    if (state.cats.isNotEmpty) {
      _selectedCat = state.cats.first;
    }
  }

  Future<Uint8List?> _capturePng() async {
    try {
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing QR: $e");
      return null;
    }
  }

  Future<void> _shareQrTag() async {
    setState(() => _isExporting = true);
    final Uint8List? imageBytes = await _capturePng();
    setState(() => _isExporting = false);

    if (imageBytes != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/cat_tag_${_selectedCat?.name ?? "tag"}.png').create();
      await imagePath.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Ini adalah Tag QR Digital untuk ${_selectedCat?.name ?? "kucing saya"}. Scan untuk maklumat pemilik!',
      );
    }
  }

  Future<void> _saveQrTag() async {
    setState(() => _isExporting = true);
    final Uint8List? imageBytes = await _capturePng();
    setState(() => _isExporting = false);

    if (imageBytes != null) {
      // Pada Android, kita boleh simpan ke folder Downloads untuk kemudahan user
      String? path;
      if (Platform.isAndroid) {
        path = '/storage/emulated/0/Download/Meowtrack_${_selectedCat?.name ?? "Tag"}.png';
        try {
          final file = File(path);
          await file.writeAsBytes(imageBytes);
        } catch (_) {
          // Fallback to app doc dir if Downloads fails (permission issues)
          final directory = await getApplicationDocumentsDirectory();
          path = '${directory.path}/Meowtrack_${_selectedCat?.name ?? "Tag"}.png';
          await File(path).writeAsBytes(imageBytes);
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/Meowtrack_${_selectedCat?.name ?? "Tag"}.png';
        await File(path).writeAsBytes(imageBytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tag disimpan ke: $path"),
            action: SnackBarAction(label: "Buka", onPressed: () => Share.shareXFiles([XFile(path!)])),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();

    // The data we want to encode in the QR code
    final qrData = {
      'owner': state.userName ?? 'Meowtrack User',
      'purrCode': state.purrCode ?? '',
      'catName': _selectedCat?.name ?? 'My Cat',
      'emergencyContact': state.userEmail ?? '',
      'app': 'Meowtrack'
    }.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
        title: const Text("Digital Pet Tag", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Text(
                  "Generate a QR code for your cat's collar. If someone finds your cat, they can scan this to contact you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 35),

                // Cat Selector
                if (state.cats.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Cat>(
                        value: _selectedCat,
                        isExpanded: true,
                        items: state.cats.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text("Tag for: ${cat.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (cat) => setState(() => _selectedCat = cat),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // QR Code Container - WRAPPED IN REPAINT BOUNDARY
                RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          foregroundColor: const Color(0xFF985BEF),
                          gapless: false,
                        ),
                        const SizedBox(height: 25),
                        Text(
                          _selectedCat?.name.toUpperCase() ?? "MY CAT",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        Text(
                          "PURR CODE: ${state.purrCode}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.download,
                        label: "Save Image",
                        onTap: _saveQrTag,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.share,
                        label: "Share Tag",
                        onTap: _shareQrTag,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _actionButton(
                  icon: Icons.print,
                  label: "Print Tag Sticker",
                  onTap: _saveQrTag, // Can reuse save logic
                  isPrimary: true,
                ),
              ],
            ),
          ),
          if (_isExporting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF985BEF))),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, bool isPrimary = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF985BEF)),
      label: Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF985BEF) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: isPrimary ? 5 : 0,
      ),
    );
  }
}
