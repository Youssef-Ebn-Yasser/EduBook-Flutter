import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/data/auth_models.dart';
import '../../admin/data/admin_models.dart';
import 'book_models.dart';

class BooksRepository {
  final Dio _dio;
  static const String _books = '/api/Books';
  static const String _myBooks = '/api/my-books';

  BooksRepository(this._dio);

  // ─── Public Books ──────────────────────────────────────────────────────────

  /// GET /api/Books — browse with filters & pagination
  Future<ApiResponse<PaginatedBooks>> getBooks(BookQueryParams params) async {
    final response = await _dio.get(
      _books,
      queryParameters: params.toQueryMap(),
    );
    final raw = response.data;
    // API may return ApiResponse<PaginatedBooks> or ApiResponse<List>
    if (raw is Map<String, dynamic>) {
      final success = raw['success'] as bool? ?? true;
      final message = raw['message'] as String? ?? '';
      final data = raw['data'];
      if (data != null) {
        return ApiResponse<PaginatedBooks>(
          success: success,
          message: message,
          data: PaginatedBooks.fromJson(data,
              page: params.page, pageSize: params.pageSize),
        );
      }
      // direct list in root
      return ApiResponse<PaginatedBooks>(
        success: success,
        message: message,
        data: PaginatedBooks.fromJson(raw,
            page: params.page, pageSize: params.pageSize),
      );
    }
    // plain array
    return ApiResponse<PaginatedBooks>(
      success: true,
      message: '',
      data: PaginatedBooks.fromJson(raw,
          page: params.page, pageSize: params.pageSize),
    );
  }

  /// GET /api/Books/{id} — book details
  Future<ApiResponse<BookDetail>> getBookById(int id) async {
    final response = await _dio.get('$_books/$id');
    final raw = response.data as Map<String, dynamic>;
    return ApiResponse<BookDetail>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: BookDetail.fromJson(
        (raw['data'] ?? raw) as Map<String, dynamic>,
      ),
    );
  }

  /// GET /api/Books/{id}/units — chapters for a book
  Future<ApiResponse<List<BookUnit>>> getBookUnits(int bookId) async {
    final response = await _dio.get('$_books/$bookId/units');
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else {
      list = raw as List<dynamic>;
    }
    return ApiResponse<List<BookUnit>>(
      success: true,
      message: '',
      data: list
          .map((e) => BookUnit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ─── My Books (requires auth) ──────────────────────────────────────────────

  /// GET /api/my-books — user library
  Future<ApiResponse<List<MyBookItem>>> getMyBooks() async {
    final response = await _dio.get(_myBooks);
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else {
      list = raw as List<dynamic>;
    }
    return ApiResponse<List<MyBookItem>>(
      success: true,
      message: '',
      data: list
          .map((e) => MyBookItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/my-books/{bookId}/access — check access
  Future<ApiResponse<BookAccessResponse>> checkAccess(int bookId) async {
    final response = await _dio.get('$_myBooks/$bookId/access');
    final raw = response.data as Map<String, dynamic>;
    return ApiResponse<BookAccessResponse>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: BookAccessResponse.fromJson(
          (raw['data'] ?? raw) as Map<String, dynamic>),
    );
  }

  /// GET /api/GradeLevels — public grade levels for filtering
  Future<List<AdminGradeLevel>> getGradeLevels() async {
    final response = await _dio.get('/api/GradeLevels');
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? []) as List<dynamic>;
    } else if (raw is List<dynamic>) {
      list = raw;
    } else {
      list = [];
    }
    return list
        .map((e) => AdminGradeLevel.fromJson(e as Map<String, dynamic>))
        .where((g) => g.isActive)
        .toList();
  }
}

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepository(ref.read(dioClientProvider));
});
