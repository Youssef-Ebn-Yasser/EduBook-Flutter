import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

/// purpose: 'emailVerification' | 'passwordReset'
class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String purpose; // 'emailVerification' | 'passwordReset'

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  // 6 individual OTP digit controllers & focus nodes
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Resend timer
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  bool get _isEmailVerification => widget.purpose == 'emailVerification';

  Future<void> _onVerify() async {
    final otp = _otp;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.otpRequired)),
      );
      return;
    }

    if (_isEmailVerification) {
      final success =
          await ref.read(authProvider.notifier).verifyEmail(widget.email, otp);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.success)),
        );
        context.go('/login');
      }
    } else {
      // passwordReset: first check the OTP is right with backend
      final success = await ref
          .read(authProvider.notifier)
          .verifyPasswordResetOtp(widget.email, otp);
      if (!mounted) return;
      if (success) {
        // Second: move to enter password and confirm password only if OTP is right
        context.push('/reset-password', extra: <String, dynamic>{
          'email': widget.email,
          'otpCode': otp,
        });
      }
    }
  }

  Future<void> _onResend() async {
    bool success;
    if (_isEmailVerification) {
      success = await ref
          .read(authProvider.notifier)
          .resendVerificationOtp(widget.email);
    } else {
      success = await ref
          .read(authProvider.notifier)
          .resendPasswordResetOtp(widget.email);
    }
    if (!mounted) return;
    if (success) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.success)),
      );
    }
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _ctrls[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.primarySurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEmailVerification
              ? AppLocalizations.of(context)!.verify
              : AppLocalizations.of(context)!.enterOtp,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo ─────────────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'logo.jpeg',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.email_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              _isEmailVerification
                  ? AppLocalizations.of(context)!.verify
                  : AppLocalizations.of(context)!.enterOtp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.otpSentTo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            // Email badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    widget.email,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.email_outlined,
                      size: 13, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── OTP boxes ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, _buildDigitBox),
            ),
            const SizedBox(height: 24),

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

            // ── Verify button ──────────────────────────────────────────────
            CustomButton(
              text: isLoading
                  ? AppLocalizations.of(context)!.verifying
                  : AppLocalizations.of(context)!.verify,
              onPressed: isLoading ? () {} : _onVerify,
            ),
            const SizedBox(height: 20),

            // ── Resend ─────────────────────────────────────────────────────
            // Resend timer display
            if (_secondsLeft > 0) ...[  
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 15, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.resendCode}: 00:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: null,
                child: Text(
                  AppLocalizations.of(context)!.resendCode,
                  style: const TextStyle(color: AppColors.textHint),
                ),
              ),
            ] else ...[  
              TextButton(
                onPressed: _onResend,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.resendCode,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
