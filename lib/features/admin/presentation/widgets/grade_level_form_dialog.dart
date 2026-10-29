import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/admin_models.dart';

class GradeLevelFormDialog extends StatefulWidget {
  final AdminGradeLevel? gradeLevel;
  final ValueChanged<GradeLevelRequest> onSubmit;

  const GradeLevelFormDialog({
    super.key,
    this.gradeLevel,
    required this.onSubmit,
  });

  @override
  State<GradeLevelFormDialog> createState() => _GradeLevelFormDialogState();
}

class _GradeLevelFormDialogState extends State<GradeLevelFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.gradeLevel?.name ?? '');
    _orderCtrl = TextEditingController(
        text: (widget.gradeLevel?.order ?? 1).toString());
    _isActive = widget.gradeLevel?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 1;
    final request = GradeLevelRequest(
      name: _nameCtrl.text.trim(),
      order: order,
      isActive: _isActive,
    );
    widget.onSubmit(request);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.gradeLevel != null;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade600,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'تعديل الصف الدراسي'
                            : 'إضافة صف دراسي جديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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

              // ── Form ──────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name field — accepts Arabic & English
                      TextFormField(
                        controller: _nameCtrl,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: 'اسم الصف *',
                          hintText: 'مثال: الصف التاسع / Grade 9',
                          prefixIcon: const Icon(Icons.school_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLowest,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'اسم الصف مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Order field — numbers only, LTR
                      TextFormField(
                        controller: _orderCtrl,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'الترتيب *',
                          hintText: 'رقم الترتيب (مثال: 9)',
                          prefixIcon: const Icon(
                              Icons.format_list_numbered_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLowest,
                          helperText:
                              'يحدد ترتيب الصفوف من الأصغر إلى الأكبر',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'الترتيب مطلوب';
                          }
                          final n = int.tryParse(v);
                          if (n == null || n < 1) {
                            return 'أدخل رقماً صحيحاً موجباً';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Active toggle
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          title: const Text('الصف نشط'),
                          subtitle: const Text(
                              'إظهار هذا الصف في التطبيق'),
                          value: _isActive,
                          onChanged: (val) =>
                              setState(() => _isActive = val),
                          activeThumbColor: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

              // ── Actions ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: Icon(
                            isEditing ? Icons.save_rounded : Icons.add),
                        label: Text(isEditing
                            ? 'حفظ التعديلات'
                            : 'إضافة الصف'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submit,
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
}
