/// Mapping du wrapper ApiResponse<T> du backend Spring Boot.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int status;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.status,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      status: json['status'] as int? ?? 0,
    );
  }

  bool get isSuccess => success && data != null;
}

/// Réponse paginée : correspond à ApiResponse<PageData<T>> du backend.
class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool first;
  final bool last;

  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.first,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = (json['content'] as List<dynamic>? ?? [])
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();
    return PageResponse<T>(
      content: items,
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }
}

