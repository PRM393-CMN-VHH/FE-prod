import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prm393/services/api_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VnpayPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final Function(Map<String, dynamic>) onPaymentSuccess;
  final Function(Map<String, dynamic>) onPaymentFail;

  const VnpayPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.onPaymentSuccess,
    required this.onPaymentFail,
  });

  @override
  State<VnpayPaymentScreen> createState() => _VnpayPaymentScreenState();
}

class _VnpayPaymentScreenState extends State<VnpayPaymentScreen> {
  static const Duration _callbackTimeout = Duration(seconds: 15);

  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledReturn = false;

  bool _isVnpayReturnUrl(String url) => url.contains('payment/vnpayReturn');

  Future<Map<String, dynamic>> _fetchBackendResult(String url) async {
    // Normalizing URL: Replace host/port with backendBaseUrl to handle 'localhost' issues in mobile
    final interceptedUri = Uri.parse(url);
    final backendUri = Uri.parse(ApiService.backendBaseUrl);

    final normalizedUri = interceptedUri.replace(
      scheme: backendUri.scheme,
      host: backendUri.host,
      port: backendUri.port,
    );

    final response = await ApiService().getRequest(normalizedUri.toString());
    if (response is Map<String, dynamic>) {
      return response;
    }

    return {
      'status': 'fail',
      'message':
          'Hệ thống trả về dữ liệu thanh toán không hợp lệ. Vui lòng kiểm tra lại đơn hàng.',
    };
  }

  void _completePayment(Map<String, dynamic> result) {
    if (result['status'] == 'success') {
      widget.onPaymentSuccess(result);
    } else {
      widget.onPaymentFail(result);
    }
  }

  Future<void> _handleReturnUrl(String url) async {
    if (_hasHandledReturn) return;
    _hasHandledReturn = true;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _fetchBackendResult(url);
      _completePayment(result);
    } catch (_) {
      widget.onPaymentFail({
        'message':
            'Không thể xác nhận kết quả thanh toán từ hệ thống. Vui lòng kiểm tra lại đơn hàng.',
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            // Phát hiện URL Return từ Backend
            if (_isVnpayReturnUrl(request.url)) {
              await _handleReturnUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            if (_isVnpayReturnUrl(url)) {
              unawaited(_handleReturnUrl(url));
              return;
            }
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Logic handled in onNavigationRequest or onPageStarted
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán VNPay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // User cancelled
            widget.onPaymentFail({'message': 'Người dùng đã hủy thanh toán'});
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
