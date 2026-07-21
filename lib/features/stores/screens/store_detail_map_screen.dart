import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:prm393/features/stores/models/store_location.dart';

class StoreDetailMapScreen extends StatefulWidget {
  final StoreLocation location;

  const StoreDetailMapScreen({super.key, required this.location});

  @override
  State<StoreDetailMapScreen> createState() => _StoreDetailMapScreenState();
}

class _StoreDetailMapScreenState extends State<StoreDetailMapScreen> {
  late final WebViewController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            _mapController.runJavaScript('''
              var style = document.createElement('style');
              style.innerHTML = '.banner, .app-promo, .smart-banner, .open-in-maps, .open-in-maps-banner { display: none !important; }';
              document.head.appendChild(style);
            ''');
          },
        ),
      );
    _loadAppleMap(widget.location);
  }

  Uri _appleMapUri(StoreLocation location) {
    return Uri.https('maps.apple.com', '/', {
      'll': '${location.latitude},${location.longitude}',
      'q': location.name,
      'z': '15',
    });
  }

  void _loadAppleMap(StoreLocation location) {
    _mapController.loadRequest(_appleMapUri(location));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.location.name,
          style: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: WebViewWidget(controller: _mapController),
    );
  }
}
