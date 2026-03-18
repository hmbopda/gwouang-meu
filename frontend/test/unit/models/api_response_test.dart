import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson avec succes et data', () {
      final response = ApiResponse<String>.fromJson(
        {'success': true, 'data': 'hello', 'status': 200},
        (data) => data as String,
      );

      expect(response.success, true);
      expect(response.data, 'hello');
      expect(response.status, 200);
      expect(response.isSuccess, true);
    });

    test('fromJson avec echec', () {
      final response = ApiResponse<String>.fromJson(
        {
          'success': false,
          'message': 'Not Found',
          'status': 404,
        },
        (data) => data as String,
      );

      expect(response.success, false);
      expect(response.data, isNull);
      expect(response.message, 'Not Found');
      expect(response.status, 404);
      expect(response.isSuccess, false);
    });

    test('fromJson avec data null', () {
      final response = ApiResponse<String>.fromJson(
        {'success': true, 'data': null, 'status': 200},
        (data) => data as String,
      );

      expect(response.success, true);
      expect(response.data, isNull);
      expect(response.isSuccess, false);
    });

    test('fromJson avec champs manquants utilise les defaults', () {
      final response = ApiResponse<String>.fromJson(
        <String, dynamic>{},
        (data) => data as String,
      );

      expect(response.success, false);
      expect(response.status, 0);
      expect(response.isSuccess, false);
    });

    test('fromJson avec data map', () {
      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        {
          'success': true,
          'data': {'id': '1', 'name': 'test'},
          'status': 200,
        },
        (data) => data as Map<String, dynamic>,
      );

      expect(response.isSuccess, true);
      expect(response.data!['id'], '1');
    });
  });

  group('PageResponse', () {
    test('fromJson avec contenu', () {
      final response = PageResponse<Map<String, dynamic>>.fromJson(
        {
          'content': [
            {'id': '1', 'name': 'A'},
            {'id': '2', 'name': 'B'},
          ],
          'page': 0,
          'size': 20,
          'totalPages': 1,
          'totalElements': 2,
          'first': true,
          'last': true,
        },
        (json) => json,
      );

      expect(response.content, hasLength(2));
      expect(response.page, 0);
      expect(response.size, 20);
      expect(response.totalPages, 1);
      expect(response.totalElements, 2);
      expect(response.first, true);
      expect(response.last, true);
    });

    test('fromJson avec contenu vide', () {
      final response = PageResponse<Map<String, dynamic>>.fromJson(
        {
          'content': [],
          'page': 0,
          'size': 20,
          'totalPages': 0,
          'totalElements': 0,
          'first': true,
          'last': true,
        },
        (json) => json,
      );

      expect(response.content, isEmpty);
      expect(response.totalElements, 0);
    });

    test('fromJson avec champs manquants utilise les defaults', () {
      final response = PageResponse<Map<String, dynamic>>.fromJson(
        <String, dynamic>{},
        (json) => json,
      );

      expect(response.content, isEmpty);
      expect(response.page, 0);
      expect(response.size, 20);
      expect(response.totalPages, 0);
      expect(response.first, true);
      expect(response.last, true);
    });

    test('fromJson page intermediaire', () {
      final response = PageResponse<Map<String, dynamic>>.fromJson(
        {
          'content': [
            {'id': '3'},
          ],
          'page': 1,
          'size': 1,
          'totalPages': 5,
          'totalElements': 5,
          'first': false,
          'last': false,
        },
        (json) => json,
      );

      expect(response.first, false);
      expect(response.last, false);
      expect(response.page, 1);
      expect(response.totalPages, 5);
    });
  });
}
