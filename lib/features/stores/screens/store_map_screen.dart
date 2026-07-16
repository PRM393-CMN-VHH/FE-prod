import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:prm393/features/stores/models/store_location.dart';
import 'package:prm393/features/stores/widgets/store_info_drawer.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  StoreLocation? _selectedLocation;
  bool _isLoading = true;
  late final WebViewController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _loadLocations();
  }

  void _loadLocations() async {
    final locs = await _apiService.getStoreLocations();
    setState(() {
      if (locs.isNotEmpty) {
        _selectedLocation = locs.first;
      }
      _isLoading = false;
    });
    if (locs.isNotEmpty) {
      _loadAppleMap(locs.first);
    }
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

  void _openInExternalMap(StoreLocation location) async {
    final appleMapsUrl = Uri.parse(
      "maps://?ll=${location.latitude},${location.longitude}&q=${Uri.encodeComponent(location.name)}",
    );
    final browserAppleMapsUrl = _appleMapUri(location);
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}",
    );
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(browserAppleMapsUrl)) {
        await launchUrl(
          browserAppleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(browserAppleMapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không thể mở ứng dụng bản đồ"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _callStore(StoreLocation location) async {
    final cleanPhone = location.phone.replaceAll(' ', '');
    final url = Uri.parse("tel:$cleanPhone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return Column(
      children: [
        Expanded(flex: 5, child: WebViewWidget(controller: _mapController)),
        Expanded(
          flex: 4,
          child: StoreInfoDrawer(
            location: _selectedLocation,
            onCall: () => _callStore(_selectedLocation!),
            onDirections: () => _openInExternalMap(_selectedLocation!),
          ),
        ),
      ],
    );
  }
}
