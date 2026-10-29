import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/book_models.dart';
import '../providers/books_provider.dart';
import '../../orders/presentation/widgets/purchase_book_sheet.dart';

class BookDetailScreen extends ConsumerWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncBook = ref.watch(bookDetailProvider(bookId));

    return Scaffold(
      body: asyncBook.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(l.bookDetails)),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Text(l.errorLoadingBooks),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(bookDetailProvider(bookId)),
                  child: Text(l.retry),
                ),
              ],
            ),
          ),
        ),
        data: (book) => CustomScrollView(
          slivers: [
            // ── App bar with cover ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  book.title,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Center(
                            child: Icon(Icons.menu_book_rounded,
                                size: 80,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(Icons.menu_book_rounded,
                              size: 80,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4)),
                        ),
                      ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ────────────────────────────────────────────────
                    Text(book.title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(book.publisherName,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                    const SizedBox(height: 16),

                    // ── Price + Buy / Access section (Responsive) ──────────
                    ref.watch(bookAccessProvider(bookId)).when(
                      data: (access) {
                        if (access.hasAccess) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'أنت تمتلك هذا الكتاب',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'متبقي ${access.daysRemaining} يوم في صلاحية الوصول',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  icon: const Icon(Icons.menu_book, size: 16),
                                  label: const Text('قراءة', style: TextStyle(fontSize: 12)),
                                  onPressed: () => context.push('/reader/${book.id}'),
                                ),
                              ],
                            ),
                          );
                        }
                        return _buildBuyRow(context, theme, book);
                      },
                      loading: () => _buildBuyRow(context, theme, book),
                      error: (_, __) => _buildBuyRow(context, theme, book),
                    ),
                    const SizedBox(height: 16),

                    // ── Meta chips ────────────────────────────────────────
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                            icon: Icons.school,
                            label: '${l.gradeLevel}: ${book.gradeLevelName}'),
                        _MetaChip(
                            icon: Icons.category,
                            label: '${l.category}: ${book.categoryName}'),
                        _MetaChip(
                            icon: Icons.timer,
                            label:
                                '${book.validityDays} ${l.days}'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Description ───────────────────────────────────────
                    if (book.description != null &&
                        book.description!.isNotEmpty) ...[
                      Text(l.description,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(book.description!,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                              height: 1.6)),
                      const SizedBox(height: 24),
                    ],

                    // ── Chapters / Units ──────────────────────────────────
                    if (book.units.isNotEmpty) ...[
                      Text(l.units,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...book.units.map((unit) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Text(
                                '${unit.order}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(unit.title,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: unit.description != null
                                ? Text(unit.description!,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                          )),
                      const SizedBox(height: 24),
                    ],

                    // ── Active file info ──────────────────────────────────
                    if (book.activeFile != null) ...[
                      Text(l.version,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: Colors.red),
                          title: Text(
                              book.activeFile!.fileName ?? 'book.pdf'),
                          subtitle: Text(
                              '${l.version} ${book.activeFile!.version} • ${book.activeFile!.fileSizeMb}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () {},
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyRow(BuildContext context, ThemeData theme, BookDetail book) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سعر الاشتراك السنوي',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${book.price.toStringAsFixed(3)} ر.ع.',
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: FilledButton.icon(
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text(
                  'شراء (تحويل بنكي)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onPressed: () => PurchaseBookSheet.show(context, book),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
