import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/auth_models.dart';
import '../../books/data/book_models.dart';
import 'admin_models.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  // ─── Categories ─────────────────────────────────────────────────────────────

  Future<ApiResponse<List<AdminCategory>>> getCategories() async {
    final response = await _dio.get('/api/Categories');
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }
    return ApiResponse<List<AdminCategory>>(
      success: true,
      message: '',
      data: list
          .map((e) => AdminCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<AdminCategory>> createCategory(CategoryRequest request) async {
    final response = await _dio.post(
      '/api/Categories',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminCategory>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تمت إضافة القسم بنجاح',
      data: AdminCategory.fromJson(data),
    );
  }

  Future<ApiResponse<AdminCategory>> updateCategory(
      int id, CategoryRequest request) async {
    final response = await _dio.put(
      '/api/Categories/$id',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminCategory>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم تعديل القسم بنجاح',
      data: AdminCategory.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> deleteCategory(int id) async {
    final response = await _dio.delete('/api/Categories/$id');
    final raw = response.data;
    bool success = true;
    String message = 'تم حذف القسم بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(
      success: success,
      message: message,
      data: success,
    );
  }

  // ─── Grade Levels ───────────────────────────────────────────────────────────

  Future<ApiResponse<List<AdminGradeLevel>>> getGradeLevels() async {
    final response = await _dio.get('/api/GradeLevels');
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }
    return ApiResponse<List<AdminGradeLevel>>(
      success: true,
      message: '',
      data: list
          .map((e) => AdminGradeLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<AdminGradeLevel>> createGradeLevel(
      GradeLevelRequest request) async {
    final response = await _dio.post(
      '/api/GradeLevels',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminGradeLevel>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تمت إضافة الصف الدراسي بنجاح',
      data: AdminGradeLevel.fromJson(data),
    );
  }

  Future<ApiResponse<AdminGradeLevel>> updateGradeLevel(
      int id, GradeLevelRequest request) async {
    final response = await _dio.put(
      '/api/GradeLevels/$id',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminGradeLevel>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم تعديل الصف الدراسي بنجاح',
      data: AdminGradeLevel.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> deleteGradeLevel(int id) async {
    final response = await _dio.delete('/api/GradeLevels/$id');
    final raw = response.data;
    bool success = true;
    String message = 'تم حذف الصف الدراسي بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(
      success: success,
      message: message,
      data: success,
    );
  }

  // ─── Books CRUD ─────────────────────────────────────────────────────────────

  Future<ApiResponse<PaginatedBooks>> getBooks({int page = 1, int pageSize = 50}) async {
    final response = await _dio.get(
      '/api/Books',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final success = raw['success'] as bool? ?? true;
      final message = raw['message'] as String? ?? '';
      final data = raw['data'] ?? raw;
      return ApiResponse<PaginatedBooks>(
        success: success,
        message: message,
        data: PaginatedBooks.fromJson(data, page: page, pageSize: pageSize),
      );
    }
    return ApiResponse<PaginatedBooks>(
      success: true,
      message: '',
      data: PaginatedBooks.fromJson(raw, page: page, pageSize: pageSize),
    );
  }

  Future<ApiResponse<BookDetail>> createBook(CreateBookRequest request) async {
    final response = await _dio.post(
      '/api/Books',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<BookDetail>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم إنشاء الكتاب بنجاح',
      data: BookDetail.fromJson(data),
    );
  }

  Future<ApiResponse<BookDetail>> updateBook(
      int id, UpdateBookRequest request) async {
    final response = await _dio.put(
      '/api/Books/$id',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<BookDetail>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم تحديث بيانات الكتاب بنجاح',
      data: BookDetail.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> deleteBook(int id) async {
    final response = await _dio.delete('/api/Books/$id');
    final raw = response.data;
    bool success = true;
    String message = 'تم حذف الكتاب بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(
      success: success,
      message: message,
      data: success,
    );
  }

  /// Upload/replace the cover image — multipart POST /api/Books/{id}/cover
  Future<ApiResponse<bool>> uploadBookCover(int id, String filePath) async {
    final fileName = filePath.split('/').last.split('\\').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/api/Books/$id/cover',
      data: formData,
    );
    final raw = response.data;
    bool success = true;
    String message = 'تم رفع صورة الغلاف بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  /// Upload a PDF file for a book — multipart POST /api/Books/{id}/files
  Future<ApiResponse<bool>> uploadBookFile(
      int id, String filePath, String version) async {
    final fileName = filePath.split('/').last.split('\\').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/api/Books/$id/files',
      data: formData,
      queryParameters: {'version': version},
    );
    final raw = response.data;
    bool success = true;
    String message = 'تم رفع ملف PDF بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  // ─── Book Units ─────────────────────────────────────────────────────────────

  Future<ApiResponse<List<BookUnit>>> getBookUnits(int bookId) async {
    final response = await _dio.get('/api/Books/$bookId/units');
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }
    return ApiResponse<List<BookUnit>>(
      success: true,
      message: '',
      data: list
          .map((e) => BookUnit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<BookUnit>> addBookUnit(
      int bookId, BookUnitRequest request) async {
    final response = await _dio.post(
      '/api/Books/$bookId/units',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<BookUnit>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تمت إضافة الوحدة بنجاح',
      data: BookUnit.fromJson(data),
    );
  }

  Future<ApiResponse<BookUnit>> updateBookUnit(
      int bookId, int unitId, BookUnitRequest request) async {
    final response = await _dio.put(
      '/api/Books/$bookId/units/$unitId',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<BookUnit>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم تعديل الوحدة بنجاح',
      data: BookUnit.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> deleteBookUnit(int bookId, int unitId) async {
    final response = await _dio.delete('/api/Books/$bookId/units/$unitId');
    final raw = response.data;
    bool success = true;
    String message = 'تم حذف الوحدة بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  // ─── Book Files (PDF versions) ──────────────────────────────────────────────

  Future<ApiResponse<List<BookFile>>> getBookFiles(int bookId) async {
    final response = await _dio.get('/api/Books/$bookId/files');
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }
    return ApiResponse<List<BookFile>>(
      success: true,
      message: '',
      data: list
          .map((e) => BookFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<bool>> activateBookFile(int bookId, int fileId) async {
    final response =
        await _dio.put('/api/Books/$bookId/files/$fileId/activate');
    final raw = response.data;
    bool success = true;
    String message = 'تم تفعيل الملف بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  Future<ApiResponse<bool>> deleteBookFile(int bookId, int fileId) async {
    final response = await _dio.delete('/api/Books/$bookId/files/$fileId');
    final raw = response.data;
    bool success = true;
    String message = 'تم حذف الملف بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  // ─── Single Item Lookups ────────────────────────────────────────────────────

  Future<ApiResponse<AdminCategory>> getCategoryById(int id) async {
    final response = await _dio.get('/api/Categories/$id');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminCategory>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: AdminCategory.fromJson(data),
    );
  }

  Future<ApiResponse<AdminGradeLevel>> getGradeLevelById(int id) async {
    final response = await _dio.get('/api/GradeLevels/$id');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminGradeLevel>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: AdminGradeLevel.fromJson(data),
    );
  }

  Future<ApiResponse<BookDetail>> getBookById(int id) async {
    final response = await _dio.get('/api/Books/$id');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<BookDetail>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: BookDetail.fromJson(data),
    );
  }

  // ─── Admin Orders ───────────────────────────────────────────────────────────

  Future<ApiResponse<List<AdminOrder>>> getAdminOrders({
    int? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;

    final response = await _dio.get(
      '/api/Orders/admin',
      queryParameters: query,
    );
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw;
      if (data is Map<String, dynamic>) {
        list = (data['items'] ?? data['data'] ?? []) as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return ApiResponse<List<AdminOrder>>(
      success: true,
      message: '',
      data: list
          .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<AdminOrder>> getOrderById(int id) async {
    final response = await _dio.get('/api/Orders/$id');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminOrder>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: AdminOrder.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> approveOrder(int id) async {
    final response = await _dio.post('/api/Orders/admin/$id/approve');
    final raw = response.data;
    bool success = true;
    String message = 'تم قبول وتفعيل الطلب بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(
      success: success,
      message: message,
      data: success,
    );
  }

  Future<ApiResponse<bool>> rejectOrder(int id, String reason) async {
    final response = await _dio.post(
      '/api/Orders/admin/$id/reject',
      data: {'reason': reason},
    );
    final raw = response.data;
    bool success = true;
    String message = 'تم رفض الطلب بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(
      success: success,
      message: message,
      data: success,
    );
  }

  // ─── Dashboard Stats & Users Management ───────────────────────────────────

  Future<ApiResponse<AdminDashboardStats>> getDashboardStats() async {
    final response = await _dio.get('/api/admin/dashboard');
    final raw = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    final data = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    return ApiResponse<AdminDashboardStats>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: AdminDashboardStats.fromJson(data),
    );
  }

  Future<ApiResponse<List<AdminUser>>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (role != null && role.isNotEmpty) query['role'] = role;
    if (isActive != null) query['isActive'] = isActive;

    final response = await _dio.get('/api/admin/users', queryParameters: query);
    final raw = response.data;
    List<dynamic> list;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw;
      if (data is Map<String, dynamic>) {
        list = (data['items'] ?? data['data'] ?? []) as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return ApiResponse<List<AdminUser>>(
      success: true,
      message: '',
      data: list
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<AdminUserDetail>> getUserDetail(String userId) async {
    final response = await _dio.get('/api/admin/users/$userId');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<AdminUserDetail>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: AdminUserDetail.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> toggleUserStatus(String userId, bool isActive) async {
    final response = await _dio.put(
      '/api/admin/users/$userId/status',
      data: {'isActive': isActive},
    );
    final raw = response.data;
    bool success = true;
    String message = 'تم تحديث حالة الحساب بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(
      success: success,
      message: message,
      data: success,
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioClientProvider));
});
