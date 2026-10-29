// ─── Categories ──────────────────────────────────────────────────────────────

class AdminCategory {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int bookCount;

  const AdminCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.bookCount = 0,
  });

  factory AdminCategory.fromJson(Map<String, dynamic> json) => AdminCategory(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        bookCount: json['bookCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'isActive': isActive,
      };
}

class CategoryRequest {
  final String name;
  final String? description;
  final bool isActive;

  const CategoryRequest({
    required this.name,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'isActive': isActive,
      };
}

// ─── Grade Levels ────────────────────────────────────────────────────────────

class AdminGradeLevel {
  final int id;
  final String name;
  final int order;
  final bool isActive;
  final int bookCount;

  const AdminGradeLevel({
    required this.id,
    required this.name,
    required this.order,
    this.isActive = true,
    this.bookCount = 0,
  });

  factory AdminGradeLevel.fromJson(Map<String, dynamic> json) => AdminGradeLevel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        bookCount: json['bookCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'order': order,
        'isActive': isActive,
      };
}

class GradeLevelRequest {
  final String name;
  final int order;
  final bool isActive;

  const GradeLevelRequest({
    required this.name,
    required this.order,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'order': order,
        'isActive': isActive,
      };
}

// ─── Books ───────────────────────────────────────────────────────────────────

class CreateBookRequest {
  final String title;
  final String? isbn;
  final String? description;
  final double price;
  final int validityDays;
  final int gradeLevelId;
  final int categoryId;

  const CreateBookRequest({
    required this.title,
    this.isbn,
    this.description,
    required this.price,
    this.validityDays = 365,
    required this.gradeLevelId,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (isbn != null && isbn!.isNotEmpty) 'isbn': isbn,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'price': price,
        'validityDays': validityDays,
        'gradeLevelId': gradeLevelId,
        'categoryId': categoryId,
      };
}

class UpdateBookRequest {
  final String? title;
  final String? isbn;
  final String? description;
  final double? price;
  final int? validityDays;
  final int? gradeLevelId;
  final int? categoryId;
  final bool? isActive;

  const UpdateBookRequest({
    this.title,
    this.isbn,
    this.description,
    this.price,
    this.validityDays,
    this.gradeLevelId,
    this.categoryId,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (isbn != null) map['isbn'] = isbn;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (validityDays != null) map['validityDays'] = validityDays;
    if (gradeLevelId != null) map['gradeLevelId'] = gradeLevelId;
    if (categoryId != null) map['categoryId'] = categoryId;
    if (isActive != null) map['isActive'] = isActive;
    return map;
  }
}

class BookUnitRequest {
  final String title;
  final String? description;
  final String? youtubeUrl;
  final int order;
  final bool isFreeSample;

  const BookUnitRequest({
    required this.title,
    this.description,
    this.youtubeUrl,
    required this.order,
    this.isFreeSample = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (youtubeUrl != null && youtubeUrl!.trim().isNotEmpty)
          'youtubeUrl': youtubeUrl!.trim(),
        'order': order,
        'isFreeSample': isFreeSample,
      };
}

// ─── Admin Orders ─────────────────────────────────────────────────────────────

enum AdminOrderStatus {
  pendingVerification(0),
  approved(1),
  rejected(2),
  cancelled(3);

  final int value;
  const AdminOrderStatus(this.value);

  static AdminOrderStatus fromInt(int v) {
    return AdminOrderStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => AdminOrderStatus.pendingVerification,
    );
  }

  static AdminOrderStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return AdminOrderStatus.approved;
      case 'rejected':
        return AdminOrderStatus.rejected;
      case 'cancelled':
        return AdminOrderStatus.cancelled;
      default:
        return AdminOrderStatus.pendingVerification;
    }
  }
}

class AdminOrder {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookCoverUrl;
  final double amount;
  final String currency;
  final AdminOrderStatus status;
  final String statusText;
  final String receiptUrl;
  final String? bankReferenceNumber;
  final String? studentNotes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? reviewedByAdminName;

