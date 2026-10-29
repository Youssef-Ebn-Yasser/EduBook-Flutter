import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/localization/localization_provider.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../books/providers/books_provider.dart';
import '../data/auth_models.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isStudent = true;
  int? _selectedGradeLevelId;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isStudent && _selectedGradeLevelId == null) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'يرجى اختيار الصف الدراسي' : 'Please select your grade level'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final request = RegisterRequest(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      confirmPassword: _confirmPassCtrl.text,
      role: _isStudent ? 'Student' : 'Teacher',
      gradeLevelId: _isStudent ? _selectedGradeLevelId : null,
    );
    final success = await ref.read(authProvider.notifier).register(request);
    if (!mounted) return;
    if (success) {
      context.push('/verify-otp', extra: <String, dynamic>{
        'email': _emailCtrl.text.trim(),
        'purpose': 'emailVerification',
      });
    }
  }

  Widget _buildFallbackGradeChips(bool isAr) {
    final fallbackList = [
      (id: 1, name: isAr ? 'الصف 9' : 'Grade 9'),
      (id: 2, name: isAr ? 'الصف 10' : 'Grade 10'),
      (id: 3, name: isAr ? 'الصف 11' : 'Grade 11'),
      (id: 4, name: isAr ? 'الصف 12' : 'Grade 12'),
    ];
    _selectedGradeLevelId ??= fallbackList.first.id;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: fallbackList.map((item) {
          final selected = _selectedGradeLevelId == item.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _SelectableGradeChip(
              label: item.name,
              isSelected: selected,
              onTap: () {
                setState(() => _selectedGradeLevelId = item.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final errorMsg =
        authState.status == AuthStatus.error ? authState.message : null;
    final gradeLevelsAsync = ref.watch(publicGradeLevelsProvider);

    // Auto-select first active grade if none selected yet
    gradeLevelsAsync.whenData((grades) {
      final activeGrades = grades.where((g) => g.isActive).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      if (_selectedGradeLevelId == null && activeGrades.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedGradeLevelId == null) {
            setState(() => _selectedGradeLevelId = activeGrades.first.id);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
            ref.read(authProvider.notifier).clearError();
            context.pop();
          },
        ),
        title: Text(
          l.registerTitle,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => ref
                    .read(localeNotifierProvider.notifier)
                    .toggleLanguage(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'English' : 'العربية',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('logo.jpeg',
                        width: 72, height: 72, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school_rounded,
                        size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      l.appTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.registerTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                l.registerSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),

              // ── Role selector ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(child: _RoleTab(l.student, true, _isStudent, () {
                      setState(() => _isStudent = true);
                    })),
                    Expanded(child: _RoleTab(l.teacher, false, !_isStudent, () {
                      setState(() => _isStudent = false);
                    })),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Full name ─────────────────────────────────────────────────
              _FieldLabel(l.fullName),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameCtrl,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: isAr ? 'أدخل الاسم بالكامل (يدعم العربية)' : l.fullName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.fullNameRequired;
                  if (v.trim().length < 2) return l.fullNameRequired;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Grade selector (for students) ─────────────────────────────
              if (_isStudent) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FieldLabel(l.gradeLevel),
                    if (_selectedGradeLevelId != null)
                      Text(
                        isAr ? 'تم الاختيار ✓' : 'Selected ✓',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: gradeLevelsAsync.when(
                    data: (grades) {
                      final active = grades.where((g) => g.isActive).toList()
                        ..sort((a, b) => a.order.compareTo(b.order));
                      if (active.isEmpty) {
                        return _buildFallbackGradeChips(isAr);
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: active.map((grade) {
                            final selected = _selectedGradeLevelId == grade.id;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _SelectableGradeChip(
                                label: grade.name,
                                isSelected: selected,
                                onTap: () {
                                  setState(() => _selectedGradeLevelId = grade.id);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => _buildFallbackGradeChips(isAr),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Email ─────────────────────────────────────────────────────
              _FieldLabel(l.email),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'example@domain.com',
                  hintTextDirection: TextDirection.ltr,
                  prefixIcon: Icon(Icons.email_outlined),
                  suffixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.emailRequired;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────────────────────────
              _FieldLabel(l.password),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintTextDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PasswordStrengthIndicator(
                          password: _passCtrl.text),
                      IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ],
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.passwordRequired;
                  if (v.length < 8) return l.passwordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Confirm Password ──────────────────────────────────────────
              _FieldLabel(l.confirmPassword),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintTextDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.passwordRequired;
                  if (v != _passCtrl.text) return l.passwordsMustMatch;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Terms notice ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'بإنشاء الحساب فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة بمنصة كامبريدج التعليمية.'
                            : 'By creating an account, you agree to Cambridge Educational Platform Terms of Service and Privacy Policy.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Error ─────────────────────────────────────────────────────
              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMsg,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Submit ────────────────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : _onRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLoading ? l.registering : l.createAccountAction,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Already have account ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.alreadyHaveAccount,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6)),
                    onPressed: () {
                      ref.read(authProvider.notifier).clearError();
                      context.pop();
                    },
                    child: Text(
                      l.login,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final bool isStudent;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleTab(this.label, this.isStudent, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isStudent ? Icons.school_rounded : Icons.person_pin_rounded,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableGradeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableGradeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  int get strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  Color get color {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return AppColors.secondary;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 6,
            height: 16,
            decoration: BoxDecoration(
              color: i < strength ? color : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}