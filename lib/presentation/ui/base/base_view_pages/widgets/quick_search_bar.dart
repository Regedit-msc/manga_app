import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';

class QuickSearchBar extends StatelessWidget {
  const QuickSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, Routes.mangaSearch),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search manga, authors, genres…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