  const AdminOrder({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookCoverUrl,
    required this.amount,
    this.currency = 'OMR',
    required this.status,
    required this.statusText,
    required this.receiptUrl,
    this.bankReferenceNumber,
    this.studentNotes,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.reviewedByAdminName,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final AdminOrderStatus status;
    if (rawStatus is int) {
      status = AdminOrderStatus.fromInt(rawStatus);
    } else if (rawStatus is String) {
      status = AdminOrderStatus.fromString(rawStatus);
    } else {
      status = AdminOrderStatus.pendingVerification;
    }

    final id = (json['id'] as num?)?.toInt() ??
        (json['orderId'] as num?)?.toInt() ??
        0;

    return AdminOrder(
      id: id,
      bookId: (json['bookId'] as num?)?.toInt() ?? 0,
      bookTitle: json['bookTitle'] as String? ?? '',
      bookCoverUrl: json['bookCoverUrl'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'OMR',
      status: status,
      statusText: json['statusText'] as String? ??
          (status == AdminOrderStatus.approved
              ? 'مقبول ومفعل'
              : (status == AdminOrderStatus.rejected
                  ? 'مرفوض'
                  : 'معلق')),
      receiptUrl: json['receiptUrl'] as String? ?? '',
      bankReferenceNumber: json['bankReferenceNumber'] as String?,
      studentNotes: json['studentNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? 'طالب',
      studentEmail: json['studentEmail'] as String? ?? '',
      reviewedByAdminName: json['reviewedByAdminName'] as String?,
    );
  }
}

// ─── Dashboard Stats & Users Management ─────────────────────────────────────

class TopSellingBook {
  final int bookId;
  final String title;
  final String? coverUrl;
  final double price;
  final String gradeLevelName;
  final String categoryName;
  final int salesCount;
  final double totalRevenue;

  const TopSellingBook({
    required this.bookId,
    required this.title,
    this.coverUrl,
    required this.price,
    required this.gradeLevelName,
    required this.categoryName,
    required this.salesCount,
    required this.totalRevenue,
  });

  factory TopSellingBook.fromJson(Map<String, dynamic> json) => TopSellingBook(
        bookId: json['bookId'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        coverUrl: json['coverUrl'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        gradeLevelName: json['gradeLevelName'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        salesCount: json['salesCount'] as int? ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      );
}

class MonthlySales {
  final int year;
  final int month;
  final String monthName;
  final int ordersCount;
  final double totalRevenue;

  const MonthlySales({
    required this.year,
    required this.month,
    required this.monthName,
    required this.ordersCount,
    required this.totalRevenue,
  });

  factory MonthlySales.fromJson(Map<String, dynamic> json) => MonthlySales(
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        monthName: json['monthName'] as String? ?? '',
        ordersCount: json['ordersCount'] as int? ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      );
}

class SalesByGrade {
  final int gradeLevelId;
  final String gradeLevelName;
  final int ordersCount;
  final double totalRevenue;
  final double percentage;

  const SalesByGrade({
    required this.gradeLevelId,
    required this.gradeLevelName,
    required this.ordersCount,
    required this.totalRevenue,
    required this.percentage,
  });

  factory SalesByGrade.fromJson(Map<String, dynamic> json) => SalesByGrade(
        gradeLevelId: json['gradeLevelId'] as int? ?? 0,
        gradeLevelName: json['gradeLevelName'] as String? ?? '',
        ordersCount: json['ordersCount'] as int? ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

class AdminDashboardStats {
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalBooks;
  final int totalActiveBooks;
  final int totalOrders;
  final int approvedOrders;
  final int pendingVerificationOrders;
  final int rejectedOrders;
  final double totalRevenue;
  final String currency;
  final List<TopSellingBook> topSellingBooks;
  final List<AdminOrder> recentOrders;
  final List<MonthlySales> monthlySales;
  final List<SalesByGrade> salesByGrade;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalBooks,
    required this.totalActiveBooks,
    required this.totalOrders,
    required this.approvedOrders,
    required this.pendingVerificationOrders,
    required this.rejectedOrders,
    required this.totalRevenue,
    this.currency = 'OMR',
    this.topSellingBooks = const [],
    this.recentOrders = const [],
    this.monthlySales = const [],
    this.salesByGrade = const [],
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final rawTopBooks = (json['topSellingBooks'] as List<dynamic>?) ?? [];
    final rawRecent = (json['recentOrders'] as List<dynamic>?) ?? [];
    final rawMonthly = (json['monthlySales'] as List<dynamic>?) ?? [];
    final rawGrades = (json['salesByGrade'] as List<dynamic>?) ?? [];

    return AdminDashboardStats(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalTeachers: (json['totalTeachers'] as num?)?.toInt() ?? 0,
      totalBooks: (json['totalBooks'] as num?)?.toInt() ?? 0,
      totalActiveBooks: (json['totalActiveBooks'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      approvedOrders: (json['approvedOrders'] as num?)?.toInt() ?? 0,
      pendingVerificationOrders: (json['pendingVerificationOrders'] as num?)?.toInt() ?? 0,
      rejectedOrders: (json['rejectedOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'OMR',
      topSellingBooks: rawTopBooks
          .whereType<Map>()
          .map((e) => TopSellingBook.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      recentOrders: rawRecent
          .whereType<Map>()
          .map((e) => AdminOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      monthlySales: rawMonthly
          .whereType<Map>()
          .map((e) => MonthlySales.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      salesByGrade: rawGrades
          .whereType<Map>()
          .map((e) => SalesByGrade.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final int purchasedBooksCount;
  final double totalSpent;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.purchasedBooksCount,
    required this.totalSpent,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        role: json['role'] as String? ?? 'Student',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        purchasedBooksCount: json['purchasedBooksCount'] as int? ?? 0,
        totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      );
}

class AdminUserBook {
  final int bookId;
  final String title;
  final String? coverUrl;
  final String gradeLevelName;
  final String categoryName;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final int daysRemaining;
  final bool isExpired;
  final int orderId;
  final double amountPaid;

  const AdminUserBook({
    required this.bookId,
    required this.title,
    this.coverUrl,
    required this.gradeLevelName,
    required this.categoryName,
    required this.purchasedAt,
    required this.expiresAt,
    required this.daysRemaining,
    required this.isExpired,
    required this.orderId,
    required this.amountPaid,
  });

  factory AdminUserBook.fromJson(Map<String, dynamic> json) => AdminUserBook(
        bookId: json['bookId'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        coverUrl: json['coverUrl'] as String?,
        gradeLevelName: json['gradeLevelName'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? '') ?? DateTime.now(),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? DateTime.now(),
        daysRemaining: json['daysRemaining'] as int? ?? 0,
        isExpired: json['isExpired'] as bool? ?? false,
        orderId: json['orderId'] as int? ?? 0,
        amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      );
}

class AdminUserDetail extends AdminUser {
  final List<AdminUserBook> purchasedBooks;
  final List<AdminOrder> orders;

  const AdminUserDetail({
    required super.id,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.purchasedBooksCount,
    required super.totalSpent,
    this.purchasedBooks = const [],
    this.orders = const [],
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final base = AdminUser.fromJson(json);
    final rawBooks = (json['purchasedBooks'] as List<dynamic>?) ?? [];
    final rawOrders = (json['orders'] as List<dynamic>?) ?? [];

    return AdminUserDetail(
      id: base.id,
      fullName: base.fullName,
      email: base.email,
      phoneNumber: base.phoneNumber,
      role: base.role,
      isActive: base.isActive,
      createdAt: base.createdAt,
      purchasedBooksCount: base.purchasedBooksCount,
      totalSpent: base.totalSpent,
      purchasedBooks: rawBooks.map((e) => AdminUserBook.fromJson(e as Map<String, dynamic>)).toList(),
      orders: rawOrders.map((e) => AdminOrder.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

