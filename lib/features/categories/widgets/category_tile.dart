import 'package:flutter/material.dart';

import '../../../core/widgets/admin_widgets.dart';
import '../models/category.dart';

class CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AdminCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
                category.isActive ? scheme.primary : scheme.outlineVariant,
            child: Text(
              category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: category.isActive
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${category.createdAt.toDate().toString().split(' ')[0]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: category.isActive,
                onChanged: (_) => onToggle(),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? scheme.primary
                      : scheme.surfaceVariant,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: scheme.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
