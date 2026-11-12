import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies picked camera/gallery images into persistent app documents storage
/// so photos remain intact after app restarts or OS cache clearing.
class ImageStorageService {
  static const String _imagesFolderName = 'product_images';

  Future<Directory> _getImagesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, _imagesFolderName));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Copies [sourceFilePath] into permanent storage and returns the new path.
  Future<String> saveProductImage(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw const FileSystemException('Selected image file does not exist.');
    }

    final imagesDir = await _getImagesDirectory();
    final ext = p.extension(sourceFilePath).isEmpty
        ? '.jpg'
        : p.extension(sourceFilePath);
    final fileName = 'prod_${DateTime.now().microsecondsSinceEpoch}$ext';
    final destinationPath = p.join(imagesDir.path, fileName);

    final copiedFile = await sourceFile.copy(destinationPath);
    return copiedFile.path;
  }

  /// Safely deletes an old product image stored inside our app images folder.
  Future<void> deleteProductImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) return;

    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
