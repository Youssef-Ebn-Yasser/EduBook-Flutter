import 'package:flutter/material.dart';

class RejectOrderDialog extends StatefulWidget {
  final int orderId;
  final ValueChanged<String> onConfirm;

  const RejectOrderDialog({
    super.key,
    required this.orderId,
    required this.onConfirm,
  });

  @override
  State<RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<RejectOrderDialog> {
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _quickReasons = [
    'إشعار التحويل غير واضح أو غير مكتمل',
    'المبلغ المحول غير مطابق لسعر الكتاب',
    'الرقم المرجعي غير صحيح أو مكرر',
    'لم يتم استلام الحوالة في الحساب البنكي',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onConfirm(_reasonCtrl.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.red),
          const SizedBox(width: 8),
          Text('رفض الطلب #${widget.orderId}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'يرجى توضيح سبب رفض الطلب حتى يظهر للطالب ويتمكن من إعادة المحاولة:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Quick suggestions chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickReasons.map((r) {
                  return ActionChip(
                    label: Text(r, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() => _reasonCtrl.text = r);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض *',
                  hintText: 'اكتب سبب الرفض هنا بالتفصيل...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'الرجاء كتابة سبب الرفض';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('تراجع'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _submit,
          child: const Text('تأكيد الرفض'),
        ),
      ],
    );
  }
}
