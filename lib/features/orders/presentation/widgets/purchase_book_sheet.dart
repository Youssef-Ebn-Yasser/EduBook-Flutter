import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../books/data/book_models.dart';
import '../../data/order_models.dart';
import '../../data/orders_repository.dart';
import '../../providers/orders_provider.dart';

class PurchaseBookSheet extends ConsumerStatefulWidget {
  final BookDetail book;

  const PurchaseBookSheet({super.key, required this.book});

  static Future<void> show(BuildContext context, BookDetail book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PurchaseBookSheet(book: book),
    );
  }

  @override
  ConsumerState<PurchaseBookSheet> createState() => _PurchaseBookSheetState();
}

class _PurchaseBookSheetState extends ConsumerState<PurchaseBookSheet> {
  String? _receiptImagePath;
  String? _receiptFileName;
  int? _receiptFileSize;
  final _refNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  StudentOrder? _createdOrder;

  @override
  void dispose() {
    _refNoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    setState(() => _errorMessage = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        dialogTitle: 'اختر صورة إشعار التحويل البنكي',
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final f = File(file.path!);
          final size = await f.length();
          if (size > 5 * 1024 * 1024) {
            setState(() {
              _errorMessage = 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت';
            });
            return;
          }
          setState(() {
            _receiptImagePath = file.path;
            _receiptFileName = file.name;
            _receiptFileSize = size;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر اختيار الصورة: ${e.toString()}';
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label بنجاح'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_receiptImagePath == null) {
      setState(() {
        _errorMessage = 'يرجى إرفاق صورة واضحة لإشعار التحويل البنكي';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(ordersRepositoryProvider);
    final res = await repo.createOrder(
      CreateBankOrderInput(
        bookId: widget.book.id,
        receiptImagePath: _receiptImagePath!,
        bankReferenceNumber: _refNoCtrl.text.trim().isEmpty ? null : _refNoCtrl.text.trim(),
        studentNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      // Refresh user's orders list
      ref.read(myOrdersProvider.notifier).fetchOrders();
      setState(() {
        _isSubmitting = false;
        _createdOrder = res.data;
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'فشل إرسال طلب الشراء. يرجى التأكد من البيانات والمحاولة مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankAsync = ref.watch(bankDetailsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──────────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),

              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.account_balance_rounded,
                          color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _createdOrder != null
                            ? 'تم إرسال الطلب بنجاح'
                            : 'شراء الكتاب والتحويل البنكي',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Scrollable Body ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _createdOrder != null
                      ? _buildSuccessView(context, theme, _createdOrder!)
                      : _buildOrderForm(context, theme, bankAsync),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderForm(
    BuildContext context,
    ThemeData theme,
    AsyncValue<BankDetails> bankAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Book Summary Card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: widget.book.coverUrl != null
                    ? Image.network(
                        widget.book.coverUrl!,
                        width: 52,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bookPlaceholder(theme),
                      )
                    : _bookPlaceholder(theme),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.book.categoryName} • ${widget.book.gradeLevelName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'المبلغ المطلوب: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${widget.book.price.toStringAsFixed(3)} ر.ع.',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 2. Bank Muscat Transfer Output (from endpoint) ─────────────────
        Text(
          'بيانات التحويل الرسمي (بنك مسقط)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        bankAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(height: 8),
                  Text('جارٍ جلب تفاصيل الحساب البنكي...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تعذر تحميل بيانات البنك تلقائياً',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('إعادة المحاولة'),
                  onPressed: () => ref.invalidate(bankDetailsProvider),
                ),
              ],
            ),
          ),
          data: (bank) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Name & Icon
                Row(
                  children: [
                    Icon(Icons.account_balance, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        BankDetails.cleanBankName(bank.bankName),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),

                // Account Name
                _bankDetailRow(
                  theme: theme,
                  icon: Icons.person_outline,
                  label: 'اسم الحساب:',
                  value: bank.accountName,
                  onCopy: () => _copyToClipboard(bank.accountName, 'اسم الحساب'),
                ),
                const SizedBox(height: 10),

                // Account Number
                _bankDetailRow(
                  theme: theme,
                  icon: Icons.numbers,
                  label: 'رقم الحساب:',
                  value: bank.accountNumber,
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(bank.accountNumber, 'رقم الحساب'),
                ),
                const SizedBox(height: 10),

                // Phone / Mobile Pay Number
                if (bank.phoneNumber.isNotEmpty) ...[
                  _bankDetailRow(
                    theme: theme,
                    icon: Icons.phone_android_outlined,
                    label: 'التحويل السريع (الهاتف):',
                    value: bank.phoneNumber,
                    isHighlight: true,
                    onCopy: () => _copyToClipboard(bank.phoneNumber, 'رقم الهاتف'),
                  ),
                  const SizedBox(height: 10),
                ],

                // Instructions Box (omitted if empty or containing nonsense words)
                if (bank.transferInstructions.isNotEmpty &&
                    !BankDetails.hasNonsense(bank.transferInstructions)) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bank.transferInstructions,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
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
        const SizedBox(height: 20),

        // ── 3. Receipt Upload Section ─────────────────────────────────────
        Text(
          'إرفاق إثبات الدفع (صورة الإشعار)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'قم بالتحويل عبر تطبيق البنك وارفع صورة واضحة لإشعار التحويل البنكي:',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),

        // Image picker card
        InkWell(
          onTap: _isSubmitting ? null : _pickReceiptImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _receiptImagePath != null
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _receiptImagePath != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: _receiptImagePath != null ? 1.5 : 1,
              ),
            ),
            child: _receiptImagePath != null
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_receiptImagePath!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _receiptFileName ?? 'إشعار التحويل',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (_receiptFileSize != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${(_receiptFileSize! / (1024 * 1024)).toStringAsFixed(2)} ميجابايت',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'اضغط لتغيير الصورة',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'حذف',
                        onPressed: () {
                          setState(() {
                            _receiptImagePath = null;
                            _receiptFileName = null;
                            _receiptFileSize = null;
                          });
                        },
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط لاختيار صورة إشعار التحويل',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يدعم صيغ JPG و PNG و WebP (بحد أقصى 5 ميجابايت)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Optional Reference Number
        TextField(
          controller: _refNoCtrl,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            labelText: 'الرقم المرجعي للتحويل (اختياري)',
            hintText: 'مثال: REF12345678',
            prefixIcon: const Icon(Icons.receipt_long_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Optional Notes
        TextField(
          controller: _notesCtrl,
          enabled: !_isSubmitting,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'ملاحظات إضافية (اختياري)',
            hintText: 'أي تفاصيل تساعد في التحقق من الإيصال...',
            prefixIcon: const Icon(Icons.edit_note_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Error message if any
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Submit Button ─────────────────────────────────────────────────
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submitOrder,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(
            _isSubmitting ? 'جارٍ إرسال الإشعار...' : 'تأكيد وإرسال إشعار التحويل',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, ThemeData theme, StudentOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
        ),
        const SizedBox(height: 16),
        const Text(
          'تم استلام طلب التحويل بنجاح!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'رقم الطلب: #${order.id}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('حالة الطلب:', style: TextStyle(fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.statusText,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              const Text(
                'طلبك الآن قيد المراجعة والتحقق من قِبل إدارة المنصة. سيتم تفعيل الكتاب تلقائياً في مكتبتك فور اعتماد الإيصال.',
                style: TextStyle(fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إغلاق'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('متابعة طلباتي'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/orders');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bankDetailRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'نسخ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookPlaceholder(ThemeData theme) {
    return Container(
      width: 52,
      height: 70,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 24),
      ),
    );
  }
}
