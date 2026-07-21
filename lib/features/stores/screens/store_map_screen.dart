import 'package:flutter/material.dart';
import 'package:prm393/features/stores/models/store_location.dart';
import 'package:prm393/features/stores/screens/store_detail_map_screen.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  List<StoreLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() async {
    final locs = await _apiService.getStoreLocations();
    if (mounted) {
      setState(() {
        _locations = locs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_locations.isEmpty) {
      return const Center(
        child: Text(
          "Không tìm thấy cửa hàng nào.",
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final location = _locations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreDetailMapScreen(location: location),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.textSecondaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location.address,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 13,
                          ),
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
                        "Giờ mở cửa: ${location.hours}",
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13,
                        ),
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
                        "Hotline: ${location.phone}",
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
