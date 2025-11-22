import 'dart:typed_data';
import 'package:supabase/supabase.dart';
import '../config/supabase_config.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  late final SupabaseClient _client = SupabaseClient(
    SupabaseConfig.supabaseUrl,
    SupabaseConfig.supabaseAnonKey,
  );

  Future<String> uploadProfileImage(Uint8List imageData, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$userId/avatar_$timestamp.jpg';

    try {
      final bucket = SupabaseConfig.profileImagesBucket;
      final storage = _client.storage.from(bucket);

      await storage.uploadBinary(
        path,
        imageData,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      // Prefer public URL for public buckets; fallback to signed URL for private buckets
      final publicUrl = storage.getPublicUrl(path);
      if (publicUrl.isNotEmpty) {
        return publicUrl;
      }

      // Fallback: short-lived signed URL (requires SELECT policy on storage.objects)
      final signed = await storage.createSignedUrl(path, 60 * 60); // 1 hour
      return signed;
    } catch (e) {
      // Surface detailed errors to logs to aid policy configuration
      print('Supabase upload failed: $e');
      rethrow;
    }
  }
}