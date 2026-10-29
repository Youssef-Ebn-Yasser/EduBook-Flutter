import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/auth_models.dart';
import 'reader_models.dart';

class ReaderRepository {
  final Dio _dio;

  ReaderRepository(this._dio);

  /// Start secure full reading session (verifies unexpired subscription)
  Future<ApiResponse<ReaderSession>> getSession(int bookId) async {
    final response = await _dio.get('/api/Reader/$bookId/session');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<ReaderSession>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: ReaderSession.fromJson(data),
    );
  }

  /// Start free sample preview session (no purchase required)
  Future<ApiResponse<ReaderSession>> getSampleSession(int bookId) async {
    final response = await _dio.get('/api/Reader/$bookId/sample-session');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<ReaderSession>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: ReaderSession.fromJson(data),
    );
  }

  /// Get annotations for this book, optionally filtered by page number
  Future<ApiResponse<List<ReaderAnnotation>>> getAnnotations(
    int bookId, {
    int? pageNumber,
  }) async {
    final query = <String, dynamic>{};
    if (pageNumber != null) query['pageNumber'] = pageNumber;

    final response = await _dio.get(
      '/api/Reader/$bookId/annotations',
      queryParameters: query,
    );
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return ApiResponse<List<ReaderAnnotation>>(
      success: true,
      message: '',
      data: list
          .map((e) => ReaderAnnotation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Save drawing, note, or highlight annotation
  Future<ApiResponse<ReaderAnnotation>> saveAnnotation(
    int bookId,
    SaveAnnotationRequest request,
  ) async {
    final response = await _dio.post(
      '/api/Reader/$bookId/annotations',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<ReaderAnnotation>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم حفظ الملاحظة بنجاح',
      data: ReaderAnnotation.fromJson(data),
    );
  }

  /// Delete specific annotation
  Future<ApiResponse<bool>> deleteAnnotation(int annotationId) async {
    final response = await _dio.delete('/api/Reader/annotations/$annotationId');
    final raw = response.data;
    bool success = true;
    String message = 'تم حذف الملاحظة';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  /// Clear all annotations for a specific page
  Future<ApiResponse<bool>> clearPageAnnotations(int bookId, int pageNumber) async {
    final response =
        await _dio.delete('/api/Reader/$bookId/annotations/page/$pageNumber');
    final raw = response.data;
    bool success = true;
    String message = 'تم مسح ملاحظات الصفحة';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  /// Save last read page progress
  Future<ApiResponse<ReadingProgressResponse>> updateProgress(
    int bookId,
    int pageNumber,
  ) async {
    final response = await _dio.put(
      '/api/Reader/$bookId/progress',
      data: {'pageNumber': pageNumber},
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<ReadingProgressResponse>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: ReadingProgressResponse.fromJson(data),
    );
  }
}

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return ReaderRepository(ref.read(dioClientProvider));
});
