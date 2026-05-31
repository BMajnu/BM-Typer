import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cloudinary configuration
class CloudinaryConfig {
  static const String cloudName = 'djhaat0sx';
  static const String uploadPreset = 'bm_typer_upload';
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

/// Service for uploading images to Cloudinary
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      debugPrint('📷 Image picked: ${image?.path}');
      return image;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Upload image to Cloudinary and return the URL
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      debugPrint('📤 Starting Cloudinary upload...');
      
      // Read file bytes
      final Uint8List bytes = await imageFile.readAsBytes();
      debugPrint('📦 Image bytes length: ${bytes.length}');
      
      // Determine MIME type from file name
      String mimeType = 'image/jpeg';
      final fileName = imageFile.name.toLowerCase();
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      // Convert to base64 data URI
      final String base64Image = base64Encode(bytes);
      final String dataUri = 'data:$mimeType;base64,$base64Image';
      
      // Generate a clean public_id without slashes (required by Cloudinary)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String publicId = 'bm_typer_profile_$timestamp';
      
      // Use simple POST request instead of MultipartRequest for web compatibility
      // Only allowed params for unsigned upload: upload_preset, public_id, folder, tags, filename_override
      final response = await http.post(
        Uri.parse(CloudinaryConfig.uploadUrl),
        body: {
          'file': dataUri,
          'upload_preset': CloudinaryConfig.uploadPreset,
          'public_id': publicId,
          'filename_override': 'profile_$timestamp.jpg',
        },
      );
      
      debugPrint('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String imageUrl = jsonResponse['secure_url'];
        debugPrint('✅ Image uploaded to Cloudinary: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Cloudinary upload failed: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading to Cloudinary: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Pick and upload image in one step
  Future<String?> pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    debugPrint('🚀 Starting pickAndUploadImage...');
    final XFile? image = await pickImage(source: source);
    if (image == null) {
      debugPrint('⚠️ No image selected');
      return null;
    }
    return uploadImage(image);
  }
}

/// Provider for CloudinaryService
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
