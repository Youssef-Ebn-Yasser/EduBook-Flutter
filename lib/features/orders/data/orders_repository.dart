import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/data/auth_models.dart';
import 'order_models.dart';

class OrdersRepository {
  final Dio _dio;
  final List<StudentOrder> _cachedOrders = [];

  OrdersRepository(this._dio);

  /// GET /api/Payments/bank-details
  /// Retrieves official Bank Muscat account information & transfer instructions
  Future<ApiResponse<BankDetails>> getBankDetails() async {
    try {
      final response = await _dio.get('/api/Payments/bank-details');
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final success = raw['success'] as bool? ?? true;
        final message = raw['message'] as String? ?? '';
        final data = raw['data'] ?? raw;
        return ApiResponse<BankDetails>(
          success: success,
          message: message,
          data: BankDetails.fromJson(data as Map<String, dynamic>),
        );
      }
      return const ApiResponse<BankDetails>(
        success: false,
        message: 'استجابة غير متوقعة من الخادم',
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'فشل تحميل بيانات البنك')
          : 'تعذر الاتصال بخدمة المدفوعات';
      return ApiResponse<BankDetails>(
        success: false,
        message: msg.toString(),
      );
    } catch (e) {
      return ApiResponse<BankDetails>(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// POST /api/Orders
  /// Submits a purchase order with the transfer receipt image (multipart/form-data)
  Future<ApiResponse<StudentOrder>> createOrder(CreateBankOrderInput input) async {
    try {
      final fileName = input.receiptImagePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'BookId': input.bookId,
        'ReceiptImage': await MultipartFile.fromFile(
          input.receiptImagePath,
          filename: fileName,
        ),
        if (input.bankReferenceNumber != null &&
            input.bankReferenceNumber!.trim().isNotEmpty)
          'BankReferenceNumber': input.bankReferenceNumber!.trim(),
        if (input.studentNotes != null &&
            input.studentNotes!.trim().isNotEmpty)
          'StudentNotes': input.studentNotes!.trim(),
      });

      final response = await _dio.post(
        '/api/Orders',
        data: formData,
      );

      final raw = response.data as Map<String, dynamic>;
      final success = raw['success'] as bool? ?? true;
      final message = raw['message'] as String? ?? 'تم إرسال إشعار التحويل بنجاح';
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      final studentOrder = StudentOrder.fromJson(data);

      _cachedOrders.removeWhere((o) => o.id == studentOrder.id);
      _cachedOrders.insert(0, studentOrder);

      return ApiResponse<StudentOrder>(
        success: success,
        message: message,
        data: studentOrder,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'فشل إرسال طلب الشراء')
          : 'حدث خطأ أثناء رفع إشعار التحويل';
      return ApiResponse<StudentOrder>(
        success: false,
        message: msg.toString(),
      );
    } catch (e) {
      return ApiResponse<StudentOrder>(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// GET /api/Orders/my-orders
  /// Retrieves all purchase orders for the logged-in student
  Future<ApiResponse<List<StudentOrder>>> getMyOrders() async {
    try {
      final response = await _dio.get('/api/Orders/my-orders');
      final raw = response.data;
      List<dynamic> list;
      if (raw is Map<String, dynamic>) {
        list = (raw['data'] ?? raw['items'] ?? []) as List<dynamic>;
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }

      final orders = list
          .map((e) => StudentOrder.fromJson(e as Map<String, dynamic>))
          .toList();

      _cachedOrders.clear();
      _cachedOrders.addAll(orders);

      return ApiResponse<List<StudentOrder>>(
        success: true,
        message: '',
        data: orders,
      );
    } on DioException catch (e) {
      if (_cachedOrders.isNotEmpty) {
        return ApiResponse<List<StudentOrder>>(
          success: true,
          message: 'تم عرض الطلبات المحفوظة مؤقتاً',
          data: List.unmodifiable(_cachedOrders),
        );
      }
      final rawMsg = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;
      final isInternalError = e.response?.statusCode == 500 ||
          (rawMsg != null &&
              rawMsg.toLowerCase().contains('internal server error'));
      final msg = isInternalError
          ? 'الخادم يواجه ضغطاً مؤقتاً في معالجة طلبات التحويل. يرجى إعادة المحاولة لاحقاً.'
          : (rawMsg ?? 'تعذر الاتصال بالخادم');
      return ApiResponse<List<StudentOrder>>(
        success: false,
        message: msg,
      );
    } catch (e) {
      if (_cachedOrders.isNotEmpty) {
        return ApiResponse<List<StudentOrder>>(
          success: true,
          message: 'تم عرض الطلبات المحفوظة مؤقتاً',
          data: List.unmodifiable(_cachedOrders),
        );
      }
      return ApiResponse<List<StudentOrder>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// GET /api/Orders/{id}
  Future<ApiResponse<StudentOrder>> getOrderById(int id) async {
    try {
      final response = await _dio.get('/api/Orders/$id');
      final raw = response.data as Map<String, dynamic>;
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      return ApiResponse<StudentOrder>(
        success: raw['success'] as bool? ?? true,
        message: raw['message'] as String? ?? '',
        data: StudentOrder.fromJson(data),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'فشل تحميل تفاصيل الطلب')
          : 'تعذر الاتصال بالخادم';
      return ApiResponse<StudentOrder>(
        success: false,
        message: msg.toString(),
      );
    } catch (e) {
      return ApiResponse<StudentOrder>(
        success: false,
        message: e.toString(),
      );
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.read(dioClientProvider));
});
