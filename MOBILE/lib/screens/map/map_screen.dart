import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<StoreLocation> _locations = [];
  StoreLocation? _selectedLocation;
  bool _isLoading = true;

  // Map simulated zoom/pan offsets
  double _zoomLevel = 1.0;
  Offset _mapOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() async {
    final locs = await _apiService.getStoreLocations();
    setState(() {
      _locations = locs;
      if (locs.isNotEmpty) {
        _selectedLocation = locs.first;
      }
      _isLoading = false;
    });
  }

  void _openInExternalMap(StoreLocation location) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}"
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not launch external map application"),
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
        // Simulated Interactive Map Canvas
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              // Map Background grids and visuals
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _mapOffset += details.delta;
                  });
                },
                child: Container(
                  color: const Color(0xFFE8ECE9), // Soft green-gray map color
                  child: CustomPaint(
                    painter: MapGridPainter(
                      offset: _mapOffset,
                      zoom: _zoomLevel,
                      locations: _locations,
                      selectedId: _selectedLocation?.id,
                    ),
                    child: Container(),
                  ),
                ),
              ),

              // Zoom controls
              Positioned(
                right: 16,
                top: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimaryColor,
                      child: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _zoomLevel = (_zoomLevel + 0.2).clamp(0.5, 3.0);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimaryColor,
                      child: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          _zoomLevel = (_zoomLevel - 0.2).clamp(0.5, 3.0);
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Visual tip overlay
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Drag to pan",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Interactive overlay pins
              ..._locations.map((loc) {
                // Map coordinates to simulated screen offsets
                // We'll calculate a relative spacing based on HCM coordinate offsets
                final relativeX = (loc.longitude - 106.68) * 12000;
                final relativeY = -(loc.latitude - 107.75) * 12000;

                final posX = (relativeX * _zoomLevel) + _mapOffset.dx + 180;
                final posY = (relativeY * _zoomLevel) + _mapOffset.dy + 120;

                final isSelected = _selectedLocation?.id == loc.id;

                return Positioned(
                  left: posX - 16,
                  top: posY - 36,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLocation = loc;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                          size: isSelected ? 36 : 28,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                          ),
                          child: Text(
                            loc.name.split('-').last.trim(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Bottom Info Drawer Card
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          const Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryColor, size: 18),
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
                          const Icon(Icons.access_time, color: AppTheme.textSecondaryColor, size: 18),
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
                          const Icon(Icons.phone_outlined, color: AppTheme.textSecondaryColor, size: 18),
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
                                side: const BorderSide(color: AppTheme.primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _callStore(_selectedLocation!),
                              icon: const Icon(Icons.call, color: AppTheme.primaryColor, size: 18),
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
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _openInExternalMap(_selectedLocation!),
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
      Path()..moveTo(-500, 100)..lineTo(1200, 100),
      Path()..moveTo(100, -200)..lineTo(100, 800),
      Path()..moveTo(-200, 300)..lineTo(800, 300),
    ];

    for (final path in roadPaths) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Secondary streets
    roadPaint.strokeWidth = 6;
    roadBorderPaint.strokeWidth = 8;
    final streetPaths = <Path>[
      Path()..moveTo(-100, 0)..lineTo(500, 600),
      Path()..moveTo(300, 0)..lineTo(-200, 500),
    ];
    
    for (final path in streetPaths) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Draw green garden/parks blocks
    paint.color = const Color(0xFFCBE3CE);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(180, -20, 150, 100), const Radius.circular(8)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-100, 150, 120, 80), const Radius.circular(8)), paint);

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
