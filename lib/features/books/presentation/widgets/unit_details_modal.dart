import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/book_models.dart';

class UnitDetailsModal extends StatelessWidget {
  final BookUnit unit;
  final int? bookId;
  final Future<void> Function()? onDownloadPdf;

  const UnitDetailsModal({
    super.key,
    required this.unit,
    this.bookId,
    this.onDownloadPdf,
  });

  static Future<void> show(
    BuildContext context, {
    required BookUnit unit,
    int? bookId,
    Future<void> Function()? onDownloadPdf,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UnitDetailsModal(
        unit: unit,
        bookId: bookId,
        onDownloadPdf: onDownloadPdf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      '${unit.order}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'معرف الدرس في النظام: #${unit.id} • الترتيب: ${unit.order}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Badges summary
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: unit.isFreeSample
                            ? 'عينة مجانية متاحة للجميع'
                            : 'محتوى كامل للمشتركين',
                        icon: unit.isFreeSample
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        color: unit.isFreeSample ? Colors.green : Colors.indigo,
                      ),
                      if (unit.hasYoutube)
                        const _StatusChip(
                          label: 'يوجد شرح فيديو',
                          icon: Icons.play_circle_fill_rounded,
                          color: Colors.red,
                        ),
                      if (unit.hasPdfFile)
                        _StatusChip(
                          label: unit.fileSizeFormatted.isNotEmpty
                              ? 'ملف PDF مرفق (${unit.fileSizeFormatted})'
                              : 'ملف PDF مرفق',
                          icon: Icons.picture_as_pdf_rounded,
                          color: Colors.deepOrange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description card
                  _buildSectionHeader(
                    theme,
                    title: 'وصف ومحتوى الدرس',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      unit.hasDescription
                          ? unit.description!
                          : 'لا يوجد وصف نصي مدخل لهذا الفصل من قبل الناشر.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: unit.hasDescription
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                        fontStyle: unit.hasDescription
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // YouTube Video Section
                  _buildSectionHeader(
                    theme,
                    title: 'فيديو شرح الدرس (يوتيوب)',
                    icon: Icons.video_collection_outlined,
                  ),
                  const SizedBox(height: 8),
                  if (unit.hasYoutube)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (unit.youtubeThumbnailUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.network(
                                      unit.youtubeThumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade900,
                                        child: const Center(
                                          child: Icon(
                                            Icons.video_library_rounded,
                                            size: 40,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _openUrl(context, unit.youtubeUrl!),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade700
                                            .withValues(alpha: 0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.link, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  unit.youtubeUrl!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                tooltip: 'نسخ الرابط',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: unit.youtubeUrl!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ رابط الفيديو'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.play_circle_fill_rounded,
                                  size: 18),
                              label: const Text(
                                'تشغيل ومتابعة الشرح على يوتيوب',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () =>
                                  _openUrl(context, unit.youtubeUrl!),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.videocam_off_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Text(
                            'لم يتم ربط فيديو شرح يوتيوب لهذه الوحدة بعد.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // PDF File Section
                  _buildSectionHeader(
                    theme,
                    title: 'ملف الـ PDF المرفق للدرس',
                    icon: Icons.attach_file_rounded,
                  ),
                  const SizedBox(height: 8),
                  if (unit.hasPdfFile)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.deepOrange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Colors.deepOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      unit.pdfFileName ?? 'ملف الدرس (PDF)',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'الحجم: ${unit.fileSizeFormatted.isNotEmpty ? unit.fileSizeFormatted : "غير محدد"}${unit.pdfFileSizeBytes != null ? " (${unit.pdfFileSizeBytes} بايت)" : ""}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (unit.formattedUploadDate.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 6),
                                Text(
                                  'تاريخ الرفع: ${unit.formattedUploadDate}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (unit.pdfStreamUrl != null &&
                              unit.pdfStreamUrl!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.stream_rounded,
                                    size: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'مسار البث: ${unit.pdfStreamUrl}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (onDownloadPdf != null)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepOrange.shade800,
                                  side: BorderSide(
                                    color: Colors.deepOrange.shade400,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text(
                                  'تحميل / فتح ملف الدرس PDF',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: onDownloadPdf,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.file_copy_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Text(
                            'لا يوجد ملف PDF مخصص لهذا الفصل بعد.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Metadata Table
                  _buildSectionHeader(
                    theme,
                    title: 'كافة البيانات التقنية من السيرفر',
                    icon: Icons.data_object_rounded,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        _MetaRow(label: 'معرف الوحدة (Id)', value: '${unit.id}'),
                        const Divider(height: 1),
                        _MetaRow(
                            label: 'الترتيب في الفهرس (Order)',
                            value: '${unit.order}'),
                        const Divider(height: 1),
                        _MetaRow(
                            label: 'عنوان الوحدة (Title)', value: unit.title),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'عينة مجانية (IsFreeSample)',
                          value: unit.isFreeSample ? 'نعم (True)' : 'لا (False)',
                          valueColor: unit.isFreeSample
                              ? Colors.green
                              : Colors.grey.shade700,
                        ),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'توفر ملف مرفق (HasPdfFile)',
                          value: unit.hasPdfFile ? 'نعم (True)' : 'لا (False)',
                          valueColor: unit.hasPdfFile
                              ? Colors.deepOrange
                              : Colors.grey.shade700,
                        ),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'اسم الملف (PdfFileName)',
                          value: unit.pdfFileName ?? 'غير محدد (null)',
                        ),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'الحجم بالبايت (PdfFileSizeBytes)',
                          value: unit.pdfFileSizeBytes != null
                              ? '${unit.pdfFileSizeBytes} بايت (${unit.fileSizeFormatted})'
                              : '0 (null)',
                        ),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'تاريخ الرفع (PdfUploadedAt)',
                          value: unit.pdfUploadedAt != null
                              ? unit.pdfUploadedAt!.toIso8601String()
                              : 'غير متوفر (null)',
                        ),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'رابط البث (PdfStreamUrl)',
                          value: unit.pdfStreamUrl ?? 'غير متوفر (null)',
                        ),
                        const Divider(height: 1),
                        _MetaRow(
                          label: 'رابط اليوتيوب (YoutubeUrl)',
                          value: unit.youtubeUrl ?? 'غير متوفر (null)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Raw JSON Inspector
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(Icons.code_rounded,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'عرض استجابة الـ JSON الخام من الباك إند',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'JSON Response Payload',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      final jsonStr = const JsonEncoder.withIndent('  ')
                                          .convert(unit.rawJson);
                                      Clipboard.setData(
                                          ClipboardData(text: jsonStr));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('تم نسخ كود الـ JSON بنجاح'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy,
                                            size: 14, color: Colors.amber),
                                        SizedBox(width: 4),
                                        Text(
                                          'نسخ',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 16),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: SelectableText(
                                  const JsonEncoder.withIndent('  ')
                                      .convert(unit.rawJson),
                                  style: const TextStyle(
                                    color: Color(0xFF4EC9B0),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الرابط'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: SelectableText(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 11,
                fontFamily: value.startsWith('http') || value.contains('{')
                    ? 'monospace'
                    : null,
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
