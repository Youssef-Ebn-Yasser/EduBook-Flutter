import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/order_models.dart';
import '../providers/orders_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  int _selectedFilter = -1; // -1: All, 0: Pending, 1: Approved, 2: Rejected

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(myOrdersProvider);

    final filteredOrders = _selectedFilter == -1
        ? state.orders
        : state.orders.where((o) => o.status.value == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('طلبات التحويل البنكي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () => ref.read(myOrdersProvider.notifier).fetchOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('الكل (${state.orders.length})', -1),
                const SizedBox(width: 8),
                _filterChip(
                  'معلق (${state.orders.where((o) => o.status == StudentOrderStatus.pendingVerification).length})',
                  0,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'مقبول (${state.orders.where((o) => o.status == StudentOrderStatus.approved).length})',
                  1,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'مرفوض (${state.orders.where((o) => o.status == StudentOrderStatus.rejected).length})',
                  2,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Orders List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'تعذر جلب طلبات التحويل',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.error!,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.icon(
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('إعادة المحاولة'),
                                    onPressed: () =>
                                        ref.read(myOrdersProvider.notifier).fetchOrders(),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                                    label: const Text('الكتب'),
                                    onPressed: () => context.push('/books'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedFilter == -1
                                      ? 'لا توجد طلبات شراء بعد'
                                      : 'لا توجد طلبات في هذا القسم',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  icon: const Icon(Icons.menu_book),
                                  label: const Text('تصفح الكتب للشراء'),
                                  onPressed: () => context.push('/books'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(myOrdersProvider.notifier).fetchOrders(),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 720),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredOrders.length,
                                  itemBuilder: (ctx, i) =>
                                      _StudentOrderCard(order: filteredOrders[i]),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int value, {Color? color}) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (color ?? theme.colorScheme.primary).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (color ?? theme.colorScheme.primary) : null,
      ),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}

class _StudentOrderCard extends StatelessWidget {
  final StudentOrder order;

  const _StudentOrderCard({required this.order});

  void _showReceiptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('إشعار التحويل #${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(
                      order.receiptUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('تعذر تحميل صورة الإشعار'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(order.status.icon, size: 14, color: order.status.color),
                      const SizedBox(width: 4),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          color: order.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Book Details Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: order.bookCoverUrl != null
                      ? Image.network(
                          order.bookCoverUrl!,
                          width: 45,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 45,
                            height: 60,
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.menu_book, size: 20),
                          ),
                        )
                      : Container(
                          width: 45,
                          height: 60,
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.menu_book, size: 20),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.bookTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المبلغ: ${order.amount.toStringAsFixed(3)} ${order.currency}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (order.bankReferenceNumber != null &&
                          order.bankReferenceNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'المرجع: ${order.bankReferenceNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // If Rejected: show rejection explanation
            if (order.status == StudentOrderStatus.rejected &&
                order.rejectionReason != null &&
                order.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${order.rejectionReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Footer: Date + View Receipt Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.createdAt.year}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (order.receiptUrl.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: const Text('عرض الإشعار', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showReceiptDialog(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
