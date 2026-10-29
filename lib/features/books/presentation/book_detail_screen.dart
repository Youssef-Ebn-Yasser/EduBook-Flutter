import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/config/env_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/presentation/widgets/purchase_book_sheet.dart';
import '../../reader/data/reader_repository.dart';
import '../data/book_models.dart';
import '../providers/books_provider.dart';

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
                        if (book.semesterName != null)
                          _MetaChip(
                              icon: Icons.date_range_rounded,
                              label: book.semesterName!,
                              color: Colors.deepPurple),
                        if (book.academicYear != null &&
                            book.academicYear!.isNotEmpty)
                          _MetaChip(
                              icon: Icons.calendar_month,
                              label: 'العام: ${book.academicYear}'),
                        if (book.pageCount > 0)
                          _MetaChip(
                              icon: Icons.auto_stories,
                              label: '${book.pageCount} صفحة'),
                        if (book.isOfficialCurriculum)
                          const _MetaChip(
                              icon: Icons.verified_rounded,
                              label: 'منهج رسمي معتمد',
                              color: Colors.teal),
                        _MetaChip(
                            icon: Icons.timer,
                            label: '${book.validityDays} ${l.days}'),
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
                    Row(
                      children: [
                        Text(
                          'فصول ومحتويات الكتاب',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (book.units.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${book.units.length} فصول / وحدات',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (book.units.isNotEmpty)
                      ...book.units.map((unit) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        '${unit.order}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        unit.title,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (unit.isFreeSample) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'عينة مجانية',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (unit.description != null &&
                                    unit.description!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 38),
                                    child: Text(
                                      unit.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                                if (unit.hasYoutube || unit.hasPdfFile) ...[
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 38),
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        if (unit.hasYoutube)
                                          FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.play_circle_fill_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'مشاهدة الفيديو على يوتيوب',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () async {
                                              final uri = Uri.tryParse(
                                                  unit.youtubeUrl!.trim());
                                              if (uri != null &&
                                                  await canLaunchUrl(uri)) {
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'تعذر فتح رابط اليوتيوب'),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        if (unit.hasPdfFile)
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              side: BorderSide(
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'تحميل ملف الدرس (PDF)${unit.fileSizeFormatted.isNotEmpty ? " • ${unit.fileSizeFormatted}" : ""}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () =>
                                                _downloadOrOpenUnitPdf(
                                                    context, ref, book, unit),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ))
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.collections_bookmark_outlined,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                                size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'محتويات وفصول الكتاب',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'سيتم إدراج فهرس الفصول والدروس قريباً من قبل المعلم.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      '${book.price.toStringAsFixed(3)} ر.ع.',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (book.hasDiscount) ...[
                      Text(
                        '${book.originalPrice!.toStringAsFixed(3)} ر.ع.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'خصم ${book.discountPercentage}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
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

  Future<void> _downloadOrOpenUnitPdf(
    BuildContext context,
    WidgetRef ref,
    BookDetail book,
    BookUnit unit,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('جاري تحضير ملف الدرس...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final readerRepo = ref.read(readerRepositoryProvider);
      String? token;
      try {
        final session = await readerRepo.getSession(book.id);
        token = session.data?.readToken;
      } catch (_) {
        try {
          final sampleSession = await readerRepo.getSampleSession(book.id);
          token = sampleSession.data?.readToken;
        } catch (_) {}
      }

      String downloadUrl;
      if (token != null && token.isNotEmpty) {
        downloadUrl =
            '${EnvConfig.apiBaseUrl}/api/Reader/${book.id}/units/${unit.id}/stream?token=${Uri.encodeComponent(token)}';
      } else {
        downloadUrl =
            '${EnvConfig.apiBaseUrl}/api/Reader/${book.id}/units/${unit.id}/stream';
      }

      final uri = Uri.parse(downloadUrl);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحميل الملف، يرجى التأكد من اتصالك بالإنترنت'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل الملف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: c,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
