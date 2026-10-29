// ─── Query Params ─────────────────────────────────────────────────────────────

class BookQueryParams {
  final int? gradeLevelId;
  final int? categoryId;
  final String? search;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy; // newest | price_asc | price_desc
  final int page;
  final int pageSize;

  const BookQueryParams({
    this.gradeLevelId,
    this.categoryId,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
    this.page = 1,
    this.pageSize = 12,
  });

  Map<String, dynamic> toQueryMap() {
    final map = <String, dynamic>{
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    };
    if (gradeLevelId != null) map['gradeLevelId'] = gradeLevelId;
    if (categoryId != null) map['categoryId'] = categoryId;
    if (search != null && search!.isNotEmpty) map['search'] = search;
    if (minPrice != null) map['minPrice'] = minPrice;
    if (maxPrice != null) map['maxPrice'] = maxPrice;
    return map;
  }

  BookQueryParams copyWith({
    int? gradeLevelId,
    int? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    int? page,
    int? pageSize,
  }) =>
      BookQueryParams(
        gradeLevelId: gradeLevelId ?? this.gradeLevelId,
        categoryId: categoryId ?? this.categoryId,
        search: search ?? this.search,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        sortBy: sortBy ?? this.sortBy,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}

// ─── Response Models ──────────────────────────────────────────────────────────

class BookListItem {
  final int id;
  final String title;
  final String? isbn;
  final double price;
  final double? originalPrice;
  final String? academicYear;
  final String? semester;
  final int pageCount;
  final double rating;
  final int reviewsCount;
  final bool isTaxInclusive;
  final bool isOfficialCurriculum;
  final String? coverUrl;
  final int validityDays;
  final String gradeLevelName;
  final String categoryName;
  final String publisherName;
  final bool isActive;
  final DateTime createdAt;

  const BookListItem({
    required this.id,
    required this.title,
    this.isbn,
    required this.price,
    this.originalPrice,
    this.academicYear,
    this.semester,
    this.pageCount = 0,
    this.rating = 5.0,
    this.reviewsCount = 0,
    this.isTaxInclusive = true,
    this.isOfficialCurriculum = true,
    this.coverUrl,
    required this.validityDays,
    required this.gradeLevelName,
    required this.categoryName,
    required this.publisherName,
    required this.isActive,
    required this.createdAt,
  });

