import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../widgets/order_receipt_dialog.dart';
import '../widgets/reject_order_dialog.dart';

class AdminOrdersTab extends ConsumerStatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  ConsumerState<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends ConsumerState<AdminOrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Filter tabs: 0=All, 1=Pending, 2=Approved, 3=Rejected
  static const _filterLabels = ['الكل', 'معلق', 'مقبول', 'مرفوض'];
  static const _filterValues = [null, 0, 1, 2];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _filterValues[_tabController.index];
        if (status == null) {
          ref.read(adminOrdersProvider.notifier).load(clearFilter: true);
        } else {
          ref.read(adminOrdersProvider.notifier).load(status: status);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(AdminOrderStatus status) {
    switch (status) {
      case AdminOrderStatus.pendingVerification:
        return Colors.orange;
      case AdminOrderStatus.approved:
        return Colors.green;
      case AdminOrderStatus.rejected:
        return Colors.red;
      case AdminOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _statusIcon(AdminOrderStatus status) {
    switch (status) {
      case AdminOrderStatus.pendingVerification:
        return Icons.hourglass_top_rounded;
      case AdminOrderStatus.approved:
        return Icons.check_circle_rounded;
      case AdminOrderStatus.rejected:
        return Icons.cancel_rounded;
      case AdminOrderStatus.cancelled:
        return Icons.block_rounded;
    }
  }

  void _showReceiptDialog(BuildContext context, AdminOrder order) {
    if (order.status != AdminOrderStatus.pendingVerification) {
      // Read-only: just show the receipt
      showDialog(
        context: context,
        builder: (_) => OrderReceiptDialog(
          order: order,
          onApprove: null,
          onReject: null,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (_) => OrderReceiptDialog(
        order: order,
        onApprove: () async {
          final ok =
              await ref.read(adminOrdersProvider.notifier).approve(order.id);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(ok ? 'تم قبول الطلب وتفعيل الكتاب للطالب' : 'فشل قبول الطلب'),
                backgroundColor: ok ? Colors.green : Colors.red,
              ),
            );
          }
        },
        onReject: () {
          showDialog(
            context: context,
            builder: (_) => RejectOrderDialog(
              orderId: order.id,
              onConfirm: (reason) async {
                final ok = await ref
                    .read(adminOrdersProvider.notifier)
                    .reject(order.id, reason);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'تم رفض الطلب بنجاح' : 'فشل رفض الطلب'),
                      backgroundColor: ok ? Colors.orange : Colors.red,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminOrdersProvider);

    // Apply search filter locally
    final filtered = state.orders.where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return o.bookTitle.toLowerCase().contains(q) ||
          o.studentName.toLowerCase().contains(q) ||
          o.studentEmail.toLowerCase().contains(q) ||
          (o.bankReferenceNumber?.toLowerCase().contains(q) ?? false);
    }).toList();

    // Count per status for badge display
    final pendingCount = state.orders
        .where((o) => o.status == AdminOrderStatus.pendingVerification)
        .length;

    return Scaffold(
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث في الطلبات (الطالب، الكتاب، رقم المرجع...)',
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),

          // ── Filter Tabs ─────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: _filterLabels[0]),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_filterLabels[1]),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(text: _filterLabels[2]),
              Tab(text: _filterLabels[3]),
            ],
          ),

          const Divider(height: 1),

          // ── Orders List ─────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                final status = _filterValues[_tabController.index];
                return ref.read(adminOrdersProvider.notifier).load(
                      status: status,
                      clearFilter: status == null,
                    );
              },
              child: state.isLoading && state.orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.orders.isEmpty
                      ? _buildError(state.error!)
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) =>
                                  _buildOrderCard(ctx, filtered[i], theme),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, AdminOrder order, ThemeData theme) {
    final statusColor = _statusColor(order.status);
    final statusIcon = _statusIcon(order.status);
    final d = order.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final isPending = order.status == AdminOrderStatus.pendingVerification;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPending
            ? BorderSide(color: Colors.orange.shade300, width: 1.5)
            : BorderSide.none,
      ),
      elevation: isPending ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReceiptDialog(context, order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: status badge + order id + date ────────────────────
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          order.statusText.isNotEmpty
                              ? order.statusText
                              : _statusLabel(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${order.id}',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Book title ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.bookTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.amount.toStringAsFixed(3)} ${order.currency}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── Student info ────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.studentName,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              if (order.bankReferenceNumber != null &&
                  order.bankReferenceNumber!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'مرجع التحويل: ${order.bankReferenceNumber}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Action buttons for pending orders ───────────────────────────
              if (isPending) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('فحص إشعار التحويل'),
                  onPressed: () => _showReceiptDialog(context, order),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('قبول'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد القبول'),
                              content: Text(
                                  'هل تريد قبول طلب "${order.bookTitle}" للطالب ${order.studentName}؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('إلغاء'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('قبول'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final ok = await ref
                                .read(adminOrdersProvider.notifier)
                                .approve(order.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'تم قبول الطلب وتفعيل الكتاب'
                                      : 'فشل قبول الطلب'),
                                  backgroundColor:
                                      ok ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('رفض'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => RejectOrderDialog(
                              orderId: order.id,
                              onConfirm: (reason) async {
                                final ok = await ref
                                    .read(adminOrdersProvider.notifier)
                                    .reject(order.id, reason);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'تم رفض الطلب بنجاح'
                                          : 'فشل رفض الطلب'),
                                      backgroundColor:
                                          ok ? Colors.orange : Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],

              // ── Rejection reason for rejected orders ────────────────────────
              if (order.status == AdminOrderStatus.rejected &&
                  order.rejectionReason != null &&
                  order.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'سبب الرفض: ${order.rejectionReason}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(AdminOrderStatus status) {
    switch (status) {
      case AdminOrderStatus.pendingVerification:
        return 'معلق';
      case AdminOrderStatus.approved:
        return 'مقبول';
      case AdminOrderStatus.rejected:
        return 'مرفوض';
      case AdminOrderStatus.cancelled:
        return 'ملغي';
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج مطابقة للبحث'
                : 'لا توجد طلبات في هذه الفئة',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
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
                  : 'حدث خطأ أثناء تحميل الطلبات',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              isAuthError
                  ? 'يرجى تسجيل الدخول مجدداً بحساب المشرف لمتابعة إدارة الطلبات.'
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
                  if (mounted) context.go('/login');
                },
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: () =>
                    ref.read(adminOrdersProvider.notifier).load(clearFilter: true),
              ),
          ],
        ),
      ),
    );
  }
}
