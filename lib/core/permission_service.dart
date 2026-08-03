import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Meminta izin untuk Kamera
  static Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;
    
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, "Kamera");
      return false;
    }
    
    return status.isGranted;
  }

  /// Meminta izin untuk Galeri/Foto
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      // Semak jika Android 13 (API 33) ke atas
      // Device info plugin can be used here, but permission_handler 
      // automatically handles the photos permission correctly if requested.
      
      // Request photos permission first (Android 13+)
      status = await Permission.photos.request();
      
      if (status.isDenied || status.isRestricted) {
        // Fallback untuk Android 12 ke bawah
        status = await Permission.storage.request();
      }
    } else {
      // iOS
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, "Galeri");
      return false;
    }

    return status.isGranted || status.isLimited;
  }

  /// Dialog untuk mengarahkan user ke Settings jika permission permanently denied
  static void _showSettingsDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Izin $feature Diperlukan", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Meowtrack memerlukan izin $feature untuk membolehkan anda memuat naik gambar. Sila aktifkan di tetapan aplikasi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            child: const Text("Tetapan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Fungsi umum untuk meminta izin kritikal sekaligus
  static Future<void> requestAllPermissions(BuildContext context) async {
    await [
      Permission.camera,
      Permission.location,
      Permission.photos,
      Permission.storage,
    ].request();
  }
}
