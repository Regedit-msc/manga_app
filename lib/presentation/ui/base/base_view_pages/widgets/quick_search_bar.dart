import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';

class QuickSearchBar extends StatelessWidget {
  const QuickSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final bg =
        isLight ? Colors.grey.shade200 : scheme.surface.withOpacity(0.12);
    final border =
        isLight ? Colors.grey.shade300 : scheme.outline.withOpacity(0.2);
    final fg = isLight ? Colors.grey.shade700 : scheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, Routes.mangaSearch),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search manga, authors, genres…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: fg),
          ],
        ),
      ),
    );
  }
}
