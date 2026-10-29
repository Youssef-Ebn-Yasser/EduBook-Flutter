import '../../books/data/book_models.dart';

class ReaderSession {
  final int bookId;
  final String bookTitle;
  final String? coverUrl;
  final String streamUrl;
  final String readToken;
  final DateTime subscriptionExpiresAt;
  final int daysRemaining;
  final int lastPageRead;
  final int totalPages;
  final bool isSample;
  final String pageImageUrlTemplate;
  final List<BookUnit> units;

  const ReaderSession({
    required this.bookId,
    required this.bookTitle,
    this.coverUrl,
    required this.streamUrl,
    required this.readToken,
    required this.subscriptionExpiresAt,
    required this.daysRemaining,
    required this.lastPageRead,
    required this.totalPages,
    required this.isSample,
    required this.pageImageUrlTemplate,
    required this.units,
  });

  factory ReaderSession.fromJson(Map<String, dynamic> json) {
    final rawUnits = (json['units'] as List<dynamic>?) ?? [];
    return ReaderSession(
      bookId: json['bookId'] as int? ?? 0,
      bookTitle: json['bookTitle'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      streamUrl: json['streamUrl'] as String? ?? '',
      readToken: json['readToken'] as String? ?? '',
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      lastPageRead: json['lastPageRead'] as int? ?? 1,
      totalPages: (json['totalPages'] as int? ?? 1) < 1 ? 1 : (json['totalPages'] as int? ?? 1),
      isSample: json['isSample'] as bool? ?? false,
      pageImageUrlTemplate: json['pageImageUrlTemplate'] as String? ?? '',
      units: rawUnits.map((u) => BookUnit.fromJson(u as Map<String, dynamic>)).toList(),
    );
  }

  /// Construct the full URL for rendering a given page as an image
  String getPageImageUrl(String baseUrl, int pageNumber) {
    if (pageImageUrlTemplate.isNotEmpty) {
      final path = pageImageUrlTemplate.replaceAll('{pageNumber}', pageNumber.toString());
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '$cleanBase$cleanPath';
    }
    // Fallback URL pattern
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final encodedToken = Uri.encodeComponent(readToken);
    return '$cleanBase/api/Reader/$bookId/pages/$pageNumber?token=$encodedToken';
  }
}

class ReaderAnnotation {
  final int id;
  final int bookId;
  final int pageNumber;
  final String type; // note, highlight, drawing
  final String? color;
  final String dataJson;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReaderAnnotation({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.type,
    this.color,
    required this.dataJson,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReaderAnnotation.fromJson(Map<String, dynamic> json) {
    return ReaderAnnotation(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      type: json['type'] as String? ?? 'note',
      color: json['color'] as String?,
      dataJson: json['dataJson'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class SaveAnnotationRequest {
  final int pageNumber;
  final String type;
  final String? color;
  final String dataJson;

  const SaveAnnotationRequest({
    required this.pageNumber,
    required this.type,
    this.color,
    required this.dataJson,
  });

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'type': type,
        'color': color,
        'dataJson': dataJson,
      };
}

class ReadingProgressResponse {
  final int bookId;
  final int lastPageRead;
  final DateTime? lastReadAt;

  const ReadingProgressResponse({
    required this.bookId,
    required this.lastPageRead,
    this.lastReadAt,
  });

  factory ReadingProgressResponse.fromJson(Map<String, dynamic> json) {
    return ReadingProgressResponse(
      bookId: json['bookId'] as int? ?? 0,
      lastPageRead: json['lastPageRead'] as int? ?? 1,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'].toString())
          : null,
    );
  }
}
