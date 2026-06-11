import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:prm393/models/store_location.dart';
import 'package:prm393/services/api_service.dart';
import 'package:prm393/theme/app_theme.dart';

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
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return Column(
      children: [
        Expanded(flex: 5, child: WebViewWidget(controller: _mapController)),

        // Bottom Info Drawer Card
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: _selectedLocation == null
                ? const Center(child: Text("Select a location on the map"))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedLocation!.name,
                              style: textTheme.titleLarge?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Open",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.textSecondaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation!.address,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppTheme.textSecondaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Working Hours: ${_selectedLocation!.hours}",
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            color: AppTheme.textSecondaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Hotline: ${_selectedLocation!.phone}",
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppTheme.primaryColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _callStore(_selectedLocation!),
                              icon: const Icon(
                                Icons.call,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                              label: const Text(
                                "Call Store",
                                style: TextStyle(color: AppTheme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  _openInExternalMap(_selectedLocation!),
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text("Directions"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter to render simulated map backgrounds (roads, waterways)
class MapGridPainter extends CustomPainter {
  final Offset offset;
  final double zoom;
  final List<StoreLocation> locations;
  final int? selectedId;

  MapGridPainter({
    required this.offset,
    required this.zoom,
    required this.locations,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Background color
    paint.color = const Color(0xFFEDF1EE);
    canvas.drawRect(Offset.zero & size, paint);

    // Zoom and pan coordinate space transformation
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    // Draw simulated river/waterway
    paint.color = const Color(0xFFA5C9EB);
    final waterPath = Path()
      ..moveTo(-500, 200)
      ..quadraticBezierTo(200, 180, 400, 400)
      ..quadraticBezierTo(500, 500, 1000, 450)
      ..lineTo(1000, 1000)
      ..lineTo(-500, 1000)
      ..close();
    canvas.drawPath(waterPath, paint);

    // Draw major simulated highways
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Road lines definition
    final roadPaths = <Path>[
      Path()
        ..moveTo(-500, 100)
        ..lineTo(1200, 100),
      Path()
        ..moveTo(100, -200)
        ..lineTo(100, 800),
      Path()
        ..moveTo(-200, 300)
        ..lineTo(800, 300),
    ];

    for (final path in roadPaths) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Secondary streets
    roadPaint.strokeWidth = 6;
    roadBorderPaint.strokeWidth = 8;
    final streetPaths = <Path>[
      Path()
        ..moveTo(-100, 0)
        ..lineTo(500, 600),
      Path()
        ..moveTo(300, 0)
        ..lineTo(-200, 500),
    ];

    for (final path in streetPaths) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Draw green garden/parks blocks
    paint.color = const Color(0xFFCBE3CE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(180, -20, 150, 100),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-100, 150, 120, 80),
        const Radius.circular(8),
      ),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.zoom != zoom ||
        oldDelegate.locations != locations ||
        oldDelegate.selectedId != selectedId;
  }
}