  String? get semesterName {
    if (semester == null || semester!.isEmpty) return null;
    final s = semester!.toLowerCase();
    if (s == 'firstterm' || s == '1') return 'الفصل الدراسي الأول';
    if (s == 'secondterm' || s == '2') return 'الفصل الدراسي الثاني';
    return semester;
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  int get discountPercentage {
    if (!hasDiscount || originalPrice == null || originalPrice! <= 0) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  factory BookListItem.fromJson(Map<String, dynamic> json) => BookListItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        isbn: json['isbn'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
        academicYear: json['academicYear'] as String?,
        semester: json['semester']?.toString(),
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
        isTaxInclusive: json['isTaxInclusive'] as bool? ?? true,
        isOfficialCurriculum: json['isOfficialCurriculum'] as bool? ?? true,
        coverUrl: json['coverUrl'] as String?,
        validityDays: (json['validityDays'] as num?)?.toInt() ?? 365,
        gradeLevelName: json['gradeLevelName'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        publisherName: json['publisherName'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class BookUnit {
  final int id;
  final String title;
  final String? description;
  final String? youtubeUrl;
  final bool hasPdfFile;
  final String? pdfFileName;
  final int? pdfFileSizeBytes;
  final DateTime? pdfUploadedAt;
  final String? pdfStreamUrl;
  final int order;
  final bool isFreeSample;

  const BookUnit({
    required this.id,
    required this.title,
    this.description,
    this.youtubeUrl,
    this.hasPdfFile = false,
    this.pdfFileName,
    this.pdfFileSizeBytes,
    this.pdfUploadedAt,
    this.pdfStreamUrl,
    required this.order,
    this.isFreeSample = false,
  });

  bool get hasYoutube => youtubeUrl != null && youtubeUrl!.trim().isNotEmpty;

  String get fileSizeFormatted {
    if (pdfFileSizeBytes == null || pdfFileSizeBytes! <= 0) return '';
    final mb = pdfFileSizeBytes! / (1024 * 1024);
    if (mb >= 1.0) return '${mb.toStringAsFixed(1)} ميجابايت';
    final kb = pdfFileSizeBytes! / 1024;
    return '${kb.toStringAsFixed(0)} كيلوبايت';
  }

  factory BookUnit.fromJson(Map<String, dynamic> json) => BookUnit(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        youtubeUrl: json['youtubeUrl'] as String?,
        hasPdfFile: json['hasPdfFile'] as bool? ?? (json['pdfFileName'] != null),
        pdfFileName: json['pdfFileName'] as String?,
        pdfFileSizeBytes: (json['pdfFileSizeBytes'] as num?)?.toInt(),
        pdfUploadedAt: json['pdfUploadedAt'] != null
            ? DateTime.tryParse(json['pdfUploadedAt'].toString())
            : null,
        pdfStreamUrl: json['pdfStreamUrl'] as String?,
        order: (json['order'] as num?)?.toInt() ?? 0,
        isFreeSample: json['isFreeSample'] as bool? ?? false,
      );
}

class BookFile {
  final int id;
  final String? fileUrl;
  final String? fileName;
  final String version;
  final int fileSizeBytes;
  final int pageCount;
  final bool hasDigitalBook;
  final bool isActive;
  final DateTime? uploadedAt;

  const BookFile({
    required this.id,
    this.fileUrl,
    this.fileName,
    this.version = '1.0',
    this.fileSizeBytes = 0,
    this.pageCount = 0,
    this.hasDigitalBook = true,
    this.isActive = false,
    this.uploadedAt,
  });

  factory BookFile.fromJson(Map<String, dynamic> json) => BookFile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fileUrl: json['fileUrl'] as String?,
        fileName: json['fileName'] as String?,
        version: json['version'] as String? ?? '1.0',
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        hasDigitalBook: json['hasDigitalBook'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? false,
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'] as String? ?? '')
            : null,
      );

  String get fileSizeMb {
    if (fileSizeBytes <= 0) return '0 MB';
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb < 0.1) {
      final kb = fileSizeBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class BookDetail extends BookListItem {
  final String? description;
  final int gradeLevelId;
  final int categoryId;
  final List<BookUnit> units;
  final BookFile? activeFile;

  const BookDetail({
    required super.id,
    required super.title,
    super.isbn,
    required super.price,
    super.originalPrice,
    super.academicYear,
    super.semester,
    super.pageCount = 0,
    super.rating = 5.0,
    super.reviewsCount = 0,
    super.isTaxInclusive = true,
    super.isOfficialCurriculum = true,
    super.coverUrl,
    required super.validityDays,
    required super.gradeLevelName,
    required super.categoryName,
    required super.publisherName,
    required super.isActive,
    required super.createdAt,
    this.description,
    required this.gradeLevelId,
    required this.categoryId,
    required this.units,
    this.activeFile,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) => BookDetail(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        isbn: json['isbn'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
        academicYear: json['academicYear'] as String?,
        semester: json['semester']?.toString(),
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
        isTaxInclusive: json['isTaxInclusive'] as bool? ?? true,
        isOfficialCurriculum: json['isOfficialCurriculum'] as bool? ?? true,
        coverUrl: json['coverUrl'] as String?,
        validityDays: (json['validityDays'] as num?)?.toInt() ?? 365,
        gradeLevelName: json['gradeLevelName'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        publisherName: json['publisherName'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        description: json['description'] as String?,
        gradeLevelId: (json['gradeLevelId'] as num?)?.toInt() ?? 0,
        categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
        units: (json['units'] as List<dynamic>?)
                ?.map((u) => BookUnit.fromJson(u as Map<String, dynamic>))
                .toList() ??
            [],
        activeFile: json['activeFile'] != null
            ? BookFile.fromJson(
                json['activeFile'] as Map<String, dynamic>)
            : null,
      );
}

// ─── Paginated response wrapper ───────────────────────────────────────────────

class PaginatedBooks {
  final List<BookListItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedBooks({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < totalCount;

  /// The API may return a plain list OR a paginated wrapper. Handle both.
  factory PaginatedBooks.fromJson(dynamic json, {int page = 1, int pageSize = 12}) {
    if (json is List) {
      final items =
          json.map((e) => BookListItem.fromJson(e as Map<String, dynamic>)).toList();
      return PaginatedBooks(
          items: items, totalCount: items.length, page: page, pageSize: pageSize);
    }
    final map = json as Map<String, dynamic>;
    final rawItems = (map['items'] ?? map['data'] ?? map['books'] ?? []) as List<dynamic>;
    return PaginatedBooks(
      items: rawItems
          .map((e) => BookListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: map['totalCount'] as int? ??
          map['total'] as int? ??
          rawItems.length,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
    );
  }
}

// ─── My Books (library) ───────────────────────────────────────────────────────

class MyBookItem {
  final int bookId;
  final String title;
  final String? coverUrl;
  final String? publisherName;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final bool isExpired;
  final int daysRemaining;
  final bool hasAccess;

  const MyBookItem({
    required this.bookId,
    required this.title,
    this.coverUrl,
    this.publisherName,
    required this.purchasedAt,
    required this.expiresAt,
    this.isExpired = false,
    this.daysRemaining = 0,
    required this.hasAccess,
  });

  factory MyBookItem.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
        DateTime.now();
    final rawIsExpired = json['isExpired'] as bool?;
    final isExpired = rawIsExpired ?? DateTime.now().isAfter(expiresAt);
    final hasAccess = json['hasAccess'] as bool? ??
        (!isExpired && DateTime.now().isBefore(expiresAt));
    final daysRemaining = (json['daysRemaining'] as num?)?.toInt() ??
        (isExpired
            ? 0
            : expiresAt.difference(DateTime.now()).inDays.clamp(0, 99999));

    return MyBookItem(
      bookId: json['bookId'] as int? ?? json['id'] as int,
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      publisherName: json['publisherName'] as String?,
      purchasedAt:
          DateTime.tryParse(json['purchasedAt'] as String? ?? '') ??
              DateTime.now(),
      expiresAt: expiresAt,
      isExpired: isExpired,
      daysRemaining: daysRemaining,
      hasAccess: hasAccess,
    );
  }
}

// ─── Access check ─────────────────────────────────────────────────────────────

class BookAccessResponse {
  final bool hasAccess;
  final DateTime? expiresAt;

  const BookAccessResponse({required this.hasAccess, this.expiresAt});

  int get daysRemaining => expiresAt != null
      ? (expiresAt!.difference(DateTime.now()).inDays > 0
          ? expiresAt!.difference(DateTime.now()).inDays
          : 0)
      : 0;

  factory BookAccessResponse.fromJson(Map<String, dynamic> json) =>
      BookAccessResponse(
        hasAccess: json['hasAccess'] as bool? ?? false,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
      );
}
