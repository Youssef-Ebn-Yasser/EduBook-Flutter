import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/book_models.dart';
import '../providers/books_provider.dart';

class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncBooks = ref.watch(myBooksProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l.myBooks,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: asyncBooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(l.errorLoadingBooks,
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l.retry),
                onPressed: () =>
                    ref.read(myBooksProvider.notifier).fetchMyBooks(),
              ),
            ],
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.library_books_outlined,
                      size: 80,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                  const SizedBox(height: 20),
                  Text(l.myBooksEmpty,
                      style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.explore),
                    label: Text(l.browseBooks),
                    onPressed: () => context.go('/books'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(myBooksProvider.notifier).fetchMyBooks(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (ctx, i) => _MyBookCard(book: books[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyBookCard extends StatelessWidget {
  final MyBookItem book;
  const _MyBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isExpired =
        book.isExpired || (!book.hasAccess && DateTime.now().isAfter(book.expiresAt));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!isExpired) {
            context.push('/reader/${book.bookId}');
          } else {
            context.push('/books/${book.bookId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderCover(theme: theme),
                      )
                    : _PlaceholderCover(theme: theme),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (book.publisherName != null)
                      Text(book.publisherName!,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55))),
                    const SizedBox(height: 6),
                    // Access status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? theme.colorScheme.error.withValues(alpha: 0.12)
                                : Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpired
                                    ? Icons.lock_outline
                                    : Icons.check_circle_outline,
                                size: 12,
                                color: isExpired
                                    ? theme.colorScheme.error
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isExpired ? l.accessExpired : l.accessValid,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isExpired
                                        ? theme.colorScheme.error
                                        : Colors.green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.validityDays}: ${book.expiresAt.day}/${book.expiresAt.month}/${book.expiresAt.year}',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              if (!isExpired)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: const Text('قراءة', style: TextStyle(fontSize: 12)),
                  onPressed: () => context.push('/reader/${book.bookId}'),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final ThemeData theme;
  const _PlaceholderCover({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 80,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.menu_book_rounded,
          color: theme.colorScheme.primary.withValues(alpha: 0.4)),
    );
  }
}
