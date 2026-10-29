import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../widgets/grade_level_form_dialog.dart';

class AdminGradeLevelsTab extends ConsumerStatefulWidget {
  const AdminGradeLevelsTab({super.key});

  @override
  ConsumerState<AdminGradeLevelsTab> createState() =>
      _AdminGradeLevelsTabState();
}

class _AdminGradeLevelsTabState extends ConsumerState<AdminGradeLevelsTab> {
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
      builder: (_) => GradeLevelFormDialog(
        onSubmit: (req) async {
          final ok =
              await ref.read(adminGradeLevelsProvider.notifier).add(req);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت إضافة الصف الدراسي بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _openEditDialog(AdminGradeLevel grade) {
    showDialog(
      context: context,
      builder: (_) => GradeLevelFormDialog(
        gradeLevel: grade,
        onSubmit: (req) async {
          final ok = await ref
              .read(adminGradeLevelsProvider.notifier)
              .edit(grade.id, req);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الصف الدراسي بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(AdminGradeLevel grade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الصف الدراسي'),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف "${grade.name}"؟ لا يمكن التراجع عن هذه العملية.'),
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
          await ref.read(adminGradeLevelsProvider.notifier).delete(grade.id);
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الصف الدراسي بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminGradeLevelsProvider);
    final theme = Theme.of(context);

    final sorted = [...state.gradeLevels]
      ..sort((a, b) => a.order.compareTo(b.order));

    final filtered = sorted.where((g) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return g.name.toLowerCase().contains(q) ||
          g.order.toString().contains(q);
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminGradeLevelsProvider.notifier).load(),
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
                        hintText: 'البحث في الصفوف الدراسية...',
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
                    label: const Text('إضافة صف'),
                  ),
                ],
              ),
            ),

            // ── Grades List ─────────────────────────────────────────────────
            if (state.isLoading && state.gradeLevels.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'لم يتم العثور على صفوف دراسية'
                            : 'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _openCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة أول صف دراسي'),
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
                    final grade = filtered[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.secondary.withValues(alpha: 0.15),
                          child: Text(
                            '${grade.order}',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                grade.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    (grade.isActive ? Colors.green : Colors.grey)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                grade.isActive ? 'نشط' : 'معطل',
                                style: TextStyle(
                                  color: grade.isActive
                                      ? Colors.green.shade800
                                      : Colors.grey.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'ترتيب العرض: #${grade.order}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blue),
                              tooltip: 'تعديل',
                              onPressed: () => _openEditDialog(grade),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'حذف',
                              onPressed: () => _confirmDelete(grade),
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
