import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../widgets/category_form_dialog.dart';

class AdminCategoriesTab extends ConsumerStatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  ConsumerState<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends ConsumerState<AdminCategoriesTab> {
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
      builder: (_) => CategoryFormDialog(
        onSubmit: (req) async {
          final ok = await ref.read(adminCategoriesProvider.notifier).add(req);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت إضافة القسم بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _openEditDialog(AdminCategory cat) {
    showDialog(
      context: context,
      builder: (_) => CategoryFormDialog(
        category: cat,
        onSubmit: (req) async {
          final ok =
              await ref.read(adminCategoriesProvider.notifier).edit(cat.id, req);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث القسم بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(AdminCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف القسم'),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف قسم "${cat.name}"؟ لا يمكن التراجع عن هذه العملية.'),
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
      final ok =
          await ref.read(adminCategoriesProvider.notifier).delete(cat.id);
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف القسم بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCategoriesProvider);
    final theme = Theme.of(context);

    final filtered = state.categories.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.description?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminCategoriesProvider.notifier).load(),
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
                        hintText: 'البحث في الأقسام...',
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
                    label: const Text('إضافة قسم'),
                  ),
                ],
              ),
            ),

            // ── Categories List ─────────────────────────────────────────────
            if (state.isLoading && state.categories.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'لم يتم العثور على أقسام مسجلة'
                            : 'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _openCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة أول قسم'),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final cat = filtered[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.folder_outlined,
                              color: theme.colorScheme.primary),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (cat.isActive ? Colors.green : Colors.grey)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                cat.isActive ? 'نشط' : 'معطل',
                                style: TextStyle(
                                  color: cat.isActive
                                      ? Colors.green.shade800
                                      : Colors.grey.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: cat.description != null &&
                                cat.description!.isNotEmpty
                            ? Text(
                                cat.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blue),
                              tooltip: 'تعديل',
                              onPressed: () => _openEditDialog(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'حذف',
                              onPressed: () => _confirmDelete(cat),
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
