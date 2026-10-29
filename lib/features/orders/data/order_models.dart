import 'package:flutter/material.dart';

/// Bank Muscat details returned from GET /api/Payments/bank-details
class BankDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String phoneNumber;
  final String transferInstructions;

  const BankDetails({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.phoneNumber,
    required this.transferInstructions,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] as String? ?? json['BankName'] as String? ?? 'بنك مسقط',
      accountName: json['accountName'] as String? ?? json['AccountName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? json['AccountNumber'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? json['PhoneNumber'] as String? ?? '',
      transferInstructions: json['transferInstructions'] as String? ??
          json['TransferInstructions'] as String? ??
          '',
    );
  }
}

/// Order status enum
enum StudentOrderStatus {
  pendingVerification(0),
  approved(1),
  rejected(2),
  cancelled(3);

  final int value;
  const StudentOrderStatus(this.value);

  static StudentOrderStatus fromInt(int v) {
    return StudentOrderStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => StudentOrderStatus.pendingVerification,
    );
  }

  String get labelAr {
    switch (this) {
      case StudentOrderStatus.pendingVerification:
        return 'قيد المراجعة والتحقق';
      case StudentOrderStatus.approved:
        return 'مقبول ومفعل';
      case StudentOrderStatus.rejected:
        return 'مرفوض';
      case StudentOrderStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case StudentOrderStatus.pendingVerification:
        return Colors.orange;
      case StudentOrderStatus.approved:
        return Colors.green;
      case StudentOrderStatus.rejected:
        return Colors.red;
      case StudentOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case StudentOrderStatus.pendingVerification:
        return Icons.hourglass_top_rounded;
      case StudentOrderStatus.approved:
        return Icons.check_circle_rounded;
      case StudentOrderStatus.rejected:
        return Icons.cancel_rounded;
      case StudentOrderStatus.cancelled:
        return Icons.block_rounded;
    }
  }
}

/// Student's Order Model
class StudentOrder {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookCoverUrl;
  final double amount;
  final String currency;
  final StudentOrderStatus status;
  final String statusText;
  final String receiptUrl;
  final String? bankReferenceNumber;
  final String? studentNotes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const StudentOrder({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookCoverUrl,
    required this.amount,
    required this.currency,
    required this.status,
    required this.statusText,
    required this.receiptUrl,
    this.bankReferenceNumber,
    this.studentNotes,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  factory StudentOrder.fromJson(Map<String, dynamic> json) {
    final statusInt = json['status'] as int? ?? json['Status'] as int? ?? 0;
    return StudentOrder(
      id: json['id'] as int? ?? json['Id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? json['BookId'] as int? ?? 0,
      bookTitle: json['bookTitle'] as String? ?? json['BookTitle'] as String? ?? '',
      bookCoverUrl: json['bookCoverUrl'] as String? ?? json['BookCoverUrl'] as String?,
      amount: (json['amount'] as num? ?? json['Amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? json['Currency'] as String? ?? 'OMR',
      status: StudentOrderStatus.fromInt(statusInt),
      statusText: json['statusText'] as String? ??
          json['StatusText'] as String? ??
          StudentOrderStatus.fromInt(statusInt).labelAr,
      receiptUrl: json['receiptUrl'] as String? ?? json['ReceiptUrl'] as String? ?? '',
      bankReferenceNumber: json['bankReferenceNumber'] as String? ?? json['BankReferenceNumber'] as String?,
      studentNotes: json['studentNotes'] as String? ?? json['StudentNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String? ?? json['RejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['CreatedAt'] != null
              ? DateTime.tryParse(json['CreatedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : (json['ReviewedAt'] != null
              ? DateTime.tryParse(json['ReviewedAt'].toString())
              : null),
    );
  }
}

/// Input model for creating a bank order
class CreateBankOrderInput {
  final int bookId;
  final String receiptImagePath;
  final String? bankReferenceNumber;
  final String? studentNotes;

  const CreateBankOrderInput({
    required this.bookId,
    required this.receiptImagePath,
    this.bankReferenceNumber,
    this.studentNotes,
  });
}
