import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../data/admin_models.dart';
import '../../providers/admin_provider.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterRole(String? role) {
    setState(() => _selectedRole = role);
    ref.read(adminUsersProvider.notifier).load(
          search: _searchController.text.trim(),
          role: role,
        );
  }

  void _onSearch(String query) {
    ref.read(adminUsersProvider.notifier).load(
          search: query.trim(),
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersState = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => notifier.load(
        search: _searchController.text.trim(),
        role: _selectedRole,
      ),
      child: Column(
        children: [
          // ── Search & Filter Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو البريد الإلكتروني...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _onSearch,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleChip('الكل', null),
                      const SizedBox(width: 8),
                      _buildRoleChip('الطلاب', 'Student'),
                      const SizedBox(width: 8),
                      _buildRoleChip('المعلمين', 'Teacher'),
                      const SizedBox(width: 8),
                      _buildRoleChip('المشرفين', 'Admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Users List ───────────────────────────────────────────────────
          Expanded(
            child: usersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : usersState.error != null
                    ? _buildError(context, usersState.error!, notifier)
                    : usersState.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text('لا يوجد مستخدمين مطابقين'),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: usersState.users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final user = usersState.users[idx];
                              return _UserCard(
                                user: user,
                                onToggleStatus: (active) async {
                                  final ok = await notifier.toggleStatus(user.id, active);
                                  if (ctx.mounted && ok) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(active
                                            ? 'تم تفعيل حساب ${user.fullName}'
                                            : 'تم تعطيل حساب ${user.fullName}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                onTap: () => _showUserDetails(context, user.id),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context, String error, AdminUsersNotifier notifier) {
    final isAuthError = error.contains('401') ||
        error.contains('انتهت صلاحية') ||
        error.contains('غير مصرح') ||
        error.contains('Unauthorized');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isAuthError ? Icons.lock_clock_rounded : Icons.error_outline,
                color: isAuthError ? Colors.orange : Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              isAuthError
                  ? 'انتهت صلاحية جلسة تسجيل الدخول'
                  : 'حدث خطأ أثناء تحميل المستخدمين',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              isAuthError
                  ? 'يرجى تسجيل الدخول مجدداً بحساب المشرف لمتابعة إدارة المستخدمين.'
                  : error,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isAuthError)
              FilledButton.icon(
                icon: const Icon(Icons.login_rounded),
                label: const Text('تسجيل الدخول مجدداً'),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: () => notifier.load(),
              ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _UserDetailSheet(userId: userId),
    );
  }

  Widget _buildRoleChip(String label, String? role) {
    final isSelected = _selectedRole == role;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      selected: isSelected,
      selectedColor: primary,
      checkmarkColor: Colors.white,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected ? primary : const Color(0xFFD1C4E9),
        width: isSelected ? 1.6 : 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onSelected: (_) => _onFilterRole(role),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onToggleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = user.role == 'Admin'
        ? Colors.purple
        : (user.role == 'Teacher' ? Colors.blue : Colors.teal);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role == 'Admin'
                                ? 'مشرف'
                                : (user.role == 'Teacher' ? 'معلم' : 'طالب'),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded,
                                size: 13, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${user.purchasedBooksCount} كتب',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 13, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '${user.totalSpent.toStringAsFixed(3)} ر.ع.',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: user.isActive,
                    onChanged: onToggleStatus,
                  ),
                  Text(
                    user.isActive ? 'نشط' : 'معطل',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDetailSheet extends ConsumerWidget {
  final String userId;

  const _UserDetailSheet({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(adminUserDetailProvider(userId));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return asyncDetail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
          data: (detail) {
            if (detail == null) {
              return const Center(child: Text('لم يتم العثور على المستخدم'));
            }
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        detail.fullName.isNotEmpty ? detail.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            detail.email,
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'الكتب المشتراة والصلاحية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (detail.purchasedBooks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'لم يقم هذا المستخدم بشراء أي كتب بعد',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  )
                else
                  ...detail.purchasedBooks.map((book) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.menu_book, color: AppColors.primary),
                        title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${book.gradeLevelName} • متبقي ${book.daysRemaining} يوم',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: book.isExpired ? Colors.red.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            book.isExpired ? 'منتهي' : 'ساري',
                            style: TextStyle(
                              color: book.isExpired ? Colors.red.shade900 : Colors.green.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'سجل طلبات التحويل البنكي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (detail.orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'لا توجد طلبات مسجلة',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  )
                else
                  ...detail.orders.map((order) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_rounded, color: Colors.orange),
                        title: Text(order.bookTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${order.amount.toStringAsFixed(3)} ${order.currency} • ${order.statusText}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}
