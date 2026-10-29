class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final int? gradeLevelId;
  final String? gradeLevelName;
  final String? avatarUrl;
  final bool emailConfirmed;
  final DateTime createdAt;
  final int purchasedBooksCount;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.gradeLevelId,
    this.gradeLevelName,
    this.avatarUrl,
    required this.emailConfirmed,
    required this.createdAt,
    required this.purchasedBooksCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      gradeLevelId: json['gradeLevelId'] as int?,
      gradeLevelName: json['gradeLevelName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      emailConfirmed: json['emailConfirmed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      purchasedBooksCount: json['purchasedBooksCount'] as int? ?? 0,
    );
  }
}

class UpdateProfileRequest {
  final String fullName;
  final int? gradeLevelId;

  const UpdateProfileRequest({
    required this.fullName,
    this.gradeLevelId,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        if (gradeLevelId != null) 'gradeLevelId': gradeLevelId,
      };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}
