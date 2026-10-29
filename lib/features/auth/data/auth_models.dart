// ─── Request Models ───────────────────────────────────────────────────────────

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String role; // "Student" | "Teacher"
  final int? gradeLevelId;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.role,
    this.gradeLevelId,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
        if (gradeLevelId != null) 'gradeLevelId': gradeLevelId,
      };
}

class ForgotPasswordRequest {
  final String email;
  const ForgotPasswordRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyEmailRequest {
  final String email;
  final String otpCode;
  const VerifyEmailRequest({required this.email, required this.otpCode});
  Map<String, dynamic> toJson() => {'email': email, 'otpCode': otpCode};
}

class VerifyPasswordResetOtpRequest {
  final String email;
  final String otpCode;
  const VerifyPasswordResetOtpRequest({required this.email, required this.otpCode});
  Map<String, dynamic> toJson() => {'email': email, 'otpCode': otpCode};
}

class ResetPasswordRequest {
  final String email;
  final String otpCode;
  final String newPassword;
  final String confirmNewPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.otpCode,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otpCode': otpCode,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      };
}

class RefreshTokenRequest {
  final String refreshToken;
  const RefreshTokenRequest({required this.refreshToken});
  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class ResendOtpRequest {
  final String email;
  const ResendOtpRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

// ─── Response Models ──────────────────────────────────────────────────────────

class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  final String? code;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.code,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      data: fromData != null ? fromData(json['data']) : null,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
      code: json['code'] as String?,
    );
  }
}
