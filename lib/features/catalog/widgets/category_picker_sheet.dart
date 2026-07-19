import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/catalog/models/category.dart';

// Modal list of gift-occasion categories ("Tất cả" + each Category), replacing
// the always-visible chip row so browsing by occasion doesn't eat up screen
// space until the shopper actually wants to filter.
class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int selectedCategoryId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text("Chọn dịp", style: textTheme.titleLarge),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _CategoryTile(
                  label: "Tất cả",
                  isSelected: selectedCategoryId == 0,
                  onTap: () {
                    onSelected(0);
                    Navigator.pop(context);
                  },
                ),
                for (final category in categories)
                  _CategoryTile(
                    label: category.name,
                    isSelected: selectedCategoryId == category.id,
                    onTap: () {
                      onSelected(category.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
    );
  }
}
