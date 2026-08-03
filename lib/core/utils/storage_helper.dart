import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageHelper {
  /// Fungsi untuk mengecilkan saiz gambar di bawah 5MB
  /// Mengurangkan kualiti ke 70% dan set lebar maksimum ke 1080px
  static Future<File?> compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final String targetPath = p.join(tempDir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}");

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      print("Ralat kompres imej: $e");
      return null;
    }
  }

  /// Fungsi untuk upload gambar ke Firebase Storage
  /// Wajib periksa saiz fail (maksimum 5MB)
  static Future<String?> uploadImageToFirebase({
    required File imageFile,
    required String folderName,
    required String userId,
    required String fileName,
  }) async {
    try {
      // 1. Validasi Saiz Fail (5MB = 5 * 1024 * 1024 bytes)
      int fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception("Saiz fail terlalu besar! Had maksimum ialah 5MB.");
      }

      // 2. Tentukan Path: folderName/userId/fileName
      final String path = "$folderName/$userId/$fileName";
      final storageRef = FirebaseStorage.instance.ref().child(path);

      // 3. Proses Upload
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Tunggu upload selesai
      TaskSnapshot snapshot = await uploadTask;

      // 4. Dapatkan download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;

    } catch (e) {
      print("Ralat semasa upload ke Firebase: $e");
      rethrow; // Lepaskan error untuk ditangkap oleh UI/Calling function
    }
  }

  /// Contoh fungsi gabungan untuk Avatar atau Gambar Kucing
  static Future<String?> processAndUpload({
    required File originalFile,
    required String folder,
    required String uid,
    required String name,
  }) async {
    // A. Kompres dahulu
    File? compressed = await compressImage(originalFile);
    if (compressed == null) return null;

    // B. Upload fail yang dah dikompres
    return await uploadImageToFirebase(
      imageFile: compressed,
      folderName: folder,
      userId: uid,
      fileName: name,
    );
  }
}
