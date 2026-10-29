import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../data/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../widgets/order_receipt_dialog.dart';
import '../widgets/reject_order_dialog.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/grade_level_form_dialog.dart';
import '../widgets/book_form_dialog.dart';

class AdminDashboardTab extends ConsumerWidget {
  final Function(int tabIndex) onNavigateTab;

  const AdminDashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final dashboardStatsState = ref.watch(adminDashboardStatsProvider);
    final dashboardStats = dashboardStatsState.stats;
    final isLoadingStats = dashboardStatsState.isLoading;
    final statsError = dashboardStatsState.error;
    final books = ref.watch(adminBooksProvider).books;
    final ordersState = ref.watch(adminOrdersProvider);

    final pendingOrders = ordersState.orders
        .where((o) => o.status == AdminOrderStatus.pendingVerification)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(adminDashboardStatsProvider.notifier).load(),
          ref.read(adminCategoriesProvider.notifier).load(),
          ref.read(adminGradeLevelsProvider.notifier).load(),
          ref.read(adminBooksProvider.notifier).load(),
          ref.read(adminOrdersProvider.notifier).load(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Welcome Banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'logo.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لوحة تحكم المشرف العام',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'إدارة المحتوى التعليمي والكتب والتحويلات المالية',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isLoadingStats && dashboardStats == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),

            if (statsError != null && dashboardStats == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statsError,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(adminDashboardStatsProvider.notifier).load(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),

            // ── Stat Cards ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    title: 'إجمالي المبيعات',
                    value: '${dashboardStats?.totalRevenue.toStringAsFixed(3) ?? "0.000"} ر.ع.',
                    icon: Icons.monetization_on_rounded,
                    color: Colors.green,
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    title: 'الطلبات المعلقة',
                    value: (dashboardStats?.pendingVerificationOrders ?? pendingOrders.length).toString(),
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    isAlert: (dashboardStats?.pendingVerificationOrders ?? pendingOrders.length) > 0,
                    onTap: () => onNavigateTab(1), // Orders tab
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    title: 'إجمالي الطلاب',
                    value: (dashboardStats?.totalStudents ?? 0).toString(),
                    icon: Icons.people_alt_rounded,
                    color: Colors.teal,
                    onTap: () => onNavigateTab(5), // Users tab
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    title: 'إجمالي الكتب',
                    value: (dashboardStats?.totalBooks ?? books.length).toString(),
                    icon: Icons.menu_book_rounded,
                    color: Colors.blue,
                    onTap: () => onNavigateTab(2), // Books tab
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    title: 'الطلبات المقبولة',
                    value: (dashboardStats?.approvedOrders ?? 0).toString(),
                    icon: Icons.check_circle_rounded,
                    color: Colors.purple,
                    onTap: () => onNavigateTab(1), // Orders tab
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    title: 'إجمالي المعلمين',
                    value: (dashboardStats?.totalTeachers ?? 0).toString(),
                    icon: Icons.school_rounded,
                    color: Colors.indigo,
                    onTap: () => onNavigateTab(5), // Users tab
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ────────────────────────────────────────────────
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // POST /api/Books
                  _AdminActionChip(
                    label: 'إضافة كتاب',
                    icon: Icons.add_circle_outline,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => BookFormDialog(
                          onCreate: (req) =>
                              ref.read(adminBooksProvider.notifier).add(req),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // POST /api/Categories
                  _AdminActionChip(
                    label: 'إضافة قسم',
                    icon: Icons.create_new_folder_outlined,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => CategoryFormDialog(
                          onSubmit: (req) =>
                              ref.read(adminCategoriesProvider.notifier).add(req),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // POST /api/GradeLevels
                  _AdminActionChip(
                    label: 'إضافة صف دراسي',
                    icon: Icons.add_home_work_outlined,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => GradeLevelFormDialog(
                          onSubmit: (req) =>
                              ref.read(adminGradeLevelsProvider.notifier).add(req),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // GET /api/Orders/admin  → Orders tab
                  _AdminActionChip(
                    label: 'مراجعة التحويلات',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => onNavigateTab(1),
                    badge: pendingOrders.isNotEmpty
                        ? '${pendingOrders.length}'
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Refresh: triggers all GET endpoints
                  _AdminActionChip(
                    label: 'تحديث البيانات',
                    icon: Icons.refresh_rounded,
                    onTap: () async {
                      await Future.wait([
                        ref.read(adminDashboardStatsProvider.notifier).load(),
                        ref.read(adminCategoriesProvider.notifier).load(),
                        ref.read(adminGradeLevelsProvider.notifier).load(),
                        ref.read(adminBooksProvider.notifier).load(),
                        ref.read(adminOrdersProvider.notifier).load(),
                      ]);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث جميع البيانات'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Top Selling Books Section (from api/admin/dashboard) ─────────
            if (dashboardStats != null && dashboardStats.topSellingBooks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الكتب الأكثر مبيعاً 🔥',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(2),
                    child: const Text('عرض كل الكتب'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...dashboardStats.topSellingBooks.take(4).map((book) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? Image.network(
                              book.coverUrl!,
                              width: 44,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 58,
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.menu_book, size: 22),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 58,
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.menu_book, size: 22),
                            ),
                    ),
                    title: Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${book.gradeLevelName} • ${book.categoryName}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${book.salesCount} مبيعات',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${book.totalRevenue.toStringAsFixed(3)} ر.ع.',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // ── Sales By Grade Level (from api/admin/dashboard) ──────────────
            if (dashboardStats != null && dashboardStats.salesByGrade.isNotEmpty) ...[
              Text(
                'توزيع المبيعات حسب الصف الدراسي 📊',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: dashboardStats.salesByGrade.map((grade) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  grade.gradeLevelName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${grade.ordersCount} طلبات • ${grade.totalRevenue.toStringAsFixed(3)} ر.ع. (${grade.percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (grade.percentage / 100).clamp(0.0, 1.0),
                                minHeight: 7,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Urgent Pending Orders Section ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'طلبات بنك مسقط المعلقة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (pendingOrders.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pendingOrders.length}',
                          style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () => onNavigateTab(1),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (pendingOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'لا توجد طلبات معلقة حالياً!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تم التحقق من كافة إشعارات التحويل البنكية بنجاح.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...pendingOrders.take(3).map((order) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_outlined,
                                  color: Colors.orange, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.bookTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${order.studentName} • ${order.amount.toStringAsFixed(3)} ${order.currency}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => OrderReceiptDialog(
                                    order: order,
                                    onApprove: () => ref
                                        .read(adminOrdersProvider.notifier)
                                        .approve(order.id),
                                    onReject: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => RejectOrderDialog(
                                          orderId: order.id,
                                          onConfirm: (reason) => ref
                                              .read(adminOrdersProvider.notifier)
                                              .reject(order.id, reason),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text('فحص الإشعار'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isAlert = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAlert
                ? Colors.orange.shade400
                : color.withValues(alpha: 0.2),
            width: isAlert ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 26),
                if (isAlert)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Styled quick action chip with solid black background and white text/icon
class _AdminActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _AdminActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
