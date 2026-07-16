import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/stores/models/store_location.dart';

class StoreInfoDrawer extends StatelessWidget {
  final StoreLocation? location;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  const StoreInfoDrawer({
    super.key,
    required this.location,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
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
      child: location == null
          ? const Center(child: Text("Select a location on the map"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        location!.name,
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
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: location!.address,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.access_time,
                  text: "Working Hours: ${location!.hours}",
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  text: "Hotline: ${location!.phone}",
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onCall,
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onDirections,
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text("Directions"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
