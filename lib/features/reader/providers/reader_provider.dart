import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reader_models.dart';
import '../data/reader_repository.dart';

class ReaderState {
  final ReaderSession? session;
  final int currentPage;
  final bool isLoading;
  final bool isSavingProgress;
  final String? errorMessage;
  final List<ReaderAnnotation> annotations;
  final bool isSample;

  const ReaderState({
    this.session,
    this.currentPage = 1,
    this.isLoading = false,
    this.isSavingProgress = false,
    this.errorMessage,
    this.annotations = const [],
    this.isSample = false,
  });

  ReaderState copyWith({
    ReaderSession? session,
    int? currentPage,
    bool? isLoading,
    bool? isSavingProgress,
    String? errorMessage,
    bool clearError = false,
    List<ReaderAnnotation>? annotations,
    bool? isSample,
  }) {
    return ReaderState(
      session: session ?? this.session,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isSavingProgress: isSavingProgress ?? this.isSavingProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      annotations: annotations ?? this.annotations,
      isSample: isSample ?? this.isSample,
    );
  }

  int get totalPages => session?.totalPages ?? 1;
}

class ReaderNotifier extends StateNotifier<ReaderState> {
  final ReaderRepository _repository;
  final int bookId;
  final bool initialIsSample;

  ReaderNotifier(this._repository, {required this.bookId, this.initialIsSample = false})
      : super(ReaderState(isSample: initialIsSample)) {
    loadSession();
  }

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = initialIsSample
          ? await _repository.getSampleSession(bookId)
          : await _repository.getSession(bookId);

      if (!res.success || res.data == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty
              ? res.message
              : 'تعذر فتح جلسة القراءة للكتاب',
        );
        return;
      }

      final session = res.data!;
      final page = (session.lastPageRead > 0 && session.lastPageRead <= session.totalPages)
          ? session.lastPageRead
          : 1;

      state = state.copyWith(
        session: session,
        currentPage: page,
        isLoading: false,
        isSample: session.isSample,
      );

      // Load annotations for this page if not sample
      if (!session.isSample) {
        await loadAnnotations();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'حدث خطأ أثناء تحميل جلسة القراءة: $e',
      );
    }
  }

  Future<void> loadAnnotations() async {
    if (state.isSample) return;
    try {
      final res = await _repository.getAnnotations(bookId, pageNumber: state.currentPage);
      if (res.success && res.data != null) {
        state = state.copyWith(annotations: res.data!);
      }
    } catch (_) {}
  }

  Future<void> jumpToPage(int page) async {
    if (page < 1 || page > state.totalPages || page == state.currentPage) return;
    state = state.copyWith(currentPage: page);
    await loadAnnotations();

    // Persist reading progress for non-sample sessions
    if (!state.isSample) {
      _saveProgress(page);
    }
  }

  Future<void> nextPage() async {
    if (state.currentPage < state.totalPages) {
      await jumpToPage(state.currentPage + 1);
    }
  }

  Future<void> prevPage() async {
    if (state.currentPage > 1) {
      await jumpToPage(state.currentPage - 1);
    }
  }

  Future<void> _saveProgress(int page) async {
    try {
      await _repository.updateProgress(bookId, page);
    } catch (_) {
      // Progress saving fail is non-fatal
    }
  }

  Future<bool> addNote(String text, {String color = '#FFD54F'}) async {
    if (state.isSample || text.trim().isEmpty) return false;
    try {
      final req = SaveAnnotationRequest(
        pageNumber: state.currentPage,
        type: 'note',
        color: color,
        dataJson: jsonEncode({'text': text.trim()}),
      );
      final res = await _repository.saveAnnotation(bookId, req);
      if (res.success && res.data != null) {
        state = state.copyWith(
          annotations: [...state.annotations, res.data!],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteAnnotation(int id) async {
    try {
      final res = await _repository.deleteAnnotation(id);
      if (res.success) {
        state = state.copyWith(
          annotations: state.annotations.where((a) => a.id != id).toList(),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> clearCurrentPageAnnotations() async {
    try {
      final res = await _repository.clearPageAnnotations(bookId, state.currentPage);
      if (res.success) {
        state = state.copyWith(annotations: []);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final readerProvider = StateNotifierProvider.autoDispose
    .family<ReaderNotifier, ReaderState, ({int bookId, bool isSample})>(
  (ref, args) {
    final repo = ref.watch(readerRepositoryProvider);
    return ReaderNotifier(repo, bookId: args.bookId, initialIsSample: args.isSample);
  },
);
