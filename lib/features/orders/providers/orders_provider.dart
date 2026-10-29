import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_models.dart';
import '../data/orders_repository.dart';

/// Provider for Bank Muscat payment account details
final bankDetailsProvider = FutureProvider.autoDispose<BankDetails>((ref) async {
  final repo = ref.read(ordersRepositoryProvider);
  final res = await repo.getBankDetails();
  if (res.success && res.data != null) {
    return res.data!;
  }
  throw Exception(res.message.isNotEmpty ? res.message : 'فشل تحميل بيانات التحويل البنكي');
});

/// State for My Orders list
class MyOrdersState {
  final bool isLoading;
  final List<StudentOrder> orders;
  final String? error;

  const MyOrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
  });

  MyOrdersState copyWith({
    bool? isLoading,
    List<StudentOrder>? orders,
    String? error,
  }) {
    return MyOrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
    );
  }
}

class MyOrdersNotifier extends StateNotifier<MyOrdersState> {
  final OrdersRepository _repo;

  MyOrdersNotifier(this._repo) : super(const MyOrdersState()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repo.getMyOrders();
    if (res.success && res.data != null) {
      state = state.copyWith(isLoading: false, orders: res.data!);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.message.isNotEmpty ? res.message : 'تعذر تحميل الطلبات',
      );
    }
  }

  Future<bool> createOrder(CreateBankOrderInput input) async {
    final res = await _repo.createOrder(input);
    if (res.success) {
      await fetchOrders();
      return true;
    }
    return false;
  }
}

final myOrdersProvider =
    StateNotifierProvider<MyOrdersNotifier, MyOrdersState>((ref) {
  return MyOrdersNotifier(ref.read(ordersRepositoryProvider));
});
