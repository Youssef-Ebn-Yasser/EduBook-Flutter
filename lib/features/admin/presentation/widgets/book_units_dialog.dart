import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../books/data/book_models.dart';
import '../../../books/presentation/widgets/unit_details_modal.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';

class BookUnitsDialog extends ConsumerStatefulWidget {
  final BookListItem book;

  const BookUnitsDialog({super.key, required this.book});

  static Future<void> show(BuildContext context, BookListItem book) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookUnitsDialog(book: book),
    );
  }

  @override
  ConsumerState<BookUnitsDialog> createState() => _BookUnitsDialogState();
}

class _BookUnitsDialogState extends ConsumerState<BookUnitsDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<BookUnit> _units = [];
  int? _uploadingUnitId;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getBookUnits(widget.book.id);
      if (mounted) {
        final list = res.data ?? [];
        list.sort((a, b) => a.order.compareTo(b.order));
        setState(() {
          _isLoading = false;
          _units = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل فصول الكتاب: $e';
        });
      }
    }
  }

  Future<void> _openUnitForm({BookUnit? unitToEdit}) async {
    final titleCtrl = TextEditingController(text: unitToEdit?.title ?? '');
    final descCtrl = TextEditingController(text: unitToEdit?.description ?? '');
    final ytCtrl = TextEditingController(text: unitToEdit?.youtubeUrl ?? '');
    final nextOrder = unitToEdit != null
        ? unitToEdit.order
        : (_units.isEmpty
            ? 1
            : (_units
                    .map((u) => u.order)
                    .fold<int>(0, (max, o) => o > max ? o : max) +
                1));
    bool isFreeSample = unitToEdit?.isFreeSample ?? false;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            unitToEdit == null ? 'إضافة فصل / درس جديد' : 'تعديل بيانات الفصل',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الفصل / الدرس *',
                      hintText: 'مثال: الوحدة الأولى: مقدمة في الجبر',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'الرجاء إدخال عنوان الفصل'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Fixed Order (Unchangeable on mobile screen) ───────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(ctx)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ترتيب الفصل في الكتاب (ثابت)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'الفصل رقم #$nextOrder',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ثابت تلقائياً',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(ctx).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: ytCtrl,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'رابط شرح يوتيوب (اختياري)',
                      hintText:
                          'https://youtube.com/watch?v=... أو https://youtu.be/...',
                      prefixIcon:
                          Icon(Icons.play_circle_fill, color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'وصف أو ملخص الفصل (اختياري)',
                      hintText: 'أدخل ملخصاً أو أهداف الفصل باللغة العربية...',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('عينة مجانية'),
                    subtitle: const Text(
                      'إتاحة هذا الفصل للمعاينة المجانية بدون اشتراك',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: isFreeSample,
                    onChanged: (v) => setDialogState(() => isFreeSample = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx, true);
              },
              child: Text(unitToEdit == null ? 'إضافة' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        final req = BookUnitRequest(
          title: titleCtrl.text.trim(),
          order: nextOrder,
          youtubeUrl: ytCtrl.text.trim().isNotEmpty ? ytCtrl.text.trim() : null,
          description:
              descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          isFreeSample: isFreeSample,
        );

        if (unitToEdit == null) {
          await repo.addBookUnit(widget.book.id, req);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت إضافة الفصل بنجاح')),
            );
          }
        } else {
          await repo.updateBookUnit(widget.book.id, unitToEdit.id, req);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الفصل بنجاح')),
            );
          }
        }
        await _fetchUnits();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadPdf(BookUnit unit) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'اختر ملف PDF للدرس: ${unit.title}',
    );

    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    setState(() => _uploadingUnitId = unit.id);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.uploadUnitPdfFile(widget.book.id, unit.id, filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'تم رفع ملف الدرس بنجاح')),
        );
      }
      await _fetchUnits();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع ملف الدرس: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingUnitId = null);
      }
    }
  }

  Future<void> _deletePdf(BookUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الملف'),
        content: Text('هل أنت متأكد من حذف ملف الـ PDF الخاص بـ "${unit.title}"؟'),
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

    if (confirmed == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        await repo.deleteUnitPdfFile(widget.book.id, unit.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف ملف الدرس بنجاح')),
          );
        }
        await _fetchUnits();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حذف الملف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteUnit(BookUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الفصل'),
        content: Text('هل أنت متأكد من حذف الفصل "${unit.title}" بالكامل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الفصل'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        await repo.deleteBookUnit(widget.book.id, unit.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الفصل بنجاح')),
          );
        }
        await _fetchUnits();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حذف الفصل: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إدارة فصول ودروس الكتاب',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // ── Actions bar ─────────────────────────────────────────
            Row(
              children: [
                Text(
                  'عدد الفصول: ${_units.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openUnitForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة فصل / درس'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 40),
                              const SizedBox(height: 8),
                              Text(_errorMessage!),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _fetchUnits,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : _units.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.collections_bookmark_outlined,
                                      size: 52, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'لا توجد فصول مضافة لهذا الكتاب بعد',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'اضغط على "إضافة فصل / درس" لإضافة الوحدات وروابط الشرح وملفات PDF',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _units.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final unit = _units[index];
                                final isUploadingThis = _uploadingUnitId == unit.id;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: Order, Title, Sample Badge, Actions
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 13,
                                            backgroundColor: theme.colorScheme.primary
                                                .withValues(alpha: 0.15),
                                            child: Text(
                                              '${unit.order}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              unit.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (unit.isFreeSample) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'عينة مجانية',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.info_outline_rounded,
                                                size: 18, color: Colors.teal),
                                            tooltip: 'عرض تفاصيل ومحتوى الفصل الكامل',
                                            onPressed: () => UnitDetailsModal.show(
                                              context,
                                              unit: unit,
                                              bookId: widget.book.id,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined,
                                                size: 18, color: Colors.blue),
                                            tooltip: 'تعديل بيانات الفصل',
                                            onPressed: () => _openUnitForm(unitToEdit: unit),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                size: 18, color: Colors.red),
                                            tooltip: 'حذف الفصل',
                                            onPressed: () => _deleteUnit(unit),
                                          ),
                                        ],
                                      ),

                                      // Description
                                      if (unit.description != null &&
                                          unit.description!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 34),
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

                                      const SizedBox(height: 10),

                                      // Row 2: YouTube link & PDF file controls
                                      Padding(
                                        padding: const EdgeInsets.only(right: 34),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            // YouTube
                                            if (unit.hasYoutube)
                                              ActionChip(
                                                avatar: const Icon(Icons.play_circle_fill,
                                                    color: Colors.red, size: 16),
                                                label: const Text('شرح يوتيوب',
                                                    style: TextStyle(fontSize: 11)),
                                                onPressed: () async {
                                                  final uri = Uri.tryParse(unit.youtubeUrl!.trim());
                                                  if (uri != null && await canLaunchUrl(uri)) {
                                                    await launchUrl(uri,
                                                        mode: LaunchMode.externalApplication);
                                                  }
                                                },
                                              ),

                                            // PDF Status & Upload
                                            if (isUploadingThis) ...[
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text('جاري الرفع...', style: TextStyle(fontSize: 11)),
                                            ] else if (unit.hasPdfFile) ...[
                                              Chip(
                                                avatar: const Icon(Icons.picture_as_pdf,
                                                    color: Colors.deepOrange, size: 16),
                                                label: Text(
                                                  '${unit.pdfFileName ?? "ملف الدرس"}${unit.fileSizeFormatted.isNotEmpty ? " (${unit.fileSizeFormatted})" : ""}',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                deleteIcon: const Icon(Icons.delete_forever, size: 16),
                                                onDeleted: () => _deletePdf(unit),
                                              ),
                                              TextButton.icon(
                                                icon: const Icon(Icons.upload_file, size: 16),
                                                label: const Text('استبدال PDF',
                                                    style: TextStyle(fontSize: 11)),
                                                onPressed: () => _pickAndUploadPdf(unit),
                                              ),
                                            ] else ...[
                                              OutlinedButton.icon(
                                                icon: const Icon(Icons.upload_file, size: 15),
                                                label: const Text('رفع ملف PDF للدرس',
                                                    style: TextStyle(fontSize: 11)),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 4),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                onPressed: () => _pickAndUploadPdf(unit),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
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
