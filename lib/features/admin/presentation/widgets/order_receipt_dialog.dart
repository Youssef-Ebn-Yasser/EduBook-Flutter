import 'package:flutter/material.dart';
import '../../data/admin_models.dart';

class OrderReceiptDialog extends StatelessWidget {
  final AdminOrder order;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const OrderReceiptDialog({
    super.key,
    required this.order,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = order.status == AdminOrderStatus.pendingVerification;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'إشعار تحويل بنك مسقط #${order.id}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // ── Order metadata ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.person_outline, 'الطالب:',
                        '${order.studentName} (${order.studentEmail})'),
                    const SizedBox(height: 6),
                    _infoRow(Icons.book_outlined, 'الكتاب:', order.bookTitle),
                    const SizedBox(height: 6),
                    _infoRow(
                        Icons.payments_outlined,
                        'المبلغ المحول:',
                        '${order.amount.toStringAsFixed(3)} ${order.currency}',
                        isBold: true),
                    if (order.bankReferenceNumber != null &&
                        order.bankReferenceNumber!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _infoRow(Icons.confirmation_number_outlined,
                          'الرقم المرجعي للبنك:', order.bankReferenceNumber!),
                    ],
                    if (order.studentNotes != null &&
                        order.studentNotes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _infoRow(Icons.notes, 'ملاحظات الطالب:',
                          order.studentNotes!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Receipt Image ────────────────────────────────────────────
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black12,
                    child: order.receiptUrl.isNotEmpty
                        ? InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              order.receiptUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (ctx, _, __) {
                                return const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_outlined,
                                          size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('تعذر تحميل صورة الإشعار',
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Text('لا توجد صورة إشعار مرفقة'),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Actions ──────────────────────────────────────────────────
              if (isPending && onApprove != null && onReject != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('رفض الطلب'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onReject!();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('قبول وتفعيل'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onApprove!();
                        },
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (order.status == AdminOrderStatus.approved
                              ? Colors.green
                              : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'حالة الطلب: ${order.statusText}',
                      style: TextStyle(
                        color: order.status == AdminOrderStatus.approved
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String val,
      {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            val,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
