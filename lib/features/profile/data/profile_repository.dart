import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/auth_models.dart';
import 'profile_models.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<ApiResponse<UserProfile>> getProfile() async {
    final response = await _dio.get('/api/Profile');
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<UserProfile>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? '',
      data: UserProfile.fromJson(data),
    );
  }

  Future<ApiResponse<UserProfile>> updateProfile(
      UpdateProfileRequest request) async {
    final response = await _dio.put(
      '/api/Profile',
      data: request.toJson(),
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<UserProfile>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم تحديث الملف الشخصي بنجاح',
      data: UserProfile.fromJson(data),
    );
  }

  Future<ApiResponse<bool>> changePassword(
      ChangePasswordRequest request) async {
    final response = await _dio.post(
      '/api/Profile/change-password',
      data: request.toJson(),
    );
    final raw = response.data;
    bool success = true;
    String message = 'تم تغيير كلمة المرور بنجاح';
    if (raw is Map<String, dynamic>) {
      success = raw['success'] as bool? ?? true;
      message = raw['message'] as String? ?? message;
    }
    return ApiResponse<bool>(success: success, message: message, data: success);
  }

  Future<ApiResponse<UserProfile>> uploadAvatar(String filePath) async {
    final fileName = filePath.split('/').last.split('\\').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/api/Profile/avatar',
      data: formData,
    );
    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    return ApiResponse<UserProfile>(
      success: raw['success'] as bool? ?? true,
      message: raw['message'] as String? ?? 'تم تحديث الصورة الشخصية بنجاح',
      data: UserProfile.fromJson(data),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioClientProvider));
});
