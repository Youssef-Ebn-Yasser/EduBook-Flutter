import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../books/data/book_models.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../providers/admin_provider.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  final BookListItem? book;
  final Function(CreateBookRequest)? onCreate;
  final Function(int id, UpdateBookRequest)? onUpdate;

  const BookFormDialog({
    super.key,
    this.book,
    this.onCreate,
    this.onUpdate,
  });

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _originalPriceCtrl;
  late final TextEditingController _academicYearCtrl;
  late final TextEditingController _pageCountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _validityCtrl;
  late final TextEditingController _versionCtrl;

  int? _selectedGradeId;
  int? _selectedCatId;
  late String _selectedSemester;
  late bool _isOfficialCurriculum;
  late bool _isTaxInclusive;
  late bool _isActive;

  // File pickers
  String? _coverFilePath;
  String? _pdfFilePath;
  String? _pdfFileName;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _isbnCtrl = TextEditingController(text: b?.isbn ?? '');
    _priceCtrl =
        TextEditingController(text: b != null ? b.price.toString() : '5.000');
    _originalPriceCtrl = TextEditingController(
        text: (b?.originalPrice != null && b!.originalPrice! > 0)
            ? b.originalPrice.toString()
            : '');
    _academicYearCtrl = TextEditingController(text: b?.academicYear ?? '');
    _pageCountCtrl = TextEditingController(
        text: (b?.pageCount != null && b!.pageCount > 0)
            ? b.pageCount.toString()
            : '');
    _descCtrl = TextEditingController();
    _validityCtrl =
        TextEditingController(text: (b?.validityDays ?? 365).toString());
    _versionCtrl = TextEditingController(text: '1.0');
    _selectedSemester = b?.semester ?? 'FirstTerm';
    _isOfficialCurriculum = b?.isOfficialCurriculum ?? true;
    _isTaxInclusive = b?.isTaxInclusive ?? true;
    _isActive = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _isbnCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _academicYearCtrl.dispose();
    _pageCountCtrl.dispose();
    _descCtrl.dispose();
    _validityCtrl.dispose();
    _versionCtrl.dispose();
    super.dispose();
  }

  // ── File pickers ─────────────────────────────────────────────────────────

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      dialogTitle: 'اختر صورة غلاف الكتاب',
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _coverFilePath = result.files.single.path);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'اختر ملف PDF للكتاب',
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFilePath = result.files.single.path;
        _pdfFileName = result.files.single.name;
      });
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGradeId == null) {
      _showError('الرجاء اختيار الصف الدراسي');
      return;
    }
    if (_selectedCatId == null) {
      _showError('الرجاء اختيار القسم');
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final originalPrice = _originalPriceCtrl.text.trim().isNotEmpty
        ? double.tryParse(_originalPriceCtrl.text.trim())
        : null;
    final academicYear = _academicYearCtrl.text.trim().isNotEmpty
        ? _academicYearCtrl.text.trim()
        : null;
    final pageCount = int.tryParse(_pageCountCtrl.text.trim()) ?? 0;
    final validity = int.tryParse(_validityCtrl.text.trim()) ?? 365;
    final version = _versionCtrl.text.trim().isEmpty
        ? '1.0'
        : _versionCtrl.text.trim();

    setState(() => _isUploading = true);

    final repo = ref.read(adminRepositoryProvider);

    try {
      if (widget.book == null) {
        // ── Create new book ──────────────────────────────────────────────
        final req = CreateBookRequest(
          title: _titleCtrl.text.trim(),
          isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          price: price,
          originalPrice: originalPrice,
          validityDays: validity,
          gradeLevelId: _selectedGradeId!,
          categoryId: _selectedCatId!,
          semester: _selectedSemester,
          academicYear: academicYear,
          pageCount: pageCount,
          isOfficialCurriculum: _isOfficialCurriculum,
          isTaxInclusive: _isTaxInclusive,
        );

        // Call parent callback so the notifier creates the book and gets its ID
        int? newBookId;
        final originalOnCreate = widget.onCreate;
        if (originalOnCreate != null) {
          // We need the book ID after creation to upload files.
          // Directly call repository so we can get the response.
          final createRes = await repo.createBook(req);
          if (createRes.data != null) {
            newBookId = createRes.data!.id;
            // Notify notifier to reload
            await ref.read(adminBooksProvider.notifier).load();
          } else {
            _showError(createRes.message.isNotEmpty
                ? createRes.message
                : 'فشل إنشاء الكتاب');
            setState(() => _isUploading = false);
            return;
          }
        }

        // Upload cover if selected
        if (newBookId != null && _coverFilePath != null) {
          await repo.uploadBookCover(newBookId, _coverFilePath!);
        }

        // Upload PDF if selected
        if (newBookId != null && _pdfFilePath != null) {
          await repo.uploadBookFile(newBookId, _pdfFilePath!, version);
        }

        if (newBookId != null) {
          await ref.read(adminBooksProvider.notifier).load();
        }
      } else {
        // ── Update existing book ──────────────────────────────────────────
        final req = UpdateBookRequest(
          title: _titleCtrl.text.trim(),
          isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          price: price,
          originalPrice: originalPrice,
          validityDays: validity,
          gradeLevelId: _selectedGradeId!,
          categoryId: _selectedCatId!,
          isActive: _isActive,
          semester: _selectedSemester,
          academicYear: academicYear,
          pageCount: pageCount,
          isOfficialCurriculum: _isOfficialCurriculum,
          isTaxInclusive: _isTaxInclusive,
        );
        widget.onUpdate?.call(widget.book!.id, req);

        // Upload cover if a new one selected
        if (_coverFilePath != null) {
          await repo.uploadBookCover(widget.book!.id, _coverFilePath!);
        }

        // Upload PDF if selected
        if (_pdfFilePath != null) {
          await repo.uploadBookFile(
              widget.book!.id, _pdfFilePath!, version);
        }

        await ref.read(adminBooksProvider.notifier).load();
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('حدث خطأ: ${e.toString()}');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.book != null;
    final theme = Theme.of(context);
    final categories = ref.watch(adminCategoriesProvider).categories;
    final grades = ref.watch(adminGradeLevelsProvider).gradeLevels;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 500;

    // Pre-select dropdowns
    if (_selectedCatId == null && categories.isNotEmpty) {
      _selectedCatId = isEditing
          ? (categories
                  .where((c) => c.name == widget.book!.categoryName)
                  .firstOrNull
                  ?.id ??
              categories.first.id)
          : categories.first.id;
    }
    if (_selectedGradeId == null && grades.isNotEmpty) {
      _selectedGradeId = isEditing
          ? (grades
                  .where((g) => g.name == widget.book!.gradeLevelName)
                  .firstOrNull
                  ?.id ??
              grades.first.id)
          : grades.first.id;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.add_circle_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing ? 'تعديل بيانات الكتاب' : 'إضافة كتاب جديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cover + basic info row
                        if (!isNarrow)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _coverPicker(theme),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _titleField(),
                                    const SizedBox(height: 12),
                                    _isbnField(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _coverPicker(theme),
                          const SizedBox(height: 12),
                          _titleField(),
                          const SizedBox(height: 12),
                          _isbnField(),
                        ],
                        const SizedBox(height: 14),

                        // Category & Grade (responsive wrap)
                        if (!isNarrow)
                          Row(
                            children: [
                              Expanded(child: _categoryDropdown(categories)),
                              const SizedBox(width: 12),
                              Expanded(child: _gradeDropdown(grades)),
                            ],
                          )
                        else ...[
                          _categoryDropdown(categories),
                          const SizedBox(height: 12),
                          _gradeDropdown(grades),
                        ],
                        const SizedBox(height: 14),

                        // Semester & Academic Year (responsive wrap)
                        if (!isNarrow)
                          Row(
                            children: [
                              Expanded(child: _semesterDropdown()),
                              const SizedBox(width: 12),
                              Expanded(child: _academicYearField()),
                            ],
                          )
                        else ...[
                          _semesterDropdown(),
                          const SizedBox(height: 12),
                          _academicYearField(),
                        ],
                        const SizedBox(height: 14),

                        // Price & Original Price (responsive wrap)
                        if (!isNarrow)
                          Row(
                            children: [
                              Expanded(child: _priceField()),
                              const SizedBox(width: 12),
                              Expanded(child: _originalPriceField()),
                            ],
                          )
                        else ...[
                          _priceField(),
                          const SizedBox(height: 12),
                          _originalPriceField(),
                        ],
                        const SizedBox(height: 14),

                        // Validity & Page Count (responsive wrap)
                        if (!isNarrow)
                          Row(
                            children: [
                              Expanded(child: _validityField()),
                              const SizedBox(width: 12),
                              Expanded(child: _pageCountField()),
                            ],
                          )
                        else ...[
                          _validityField(),
                          const SizedBox(height: 12),
                          _pageCountField(),
                        ],
                        const SizedBox(height: 14),

                        // Description
                        _descField(),
                        const SizedBox(height: 14),

                        // Curriculum & Tax switches
                        Card(
                          margin: EdgeInsets.zero,
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            title: const Text('منهج دراسي رسمي معتمد'),
                            subtitle: const Text(
                                'تحديد ما إذا كان الكتاب يتبع المنهاج الوزاري المعتمد'),
                            value: _isOfficialCurriculum,
                            onChanged: (val) =>
                                setState(() => _isOfficialCurriculum = val),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          margin: EdgeInsets.zero,
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            title: const Text('السعر شامل الضريبة'),
                            subtitle: const Text(
                                'تأكيد أن السعر المدخل شامل ضريبة القيمة المضافة'),
                            value: _isTaxInclusive,
                            onChanged: (val) =>
                                setState(() => _isTaxInclusive = val),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── PDF File Upload ─────────────────────────────
                        _sectionLabel('ملف الكتاب (PDF)', Icons.picture_as_pdf),
                        const SizedBox(height: 8),
                        if (!isNarrow)
                          Row(
                            children: [
                              Expanded(child: _pdfPickerButton()),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 130,
                                child: TextFormField(
                                  controller: _versionCtrl,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    labelText: 'الإصدار',
                                    hintText: '1.0',
                                    prefixIcon:
                                        Icon(Icons.tag_rounded, size: 18),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _pdfPickerButton(),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _versionCtrl,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'رقم الإصدار',
                              hintText: '1.0',
                              prefixIcon: Icon(Icons.tag_rounded, size: 18),
                              isDense: true,
                            ),
                          ),
                        ],

                        if (_pdfFileName != null) ...[
                          const SizedBox(height: 8),
                          _fileChip(
                            _pdfFileName!,
                            Icons.picture_as_pdf,
                            Colors.red,
                            () => setState(() {
                              _pdfFilePath = null;
                              _pdfFileName = null;
                            }),
                          ),
                        ],

                        // Active switch (edit mode)
                        if (isEditing) ...[
                          const SizedBox(height: 12),
                          Card(
                            margin: EdgeInsets.zero,
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              title: const Text('الكتاب متاح للبيع'),
                              subtitle: const Text(
                                  'إظهار الكتاب للطلاب في المتجر'),
                              value: _isActive,
                              onChanged: (val) =>
                                  setState(() => _isActive = val),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer Buttons ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _isUploading ? null : _submit,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isEditing ? Icons.save_rounded : Icons.add),
                        label: Text(
                          _isUploading
                              ? 'جاري الحفظ...'
                              : isEditing
                                  ? 'حفظ التعديلات'
                                  : 'إضافة الكتاب',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _coverPicker(ThemeData theme) {
    final hasFile = _coverFilePath != null;
    final hasCover = widget.book?.coverUrl != null;

    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: hasFile
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(_coverFilePath!), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(4),
                        child: const Text(
                          'تغيير الغلاف',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                )
              : hasCover
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.book!.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _coverPlaceholder(theme),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(4),
                            child: const Text(
                              'تغيير الغلاف',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _coverPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 6),
        Text(
          'صورة\nالغلاف',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _titleField() => TextFormField(
        controller: _titleCtrl,
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          labelText: 'عنوان الكتاب *',
          hintText: 'مثال: رياضيات الصف الأول',
          prefixIcon: Icon(Icons.book_outlined),
          isDense: true,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'عنوان الكتاب مطلوب';
          return null;
        },
      );

  Widget _isbnField() => TextFormField(
        controller: _isbnCtrl,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          labelText: 'رقم ISBN (اختياري)',
          hintText: '978-0-123456-47-2',
          prefixIcon: Icon(Icons.qr_code_2_outlined),
          isDense: true,
        ),
        keyboardType: TextInputType.text,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
        ],
      );

  Widget _categoryDropdown(List categories) => DropdownButtonFormField<int>(
        initialValue: _selectedCatId,
        decoration: const InputDecoration(
          labelText: 'القسم *',
          prefixIcon: Icon(Icons.category_outlined),
          isDense: true,
        ),
        isExpanded: true,
        items: categories
            .map((c) => DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                ))
            .toList(),
        onChanged: (val) => setState(() => _selectedCatId = val),
        validator: (v) => v == null ? 'اختر القسم' : null,
      );

  Widget _gradeDropdown(List grades) => DropdownButtonFormField<int>(
        initialValue: _selectedGradeId,
        decoration: const InputDecoration(
          labelText: 'الصف الدراسي *',
          prefixIcon: Icon(Icons.school_outlined),
          isDense: true,
        ),
        isExpanded: true,
        items: grades
            .map((g) => DropdownMenuItem<int>(
                  value: g.id,
                  child: Text(
                    g.name,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                ))
            .toList(),
        onChanged: (val) => setState(() => _selectedGradeId = val),
        validator: (v) => v == null ? 'اختر الصف' : null,
      );

  Widget _semesterDropdown() => DropdownButtonFormField<String>(
        initialValue: _selectedSemester,
        decoration: const InputDecoration(
          labelText: 'الفصل الدراسي *',
          prefixIcon: Icon(Icons.date_range_outlined),
          isDense: true,
        ),
        isExpanded: true,
        items: const [
          DropdownMenuItem(
            value: 'FirstTerm',
            child: Text('الفصل الدراسي الأول', textDirection: TextDirection.rtl),
          ),
          DropdownMenuItem(
            value: 'SecondTerm',
            child: Text('الفصل الدراسي الثاني', textDirection: TextDirection.rtl),
          ),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _selectedSemester = val);
        },
      );

  Widget _academicYearField() => TextFormField(
        controller: _academicYearCtrl,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          labelText: 'العام الدراسي (اختياري)',
          hintText: '2024/2025',
          prefixIcon: Icon(Icons.calendar_today_outlined),
          isDense: true,
        ),
      );

  Widget _originalPriceField() => TextFormField(
        controller: _originalPriceCtrl,
        textDirection: TextDirection.ltr,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'السعر قبل الخصم (ر.ع)',
          hintText: 'اختياري - مثلاً 7.000',
          prefixIcon: Icon(Icons.money_off_outlined),
          isDense: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\.]')),
        ],
      );

  Widget _pageCountField() => TextFormField(
        controller: _pageCountCtrl,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'عدد الصفحات (اختياري)',
          hintText: 'مثال: 150',
          prefixIcon: Icon(Icons.auto_stories_outlined),
          isDense: true,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      );

  Widget _priceField() => TextFormField(
        controller: _priceCtrl,
        textDirection: TextDirection.ltr,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'السعر (ر.ع) *',
          hintText: '5.000',
          prefixIcon: Icon(Icons.monetization_on_outlined),
          isDense: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\.]')),
        ],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'السعر مطلوب';
          final p = double.tryParse(v);
          if (p == null || p < 0) return 'سعر غير صالح';
          return null;
        },
      );

  Widget _validityField() => TextFormField(
        controller: _validityCtrl,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'مدة الصلاحية (أيام) *',
          hintText: '365',
          prefixIcon: Icon(Icons.calendar_today_outlined),
          isDense: true,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'المدة مطلوبة';
          final n = int.tryParse(v);
          if (n == null || n < 1) return 'عدد صحيح ≥ 1';
          return null;
        },
      );

  Widget _descField() => TextFormField(
        controller: _descCtrl,
        textDirection: TextDirection.rtl,
        maxLines: 3,
        minLines: 2,
        decoration: const InputDecoration(
          labelText: 'وصف الكتاب (اختياري)',
          hintText: 'نبذة تعريفية عن محتوى الكتاب والأهداف التعليمية...',
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 36),
            child: Icon(Icons.notes_rounded),
          ),
          isDense: true,
        ),
      );

  Widget _pdfPickerButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.upload_file_rounded),
      label: const Text('اختر ملف PDF'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _pickPdf,
    );
  }

  Widget _fileChip(
      String name, IconData icon, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}
