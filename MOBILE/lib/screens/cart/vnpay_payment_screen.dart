import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledReturn = false;

  bool _isVnpayReturnUrl(String url) => url.contains('payment/vnpayReturn');

  Map<String, dynamic> _resultFromReturnUrl(Uri uri) {
    final params = uri.queryParameters;
    final responseCode = params['vnp_ResponseCode'];
    final transactionStatus = params['vnp_TransactionStatus'];
    final isSuccess =
        responseCode == '00' &&
        (transactionStatus == null || transactionStatus == '00');

    return {
      'status': isSuccess ? 'success' : 'fail',
      'message': isSuccess
          ? 'Thanh toán thành công'
          : 'Thanh toán thất bại (Mã lỗi: ${responseCode ?? 'không xác định'})',
      'orderId': params['vnp_TxnRef'],
      'amount': params['vnp_Amount'],
      'bankCode': params['vnp_BankCode'],
      'responseCode': responseCode,
      'transactionStatus': transactionStatus,
    };
  }

  Future<Map<String, dynamic>?> _fetchBackendResult(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _waitForBackendSuccess(String url) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await _fetchBackendResult(url);
        if (result != null && result['status'] == 'success') {
          return result;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 700));
    }
    return null;
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
      final uri = Uri.parse(url);
      final hasVnpayResult = uri.queryParameters.containsKey(
        'vnp_ResponseCode',
      );

      if (hasVnpayResult) {
        final vnpayResult = _resultFromReturnUrl(uri);
        if (vnpayResult['status'] != 'success') {
          widget.onPaymentFail(vnpayResult);
          return;
        }

        final backendResult = await _waitForBackendSuccess(url);
        widget.onPaymentSuccess({
          ...vnpayResult,
          if (backendResult != null) ...backendResult,
        });
        return;
      }

      final result = await _fetchBackendResult(url);

      if (result != null && result['status'] == 'success') {
        widget.onPaymentSuccess(result);
      } else {
        widget.onPaymentFail(
          result ??
              {
                'message':
                    'Không thể xác nhận kết quả thanh toán. Vui lòng kiểm tra lại đơn hàng.',
              },
        );
      }
    } catch (_) {
      widget.onPaymentFail({
        'message':
            'Đã nhận phản hồi từ VNPay nhưng không thể đọc kết quả. Vui lòng kiểm tra lại đơn hàng.',
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
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            if (_isVnpayReturnUrl(url) && !_hasHandledReturn) {
              _hasHandledReturn = true;
              // Lấy nội dung JSON từ phản hồi của Backend
              final String responseText =
                  await _controller.runJavaScriptReturningResult(
                        "document.body.innerText",
                      )
                      as String;

              // Giải mã chuỗi JSON (trong một số môi trường có thể bị bao bởi dấu nháy kép thừa)
              String cleanJson = responseText;
              if (cleanJson.startsWith('"') && cleanJson.endsWith('"')) {
                cleanJson = cleanJson
                    .substring(1, cleanJson.length - 1)
                    .replaceAll('\\"', '"');
              }

              try {
                final Map<String, dynamic> result = jsonDecode(cleanJson);
                if (result['status'] == 'success') {
                  widget.onPaymentSuccess(result);
                } else {
                  widget.onPaymentFail(result);
                }
              } catch (e) {
                widget.onPaymentFail({'message': 'Lỗi xử lý dữ liệu!'});
              }
            }
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
