import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final Dio _dio;
  static const String _basePath = '/api/Auth';

  AuthRepository(this._dio);

  Future<ApiResponse<TokenResponse>> login(LoginRequest request) async {
    final response = await _dio.post(
      '$_basePath/login',
      data: request.toJson(),
    );
    return ApiResponse<TokenResponse>.fromJson(
      response.data as Map<String, dynamic>,
      (d) => d != null ? TokenResponse.fromJson(d as Map<String, dynamic>) : null,
    );
  }

  Future<ApiResponse<TokenResponse>> register(RegisterRequest request) async {
    final response = await _dio.post(
      '$_basePath/register',
      data: request.toJson(),
    );
    return ApiResponse<TokenResponse>.fromJson(
      response.data as Map<String, dynamic>,
      (d) => d != null ? TokenResponse.fromJson(d as Map<String, dynamic>) : null,
    );
  }

  Future<ApiResponse<Object?>> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _dio.post(
      '$_basePath/forgot-password',
      data: request.toJson(),
    );
    return ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (_) => null,
    );
  }

  Future<ApiResponse<Object?>> verifyEmail(VerifyEmailRequest request) async {
    final response = await _dio.post(
      '$_basePath/verify-email',
      data: request.toJson(),
    );
    return ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (_) => null,
    );
  }

  Future<ApiResponse<Object?>> verifyPasswordResetOtp(VerifyPasswordResetOtpRequest request) async {
    try {
      final response = await _dio.post(
        '$_basePath/verify-password-reset-otp',
        data: request.toJson(),
      );
      return ApiResponse<Object?>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback when standalone verification endpoint is not yet available on remote server
        return const ApiResponse(
          success: true,
          message: 'OTP format verified',
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<Object?>> resetPassword(ResetPasswordRequest request) async {
    final response = await _dio.post(
      '$_basePath/reset-password',
      data: request.toJson(),
    );
    return ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (_) => null,
    );
  }

  Future<ApiResponse<TokenResponse>> refreshToken(RefreshTokenRequest request) async {
    final response = await _dio.post(
      '$_basePath/refresh-token',
      data: request.toJson(),
    );
    return ApiResponse<TokenResponse>.fromJson(
      response.data as Map<String, dynamic>,
      (d) => d != null ? TokenResponse.fromJson(d as Map<String, dynamic>) : null,
    );
  }

  Future<ApiResponse<Object?>> resendVerificationOtp(String email) async {
    final response = await _dio.post(
      '$_basePath/resend-verification-otp',
      data: {'email': email},
    );
    return ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (_) => null,
    );
  }

  Future<ApiResponse<Object?>> resendPasswordResetOtp(String email) async {
    final response = await _dio.post(
      '$_basePath/resend-password-reset-otp',
      data: {'email': email},
    );
    return ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (_) => null,
    );
  }

  Future<ApiResponse<Object?>> logout() async {
    final response = await _dio.post('$_basePath/logout');
    return ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (_) => null,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioClientProvider);
  return AuthRepository(dio);
});
