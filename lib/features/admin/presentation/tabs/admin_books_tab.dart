import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../books/data/book_models.dart';
import '../../providers/admin_provider.dart';
import '../widgets/book_form_dialog.dart';
import '../widgets/book_units_dialog.dart';

class AdminBooksTab extends ConsumerStatefulWidget {
  const AdminBooksTab({super.key});

  @override
  ConsumerState<AdminBooksTab> createState() => _AdminBooksTabState();
}

class _AdminBooksTabState extends ConsumerState<AdminBooksTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => BookFormDialog(
        onCreate: (req) async {
          final ok = await ref.read(adminBooksProvider.notifier).add(req);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت إضافة الكتاب بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _openEditDialog(BookListItem book) {
    showDialog(
      context: context,
      builder: (_) => BookFormDialog(
        book: book,
        onUpdate: (id, req) async {
          final ok = await ref.read(adminBooksProvider.notifier).edit(id, req);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث بيانات الكتاب بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BookListItem book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الكتاب'),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف كتاب "${book.title}"؟ سيتم حذف جميع ملفات وفصول الكتاب نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await ref.read(adminBooksProvider.notifier).delete(book.id);
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الكتاب بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBooksProvider);
    final theme = Theme.of(context);

    final filtered = state.books.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.title.toLowerCase().contains(q) ||
          b.categoryName.toLowerCase().contains(q) ||
          b.gradeLevelName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminBooksProvider.notifier).load(),
        child: Column(
          children: [
            // ── Search & Header bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'البحث في الكتب بالعنوان أو القسم...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة كتاب'),
                  ),
                ],
              ),
            ),

            // ── Books List ──────────────────────────────────────────────────
            if (state.isLoading && state.books.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'لم يتم العثور على كتب مسجلة'
                            : 'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _openCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة أول كتاب'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final book = filtered[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book Cover Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 70,
                                height: 95,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                child: book.coverUrl != null &&
                                        book.coverUrl!.isNotEmpty
                                    ? Image.network(
                                        book.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.menu_book_rounded,
                                                color: Colors.grey),
                                      )
                                    : const Icon(Icons.menu_book_rounded,
                                        color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Book Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          book.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (book.isActive
                                                  ? Colors.green
                                                  : Colors.grey)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          book.isActive ? 'متاح' : 'معطل',
                                          style: TextStyle(
                                            color: book.isActive
                                                ? Colors.green.shade800
                                                : Colors.grey.shade800,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          book.categoryName,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          book.gradeLevelName,
                                          style: const TextStyle(
                                            color: Colors.purple,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: AlignmentDirectional.centerStart,
                                          child: Text(
                                            '${book.price.toStringAsFixed(3)} ر.ع',
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.format_list_bulleted_rounded,
                                                color: Colors.deepPurple, size: 20),
                                            tooltip: 'إدارة الفصول والدروس وملفات PDF',
                                            onPressed: () =>
                                                BookUnitsDialog.show(context, book),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.edit_outlined,
                                                color: Colors.blue, size: 20),
                                            tooltip: 'تعديل',
                                            onPressed: () =>
                                                _openEditDialog(book),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20),
                                            tooltip: 'حذف',
                                            onPressed: () =>
                                                _confirmDelete(book),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
