import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Upload d'un média vers **Supabase Storage** (bucket public `media`) → URL CDN
/// publique et durable.
///
/// Remplace l'ancien passage par le backend `/api/v1/media/upload` : R2 n'y est
/// pas configuré, le service tombait donc en stockage local éphémère et générait
/// une URL vers le mauvais domaine (front) → images 404. Ici tout le média
/// (publications, avatars, couvertures…) est unifié sur Supabase Storage.
///
/// [folder] : `posts` | `avatars` | `covers` | `village-covers` …
class MediaStorage {
  const MediaStorage._();

  static const bucket = 'media';

  static Future<String> upload({
    required List<int> bytes,
    required String folder,
    String? filename,
  }) async {
    final client = Supabase.instance.client;
    final storage = client.storage.from(bucket);
    final uid = client.auth.currentUser?.id ?? 'anon';
    final ext = _extension(filename);
    final path = '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}$ext';
    await storage.uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: _contentType(ext), upsert: true),
    );
    return storage.getPublicUrl(path);
  }

  static String _extension(String? name) {
    if (name != null && name.contains('.')) {
      return name.substring(name.lastIndexOf('.')).toLowerCase();
    }
    return '.jpg';
  }

  static String _contentType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
