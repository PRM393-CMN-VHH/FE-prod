import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/core/utils/error_translator.dart';
import 'package:prm393/core/utils/status_translator.dart';
import 'package:prm393/features/orders/widgets/order_info_tile.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/cart/screens/cart_screen.dart';
import 'package:prm393/features/catalog/widgets/product_reviews_section.dart';
import 'package:prm393/features/catalog/models/product.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final bool isAdmin;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.isAdmin = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await (widget.isAdmin
          ? ApiService().getAdminOrderDetail(widget.orderId)
          : ApiService().getOrderDetail(widget.orderId));
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorTranslator.userMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleConfirmReceived(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận đã nhận hàng"),
        content: const Text(
          "Bạn xác nhận đã nhận được đơn hàng này đầy đủ và đúng hẹn?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Xác nhận",
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService().confirmOrderReceived(order.id);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xác nhận đã nhận hàng thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Không thể xác nhận: ${ErrorTranslator.userMessage(e)}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleReview(OrderModel order) async {
    if (order.items.isEmpty) return;

    Product selectedProduct;
    if (order.items.length == 1) {
      selectedProduct = order.items.first.product;
    } else {
      final Product? chosen = await showModalBottomSheet<Product>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chọn sản phẩm để đánh giá",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: order.items.length,
                      itemBuilder: (context, idx) {
                        final item = order.items[idx];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.local_florist),
                            ),
                          ),
                          title: Text(item.product.name),
                          onTap: () => Navigator.pop(ctx, item.product),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (chosen == null) return;
      selectedProduct = chosen;
    }

    if (!mounted) return;
    final result = await showWriteReviewSheet(context);
    if (result == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService().submitProductReview(
        selectedProduct.id,
        rating: result.rating,
        comment: result.comment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gửi đánh giá thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lỗi khi gửi đánh giá: ${ErrorTranslator.userMessage(e)}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleReorder(OrderModel order) async {
    setState(() => _isSubmitting = true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    bool allAdded = true;
    String? lastError;

    for (final item in order.items) {
      try {
        final success = await cartProvider.addToCart(item.product, item.quantity);
        if (!success) {
          allAdded = false;
          lastError = cartProvider.errorMessage;
        }
      } catch (e) {
        allAdded = false;
        lastError = e.toString();
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (allAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã thêm toàn bộ sản phẩm vào giỏ hàng!"),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Không thể thêm toàn bộ sản phẩm vào giỏ: ${lastError ?? 'Lỗi không xác định'}",
            ),
          ),
        );
      }
    }
  }

  Widget? _buildBottomActions() {
    if (widget.isAdmin || _order == null) return null;
    final order = _order!;

    final status = order.status.toUpperCase();
    final isDelivered = status == 'DELIVERED';
    final isCompleted = status == 'COMPLETED';

    if (!isDelivered && !isCompleted) return null;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : isDelivered
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _handleConfirmReceived(order),
                  child: const Text(
                    "Đã nhận hàng",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleReview(order),
                        child: const Text(
                          "Đánh giá",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleReorder(order),
                        child: const Text(
                          "Mua lại",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thông tin đơn hàng",
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _order == null
                  ? const Center(
                      child: Text("Không tìm thấy đơn hàng"),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrder,
                      color: AppTheme.primaryColor,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        children: [
                          OrderInfoTile(
                            label: "Trạng thái đơn",
                            value: StatusTranslator.orderStatus(_order!.status),
                          ),
                          OrderInfoTile(
                            label: "Thanh toán",
                            value:
                                "${_order!.paymentMethod}${_order!.paymentStatus.isEmpty ? '' : ' (${StatusTranslator.paymentStatus(_order!.paymentStatus)})'}",
                          ),
                          OrderInfoTile(label: "Người nhận", value: _order!.recipientName),
                          OrderInfoTile(
                            label: "Số điện thoại",
                            value: _order!.recipientPhone,
                          ),
                          OrderInfoTile(label: "Địa chỉ", value: _order!.shippingAddress),
                          OrderInfoTile(
                            label: "Ngày tạo",
                            value:
                                "${_order!.createdAt.day.toString().padLeft(2, '0')}/${_order!.createdAt.month.toString().padLeft(2, '0')}/${_order!.createdAt.year}",
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Sản phẩm",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_order!.items.isEmpty)
                            const Text(
                              "Không có chi tiết sản phẩm.",
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            )
                          else
                            ..._order!.items.map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.product.imageUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.local_florist),
                                  ),
                                ),
                                title: Text(item.product.name),
                                subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Số lượng: ${item.quantity}",
                                      style: const TextStyle(color: AppTheme.textPrimaryColor),
                                    ),
                                    Text(
                                      formatVnd(item.price * item.quantity),
                                      style: const TextStyle(color: AppTheme.textPrimaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const Divider(height: 32),
                          if (_order!.items.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tạm tính",
                                  style: TextStyle(color: AppTheme.textSecondaryColor),
                                ),
                                Text(
                                  formatVnd(
                                    _order!.items.fold(
                                      0.0,
                                      (sum, item) => sum + (item.product.price * item.quantity),
                                    ),
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Giảm giá",
                                  style: TextStyle(color: AppTheme.textSecondaryColor),
                                ),
                                Text(
                                  (() {
                                    final orig = _order!.items.fold(
                                      0.0,
                                      (sum, item) => sum + (item.product.price * item.quantity),
                                    );
                                    final act = _order!.items.fold(
                                      0.0,
                                      (sum, item) => sum + (item.price * item.quantity),
                                    );
                                    final diff = orig - act;
                                    return diff > 0 ? "-${formatVnd(diff)}" : "0đ";
                                  })(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Phí giao hàng",
                                  style: TextStyle(color: AppTheme.textSecondaryColor),
                                ),
                                Text(
                                  (() {
                                    final act = _order!.items.fold(
                                      0.0,
                                      (sum, item) => sum + (item.price * item.quantity),
                                    );
                                    final fee = _order!.totalAmount - act;
                                    return fee > 0 ? formatVnd(fee) : "Miễn phí";
                                  })(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tổng cộng",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                formatVnd(_order!.totalAmount),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}
