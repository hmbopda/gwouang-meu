import 'package:dio/dio.dart' hide MultipartFile;
import 'package:dio/dio.dart' as dio show MultipartFile;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client HTTP central — toutes les requêtes vers le backend Spring Boot passent ici.
/// JWT Supabase injecté automatiquement dans chaque requête.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      LogInterceptor(requestBody: false, responseBody: false),
    ]);
  }

  // ── GET ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return response.data!;
  }

  // ── POST ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    return response.data!;
  }

  // ── PUT ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(path, data: data);
    return response.data!;
  }

  // ── PATCH ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(path, data: data);
    return response.data!;
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> delete(String path) async {
    await _dio.delete<void>(path);
  }

  // ── MULTIPART UPLOAD ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required List<int> bytes,
    required String filename,
    required String field,
    Map<String, dynamic>? fields,
  }) async {
    final formData = FormData.fromMap({
      field: dio.MultipartFile.fromBytes(bytes, filename: filename),
      if (fields != null) ...fields,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data!;
  }
}

/// Intercepteur JWT — lit le token Supabase courant et l'injecte en header.
/// Exclut les endpoints publics (invitations/token) pour éviter les 401 avec JWT expiré.
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Endpoints publics : GET invitation par token (pas besoin de JWT)
    final isPublicGet = options.method == 'GET' &&
        options.path.contains('/api/v1/invitations/token/');

    if (!isPublicGet) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expiré ou invalide → déconnexion
      Supabase.instance.client.auth.signOut();
    }
    handler.next(err);
  }
}

// ── Provider Riverpod ─────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
