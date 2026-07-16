import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/error_translator.dart';

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: const CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String text;

  const AdminEmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  final Object error;

  const AdminErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ErrorTranslator.userMessage(error),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: card,
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AdminStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color adminStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMED':
      return Colors.blue.shade700;
    case 'SHIPPED':
      return Colors.indigo.shade700;
    case 'DELIVERED':
      return Colors.green.shade700;
    case 'CANCELLED':
      return Colors.red.shade700;
    case 'PENDING':
    default:
      return Colors.orange.shade800;
  }
}

void showAdminError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ErrorTranslator.userMessage(error)),
      backgroundColor: Colors.redAccent,
    ),
  );
}
