import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../books/data/book_models.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

String formatApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) {
      return 'انتهت صلاحية جلسة تسجيل الدخول. يرجى إعادة تسجيل الدخول للمتابعة.';
    }
    if (status == 403) {
      return 'ليس لديك صلاحية وصول (خاصة بالمشرفين فقط).';
    }
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) return errors.first.toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';
    }
    return 'تعذر الاتصال بالخادم (${status ?? "خطأ في الشبكة"}).';
  }
  return error.toString();
}

// ─── Categories Provider ──────────────────────────────────────────────────────

class AdminCategoriesState {
  final List<AdminCategory> categories;
  final bool isLoading;
  final String? error;

  const AdminCategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  AdminCategoriesState copyWith({
    List<AdminCategory>? categories,
    bool? isLoading,
    String? error,
  }) =>
      AdminCategoriesState(
        categories: categories ?? this.categories,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AdminCategoriesNotifier extends StateNotifier<AdminCategoriesState> {
  final AdminRepository _repo;

  AdminCategoriesNotifier(this._repo) : super(const AdminCategoriesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getCategories();
      state = state.copyWith(
        isLoading: false,
        categories: res.data ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> add(CategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.createCategory(request);
      if (res.data != null) {
        state = state.copyWith(
          isLoading: false,
          categories: [...state.categories, res.data!],
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> edit(int id, CategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.updateCategory(id, request);
      if (res.data != null) {
        final updated = state.categories.map((c) {
          return c.id == id ? res.data! : c;
        }).toList();
        state = state.copyWith(isLoading: false, categories: updated);
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.deleteCategory(id);
      if (res.success) {
        state = state.copyWith(
          isLoading: false,
          categories: state.categories.where((c) => c.id != id).toList(),
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminCategoriesProvider =
    StateNotifierProvider<AdminCategoriesNotifier, AdminCategoriesState>((ref) {
  return AdminCategoriesNotifier(ref.read(adminRepositoryProvider));
});

// ─── Grade Levels Provider ────────────────────────────────────────────────────

class AdminGradeLevelsState {
  final List<AdminGradeLevel> gradeLevels;
  final bool isLoading;
  final String? error;

  const AdminGradeLevelsState({
    this.gradeLevels = const [],
    this.isLoading = false,
    this.error,
  });

  AdminGradeLevelsState copyWith({
    List<AdminGradeLevel>? gradeLevels,
    bool? isLoading,
    String? error,
  }) =>
      AdminGradeLevelsState(
        gradeLevels: gradeLevels ?? this.gradeLevels,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AdminGradeLevelsNotifier extends StateNotifier<AdminGradeLevelsState> {
  final AdminRepository _repo;

  AdminGradeLevelsNotifier(this._repo) : super(const AdminGradeLevelsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getGradeLevels();
      state = state.copyWith(
        isLoading: false,
        gradeLevels: res.data ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> add(GradeLevelRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.createGradeLevel(request);
      if (res.data != null) {
        state = state.copyWith(
          isLoading: false,
          gradeLevels: [...state.gradeLevels, res.data!],
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> edit(int id, GradeLevelRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.updateGradeLevel(id, request);
      if (res.data != null) {
        final updated = state.gradeLevels.map((g) {
          return g.id == id ? res.data! : g;
        }).toList();
        state = state.copyWith(isLoading: false, gradeLevels: updated);
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.deleteGradeLevel(id);
      if (res.success) {
        state = state.copyWith(
          isLoading: false,
          gradeLevels: state.gradeLevels.where((g) => g.id != id).toList(),
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminGradeLevelsProvider =
    StateNotifierProvider<AdminGradeLevelsNotifier, AdminGradeLevelsState>(
        (ref) {
  return AdminGradeLevelsNotifier(ref.read(adminRepositoryProvider));
});

// ─── Books Provider ───────────────────────────────────────────────────────────

class AdminBooksState {
  final List<BookListItem> books;
  final bool isLoading;
  final String? error;

  const AdminBooksState({
    this.books = const [],
    this.isLoading = false,
    this.error,
  });

  AdminBooksState copyWith({
    List<BookListItem>? books,
    bool? isLoading,
    String? error,
  }) =>
      AdminBooksState(
        books: books ?? this.books,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AdminBooksNotifier extends StateNotifier<AdminBooksState> {
  final AdminRepository _repo;

  AdminBooksNotifier(this._repo) : super(const AdminBooksState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getBooks();
      state = state.copyWith(
        isLoading: false,
        books: res.data?.items ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> add(CreateBookRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.createBook(request);
      if (res.data != null) {
        await load();
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> edit(int id, UpdateBookRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.updateBook(id, request);
      if (res.data != null) {
        await load();
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.deleteBook(id);
      if (res.success) {
        state = state.copyWith(
          isLoading: false,
          books: state.books.where((b) => b.id != id).toList(),
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminBooksProvider =
    StateNotifierProvider<AdminBooksNotifier, AdminBooksState>((ref) {
  return AdminBooksNotifier(ref.read(adminRepositoryProvider));
});

// ─── Orders Provider ──────────────────────────────────────────────────────────

class AdminOrdersState {
  final List<AdminOrder> orders;
  final int? filterStatus; // null: all, 0: pending, 1: approved, 2: rejected
  final bool isLoading;
  final String? error;

  const AdminOrdersState({
    this.orders = const [],
    this.filterStatus,
    this.isLoading = false,
    this.error,
  });

  AdminOrdersState copyWith({
    List<AdminOrder>? orders,
    int? filterStatus,
    bool clearFilter = false,
    bool? isLoading,
    String? error,
  }) =>
      AdminOrdersState(
        orders: orders ?? this.orders,
        filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  int get pendingCount =>
      orders.where((o) => o.status == AdminOrderStatus.pendingVerification).length;
}

class AdminOrdersNotifier extends StateNotifier<AdminOrdersState> {
  final AdminRepository _repo;

  AdminOrdersNotifier(this._repo) : super(const AdminOrdersState()) {
    load();
  }

  Future<void> load({int? status, bool clearFilter = false}) async {
    final effectiveStatus = clearFilter ? null : (status ?? state.filterStatus);
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterStatus: effectiveStatus,
      clearFilter: clearFilter,
    );
    try {
      final res = await _repo.getAdminOrders(status: effectiveStatus);
      state = state.copyWith(
        isLoading: false,
        orders: res.data ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatApiError(e));
    }
  }

  Future<bool> approve(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.approveOrder(id);
      if (res.success) {
        await load();
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reject(int id, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.rejectOrder(id, reason);
      if (res.success) {
        await load();
        return true;
      }
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminOrdersProvider =
    StateNotifierProvider<AdminOrdersNotifier, AdminOrdersState>((ref) {
  return AdminOrdersNotifier(ref.read(adminRepositoryProvider));
});

// ─── Admin Dashboard Stats Provider ──────────────────────────────────────────

class AdminDashboardStatsState {
  final AdminDashboardStats? stats;
  final bool isLoading;
  final String? error;

  const AdminDashboardStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  AdminDashboardStatsState copyWith({
    AdminDashboardStats? stats,
    bool? isLoading,
    String? error,
  }) =>
      AdminDashboardStatsState(
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AdminDashboardStatsNotifier extends StateNotifier<AdminDashboardStatsState> {
  final AdminRepository _repo;

  AdminDashboardStatsNotifier(this._repo) : super(const AdminDashboardStatsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getDashboardStats();
      if (res.success && res.data != null) {
        state = state.copyWith(isLoading: false, stats: res.data);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.message.isNotEmpty ? res.message : 'تعذر تحميل إحصائيات لوحة التحكم',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatApiError(e));
    }
  }
}

final adminDashboardStatsProvider =
    StateNotifierProvider<AdminDashboardStatsNotifier, AdminDashboardStatsState>((ref) {
  return AdminDashboardStatsNotifier(ref.read(adminRepositoryProvider));
});

// ─── Admin Users Provider ───────────────────────────────────────────────────

class AdminUsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedRole; // Student, Teacher, etc.

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedRole,
  });

  AdminUsersState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedRole,
    bool clearRole = false,
  }) =>
      AdminUsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedRole: clearRole ? null : (selectedRole ?? this.selectedRole),
      );
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminRepository _repo;

  AdminUsersNotifier(this._repo) : super(const AdminUsersState()) {
    load();
  }

  Future<void> load({String? search, String? role}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: search ?? state.searchQuery,
      selectedRole: role ?? state.selectedRole,
    );
    try {
      final res = await _repo.getUsers(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        role: state.selectedRole,
      );
      if (res.success && res.data != null) {
        state = state.copyWith(isLoading: false, users: res.data!);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.message.isNotEmpty ? res.message : 'تعذر تحميل المستخدمين',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatApiError(e));
    }
  }

  Future<bool> toggleStatus(String userId, bool isActive) async {
    try {
      final res = await _repo.toggleUserStatus(userId, isActive);
      if (res.success) {
        final updated = state.users.map((u) {
          if (u.id == userId) {
            return AdminUser(
              id: u.id,
              fullName: u.fullName,
              email: u.email,
              phoneNumber: u.phoneNumber,
              role: u.role,
              isActive: isActive,
              createdAt: u.createdAt,
              purchasedBooksCount: u.purchasedBooksCount,
              totalSpent: u.totalSpent,
            );
          }
          return u;
        }).toList();
        state = state.copyWith(users: updated);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref.read(adminRepositoryProvider));
});

final adminUserDetailProvider = FutureProvider.family<AdminUserDetail?, String>((ref, userId) async {
  final repo = ref.read(adminRepositoryProvider);
  final res = await repo.getUserDetail(userId);
  return res.data;
});

