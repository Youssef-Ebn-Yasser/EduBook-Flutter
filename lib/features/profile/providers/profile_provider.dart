import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final res = await _repository.getProfile();
      if (res.success && res.data != null) {
        state = state.copyWith(profile: res.data, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'تعذر تحميل الملف الشخصي',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'خطأ: $e');
    }
  }

  Future<bool> updateProfile(String fullName, int? gradeLevelId) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final req = UpdateProfileRequest(fullName: fullName, gradeLevelId: gradeLevelId);
      final res = await _repository.updateProfile(req);
      if (res.success && res.data != null) {
        state = state.copyWith(
          profile: res.data,
          isSaving: false,
          successMessage: 'تم تحديث الملف الشخصي بنجاح',
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'تعذر تحديث البيانات',
        );
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'خطأ: $e');
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final req = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      final res = await _repository.changePassword(req);
      if (res.success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'تم تغيير كلمة المرور بنجاح',
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'تعذر تغيير كلمة المرور',
        );
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'خطأ: $e');
    }
    return false;
  }

  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final res = await _repository.uploadAvatar(filePath);
      if (res.success && res.data != null) {
        state = state.copyWith(
          profile: res.data,
          isSaving: false,
          successMessage: 'تم تحديث الصورة الشخصية بنجاح',
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'تعذر رفع الصورة الشخصية',
        );
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'خطأ: $e');
    }
    return false;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo);
});
