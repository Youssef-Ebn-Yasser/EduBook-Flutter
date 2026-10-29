import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/localization/localization_provider.dart';
import '../../../app/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (success) {
      final isAdmin = ref.read(authProvider).isAdmin;
      if (isAdmin) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final errorMsg =
        authState.status == AuthStatus.error ? authState.message : null;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Language switch
                    _TopBarButton(
                      label: isAr ? 'English' : 'العربية',
                      icon: Icons.language_rounded,
                      onTap: () => ref
                          .read(localeNotifierProvider.notifier)
                          .toggleLanguage(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo ─────────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset('logo.jpeg', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── App name ────────────────────────────────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l.appTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Welcome heading ─────────────────────────────────────
                      Text(
                        l.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.welcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Email field ─────────────────────────────────────────
                      Text(
                        l.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        onChanged: (_) {
                          if (ref.read(authProvider).status ==
                              AuthStatus.error) {
                            ref.read(authProvider.notifier).clearError();
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'example@domain.com',
                          hintTextDirection: TextDirection.ltr,
                          suffixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l.emailRequired;
                          if (!v.contains('@')) return l.invalidEmail;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Password field ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l.password,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              ref.read(authProvider.notifier).clearError();
                              context.push('/forgot-password');
                            },
                            child: Text(
                              l.forgotPassword,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        onChanged: (_) {
                          if (ref.read(authProvider).status ==
                              AuthStatus.error) {
                            ref.read(authProvider.notifier).clearError();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintTextDirection: TextDirection.ltr,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l.passwordRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Error ───────────────────────────────────────────────
                      if (errorMsg != null) ...[
                        _ErrorBanner(message: errorMsg),
                        const SizedBox(height: 12),
                      ],

                      // ── Login button ────────────────────────────────────────
                      _PrimaryButton(
                        text: isLoading ? l.loggingIn : l.login,
                        icon: isLoading ? null : Icons.arrow_forward_rounded,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _onLogin,
                      ),
                      const SizedBox(height: 24),

                      // ── Info banner ─────────────────────────────────────────
                      _InfoBanner(text: l.tagline),
                      const SizedBox(height: 24),

                      // ── Register link ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l.noAccount,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            onPressed: () {
                              ref.read(authProvider.notifier).clearError();
                              context.push('/register');
                            },
                            child: Text(
                              l.createNewAccount,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Terms ───────────────────────────────────────────────
                      const SizedBox(height: 8),
                      const Text(
                        'بتسجيل دخولك فإنك توافق تماماً على الشروط والأحكام وخصوصية البيانات.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

// ── Shared UI Components ─────────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.text,
    this.icon,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}