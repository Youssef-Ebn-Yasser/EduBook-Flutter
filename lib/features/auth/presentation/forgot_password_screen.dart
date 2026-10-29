import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      context.push('/verify-otp', extra: <String, dynamic>{
        'email': _emailCtrl.text.trim(),
        'purpose': 'passwordReset',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final errorMsg =
        authState.status == AuthStatus.error ? authState.message : null;

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
          AppLocalizations.of(context)!.forgotPassword,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
            key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo ─────────────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'logo.jpeg',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.resetPassword,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.sendOtp,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Email ─────────────────────────────────────────────────────
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                onChanged: (_) {
                  if (ref.read(authProvider).status == AuthStatus.error) {
                    ref.read(authProvider.notifier).clearError();
                  }
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  hintText: 'example@domain.com',
                  hintTextDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return AppLocalizations.of(context)!.emailRequired;
                  }
                  if (!v.contains('@')) {
                    return AppLocalizations.of(context)!.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Error ──────────────────────────────────────────────────────
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

              // ── Send button ───────────────────────────────────────────────
              CustomButton(
                text: isLoading
                    ? AppLocalizations.of(context)!.sending
                    : AppLocalizations.of(context)!.sendOtp,
                icon: isLoading ? null : Icons.send_outlined,
                onPressed: isLoading ? () {} : _onSend,
              ),
              const SizedBox(height: 16),

              // ── Back ──────────────────────────────────────────────────────
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).clearError();
                  context.pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.login,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
);
}
}