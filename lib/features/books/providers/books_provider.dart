import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/book_models.dart';
import '../data/books_repository.dart';
import '../../admin/data/admin_models.dart';

// ─── Books List Provider ───────────────────────────────────────────────────────

class BooksState {
  final List<BookListItem> books;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final BookQueryParams params;

  const BooksState({
    this.books = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.params = const BookQueryParams(),
  });

  BooksState copyWith({
    List<BookListItem>? books,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    BookQueryParams? params,
  }) =>
      BooksState(
        books: books ?? this.books,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        hasMore: hasMore ?? this.hasMore,
        params: params ?? this.params,
      );
}

class BooksNotifier extends StateNotifier<BooksState> {
  final BooksRepository _repo;

  BooksNotifier(this._repo) : super(const BooksState()) {
    fetchBooks();
  }

  Future<void> fetchBooks({bool refresh = true}) async {
    final newParams = refresh
        ? state.params.copyWith(page: 1)
        : state.params.copyWith(page: state.params.page + 1);

    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, params: newParams);
    } else {
      state = state.copyWith(isLoadingMore: true, params: newParams);
    }

    try {
      final result = await _repo.getBooks(newParams);
      if (result.success && result.data != null) {
        final newBooks = refresh
            ? result.data!.items
            : [...state.books, ...result.data!.items];
        state = state.copyWith(
          books: newBooks,
          isLoading: false,
          isLoadingMore: false,
          hasMore: result.data!.hasMore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: result.message.isNotEmpty ? result.message : 'Failed to load books',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.message ?? 'Network error',
      );
    }
  }

  void updateSearch(String search) {
    state = state.copyWith(
      params: state.params.copyWith(search: search, page: 1),
    );
    fetchBooks();
  }

  void updateFilters({int? categoryId, int? gradeLevelId, String? sortBy}) {
    state = state.copyWith(
      params: state.params.copyWith(
        categoryId: categoryId,
        gradeLevelId: gradeLevelId,
        sortBy: sortBy,
        page: 1,
      ),
    );
    fetchBooks();
  }

  void loadMore() {
    if (!state.isLoadingMore && state.hasMore) {
      fetchBooks(refresh: false);
    }
  }
}

final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  return BooksNotifier(ref.read(booksRepositoryProvider));
});

// ─── Book Detail Provider ──────────────────────────────────────────────────────

final bookDetailProvider =
    FutureProvider.family<BookDetail, int>((ref, id) async {
  return (await ref.read(booksRepositoryProvider).getBookById(id)).data!;
});

// ─── My Books Provider ─────────────────────────────────────────────────────────

class MyBooksNotifier extends StateNotifier<AsyncValue<List<MyBookItem>>> {
  final BooksRepository _repo;

  MyBooksNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchMyBooks();
  }

  Future<void> fetchMyBooks() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.getMyBooks();
      if (result.success && result.data != null) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.message, StackTrace.current);
      }
    } on DioException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Network error', st);
    }
  }
}

final myBooksProvider =
    StateNotifierProvider<MyBooksNotifier, AsyncValue<List<MyBookItem>>>((ref) {
  return MyBooksNotifier(ref.read(booksRepositoryProvider));
});

// ─── Book Access Provider ──────────────────────────────────────────────────────

final bookAccessProvider =
    FutureProvider.family<BookAccessResponse, int>((ref, bookId) async {
  try {
    final res = await ref.read(booksRepositoryProvider).checkAccess(bookId);
    return res.data ?? const BookAccessResponse(hasAccess: false);
  } catch (_) {
    return const BookAccessResponse(hasAccess: false);
  }
});

// ─── Public Grade Levels Provider ──────────────────────────────────────────────

final publicGradeLevelsProvider =
    FutureProvider<List<AdminGradeLevel>>((ref) async {
  return ref.read(booksRepositoryProvider).getGradeLevels();
});

// ─── Home Books Provider ────────────────────────────────────────────────────────

final homeBooksProvider =
    FutureProvider.family<List<BookListItem>, int?>((ref, gradeId) async {
  final repo = ref.read(booksRepositoryProvider);
  final res = await repo
      .getBooks(BookQueryParams(gradeLevelId: gradeId, pageSize: 20));
  return res.data?.items ?? [];
});


