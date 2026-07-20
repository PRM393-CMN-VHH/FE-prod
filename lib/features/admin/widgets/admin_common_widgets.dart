import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/error_translator.dart';
import 'package:prm393/core/utils/status_translator.dart';

// A small semantic palette for the admin surface. Kept separate from
// AppTheme (which is tuned for customer-facing screens) but chosen to sit
// comfortably alongside the burgundy/blush brand colors instead of clashing
// stock Material hues.
class AdminPalette {
  const AdminPalette._();

  static const Color info = Color(0xFF3D6B8C); // confirmed / neutral info
  static const Color progress = Color(0xFF6B5CA5); // shipped / in-transit
  static const Color success = Color(0xFF2E7D5B); // delivered / active
  static const Color warning = Color(0xFFB8720C); // pending / low stock
  static const Color danger = Color(0xFFC1444B); // cancelled / locked
  static const Color neutral = Color(0xFF8A7B7D); // muted / unknown
}

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
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.text,
    this.icon = Icons.inbox_outlined,
  });

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
              child: Icon(icon, color: AppTheme.primaryColor),
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
      return AdminPalette.info;
    case 'SHIPPED':
      return AdminPalette.progress;
    case 'DELIVERED':
    case 'PAID':
      return AdminPalette.success;
    case 'CANCELLED':
    case 'FAILED':
      return AdminPalette.danger;
    case 'PENDING':
    default:
      return AdminPalette.warning;
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

void showAdminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppTheme.primaryColor),
  );
}

// Consistent section title used to separate groups of content within a tab
// (e.g. dashboard's "Tổng quan" vs "Đơn hàng theo trạng thái").
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AdminSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// Shared search bar used by the Orders/Products/Users tabs, replacing three
// near-identical hand-rolled TextField+AdminCard blocks.
class AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSubmitted;
  final Widget? trailing;

  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2.0,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: hintText,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSubmitted(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

// Horizontal row of filter chips (e.g. order status). Scrolls if it overflows
// small screens instead of wrapping into an awkward multi-row block.
class AdminFilterChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  const AdminFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allLabel = "Tất cả",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: options.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final value = index == 0 ? null : options[index - 1];
          final label = index == 0 ? allLabel : StatusTranslator.orderStatus(options[index - 1]);
          final isSelected = selected == value;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.black.withValues(alpha: 0.08),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

// Compact stat tile for dashboard totals.
class AdminStatCard extends StatelessWidget {
  final String label;
  final Object? value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            "${value ?? 0}",
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// A single row in the "orders by status" breakdown: icon, label, count, and
// a proportion bar relative to [total] so admins can eyeball the split
// without doing math.
class AdminStatusBreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const AdminStatusBreakdownRow({
    super.key,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "$count",
                      style: TextStyle(color: color, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Prev/next pagination footer. Hidden entirely when there's nothing to page
// through (single page and not currently loading more).
class AdminPageControl extends StatelessWidget {
  final int page;
  final bool hasMore;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const AdminPageControl({
    super.key,
    required this.page,
    required this.hasMore,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (page == 1 && !hasMore) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: page > 1 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 12),
          Text(
            "Trang $page",
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

// Confirmation dialog for actions with real consequences (delete, deactivate,
// cancel, role change). Returns true only if the user tapped confirm.
Future<bool> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(AppMessage.cancelAction.text),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive
                ? AdminPalette.danger
                : AppTheme.primaryColor,
          ),
          child: Text(confirmLabel ?? AppMessage.confirmDefault.text),
        ),
      ],
    ),
  );
  return result ?? false;
}
