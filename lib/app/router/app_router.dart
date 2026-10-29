import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/books/presentation/books_screen.dart';
import '../../features/books/presentation/book_detail_screen.dart';
import '../../features/books/presentation/my_books_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/orders/presentation/my_orders_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

// Public routes that do NOT require authentication
const _publicRoutes = {
  '/login',
  '/register',
  '/forgot-password',
  '/verify-otp',
  '/reset-password',
};

/// A ChangeNotifier that fires whenever [authProvider] state changes,
/// allowing GoRouter to re-evaluate its redirect logic.
class _AuthNotifierBridge extends ChangeNotifier {
  _AuthNotifierBridge(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final bridge = _AuthNotifierBridge(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: bridge,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isAdmin = authState.isAdmin;
      final path = state.matchedLocation;

      final isPublic = _publicRoutes.any((r) => path.startsWith(r));

      // Not authenticated → force login
      if (!isAuthenticated && !isPublic) return '/login';

      // Authenticated but still on login → send to correct home
      if (isAuthenticated && path == '/login') {
        return isAdmin ? '/admin' : '/home';
      }

      // Non-admin blocked from admin area
      if (isAuthenticated && !isAdmin && path.startsWith('/admin')) {
        return '/home';
      }

      return null; // allow navigation
    },
    routes: [
      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : const <dynamic, dynamic>{};
          final email = (map['email'] ?? state.uri.queryParameters['email'] ?? '').toString();
          final purpose = (map['purpose'] ?? state.uri.queryParameters['purpose'] ?? 'emailVerification').toString();
          return VerifyOtpScreen(
            email: email,
            purpose: purpose,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : const <dynamic, dynamic>{};
          final email = (map['email'] ?? state.uri.queryParameters['email'] ?? '').toString();
          final otpCode = (map['otpCode'] ?? state.uri.queryParameters['otpCode'] ?? '').toString();
          return ResetPasswordScreen(
            email: email,
            otpCode: otpCode,
          );
        },
      ),

      // ── Admin ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),

      // ── Main App ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/books',
        builder: (context, state) => const BooksScreen(),
      ),
      GoRoute(
        path: '/books/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BookDetailScreen(bookId: id);
        },
      ),
      GoRoute(
        path: '/my-books',
        builder: (context, state) => const MyBooksScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/reader/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final isSample = state.uri.queryParameters['sample'] == 'true';
          return ReaderScreen(bookId: id, isSample: isSample);
        },
      ),
    ],
  );
});