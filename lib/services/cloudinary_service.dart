import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dlsnldb6p',
    'my_app_preset',
    cache: false,
  );

  /// Uploads an image byte array to Cloudinary and returns the secure URL.
  /// [folder] is the target folder name on Cloudinary (e.g., 'jobs', 'services').
  /// [identifier] is a unique identifier for the file (e.g., userId + timestamp).
  Future<String?> uploadImage(
      Uint8List imageBytes, String folder, String identifier) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: identifier,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }
}
