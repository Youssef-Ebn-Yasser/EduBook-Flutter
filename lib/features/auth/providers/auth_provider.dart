import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

Map<String, dynamic>? _parseJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    String normalized = base64Url.normalize(parts[1]);
    final payloadString = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payloadString) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

// ─── State ─────────────────────────────────────────────────────────────────

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? message;
  final bool isAuthenticated;
  final bool isAdmin;
  final String? role;
  final String? userName;
  final String? userEmail;

  const AuthState({
    this.status = AuthStatus.idle,
    this.message,
    this.isAuthenticated = false,
    this.isAdmin = false,
    this.role,
    this.userName,
    this.userEmail,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? message,
    bool clearMessage = false,
    bool? isAuthenticated,
    bool? isAdmin,
    String? role,
    String? userName,
    String? userEmail,
  }) =>
      AuthState(
        status: status ?? this.status,
        message: clearMessage ? null : (message ?? this.message),
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isAdmin: isAdmin ?? this.isAdmin,
        role: role ?? this.role,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SecureStorageService _storage;

  AuthNotifier(this._repo, this._storage) : super(const AuthState()) {
    checkAuth();
  }

  void reset() => state = const AuthState();

  void clearError() {
    if (state.status == AuthStatus.error || state.message != null) {
      state = state.copyWith(status: AuthStatus.idle, clearMessage: true);
    }
  }

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      _extractUserFromToken(token);
    }
  }

  void _extractUserFromToken(String token) {
    final claims = _parseJwt(token);
    if (claims != null) {
      final roleClaim = claims['role'] ??
          claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      bool admin = false;
      String roleName = 'Student';
      if (roleClaim is String) {
        admin = roleClaim.toLowerCase() == 'admin';
        roleName = roleClaim;
      } else if (roleClaim is List) {
        admin = roleClaim.any((r) => r.toString().toLowerCase() == 'admin');
        roleName = roleClaim.join(', ');
      }
      final name = claims['name'] ??
          claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
          claims['FullName'] ??
          '';
      final email = claims['email'] ??
          claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ??
          '';
      state = state.copyWith(
        isAuthenticated: true,
        isAdmin: admin,
        role: roleName,
        userName: name.toString(),
        userEmail: email.toString(),
      );
    } else {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        } else if (errors is Map && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          }
          return firstVal.toString();
        }
        final message = data['message'] ?? data['title'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    } catch (_) {}
    return 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.login(LoginRequest(email: email, password: password));
      if (result.success && result.data != null) {
        await _storage.saveToken(result.data!.accessToken);
        await _storage.saveRefreshToken(result.data!.refreshToken);
        // Extract role/user info from the token FIRST
        _extractUserFromToken(result.data!.accessToken);
        // Then stamp success — preserve isAdmin already in state
        state = state.copyWith(
          status: AuthStatus.success,
          isAuthenticated: true,
          isAdmin: state.isAdmin, // explicit carry-through
        );
        return true;
      } else {
        state = state.copyWith(status: AuthStatus.error, message: result.message);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.register(request);
      if (result.success) {
        state = state.copyWith(status: AuthStatus.success, message: result.message);
        return true;
      } else {
        state = state.copyWith(
            status: AuthStatus.error,
            message: result.errors?.join('\n') ?? result.message);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.forgotPassword(ForgotPasswordRequest(email: email));
      state = state.copyWith(
          status: result.success ? AuthStatus.success : AuthStatus.error,
          message: result.message);
      return result.success;
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String otp) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result =
          await _repo.verifyEmail(VerifyEmailRequest(email: email, otpCode: otp));
      state = state.copyWith(
          status: result.success ? AuthStatus.success : AuthStatus.error,
          message: result.message);
      return result.success;
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<String?> verifyPasswordResetOtp(String email, String otp) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.verifyPasswordResetOtp(
        VerifyPasswordResetOtpRequest(email: email, otpCode: otp),
      );
      state = state.copyWith(
        status: result.success ? AuthStatus.success : AuthStatus.error,
        message: result.message,
      );
      if (result.success && result.data != null && result.data!.resetToken.isNotEmpty) {
        return result.data!.resetToken;
      }
      return null;
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return null;
    }
  }

  Future<bool> resetPassword(ResetPasswordRequest request) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.resetPassword(request);
      state = state.copyWith(
          status: result.success ? AuthStatus.success : AuthStatus.error,
          message: result.message);
      return result.success;
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<bool> resendVerificationOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.resendVerificationOtp(email);
      state = state.copyWith(
          status: result.success ? AuthStatus.success : AuthStatus.error,
          message: result.message);
      return result.success;
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<bool> resendPasswordResetOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final result = await _repo.resendPasswordResetOtp(email);
      state = state.copyWith(
          status: result.success ? AuthStatus.success : AuthStatus.error,
          message: result.message);
      return result.success;
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: _extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {}
    await _storage.clearAll();
    state = const AuthState(isAuthenticated: false);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(repo, storage);
});
