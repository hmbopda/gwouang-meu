import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/network/supabase_service.dart';
import '../../shared/models/user_model.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<UserModel?> build() async {
    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser == null) return null;
    return _fetchProfile(supaUser.id);
  }

  Future<UserModel?> _fetchProfile(String supabaseId) async {
    try {
      final client = ref.read(apiClientProvider);
      final json = await client.get('/api/v1/users/me');
      return UserModel.fromJson(json['data'] as Map<String, dynamic>);
    } catch (_) {
      // Fallback : construire un UserModel minimal depuis Supabase
      final u = Supabase.instance.client.auth.currentUser!;
      return UserModel(
        id: u.id,
        email: u.email ?? '',
        displayName: u.userMetadata?['display_name'] as String?,
        role: u.userMetadata?['role'] as String? ?? 'MEMBRE',
      );
    }
  }

  Future<void> signOut() async {
    await ref.read(supabaseServiceProvider).signOut();
    state = const AsyncData(null);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(apiClientProvider);
      final json = await client.put('/api/v1/users/me', data: data);
      return UserModel.fromJson(json['data'] as Map<String, dynamic>);
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Upload une image (avatar ou cover) puis met a jour le profil.
  /// [folder] : "avatars" ou "covers"
  /// [profileField] : "avatarUrl" ou "coverUrl"
  Future<void> uploadImage({
    required List<int> bytes,
    required String filename,
    required String folder,
    required String profileField,
  }) async {
    final client = ref.read(apiClientProvider);
    // 1) Upload vers R2
    final uploadJson = await client.uploadFile(
      '/api/v1/media/upload',
      bytes: bytes,
      filename: filename,
      field: 'file',
      fields: {'folder': folder},
    );
    final url = (uploadJson['data'] as Map<String, dynamic>)['url'] as String;
    // 2) Met a jour le profil avec l'URL
    await updateProfile({profileField: url});
  }
}
