import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';

class GenreChipsRow extends StatelessWidget {
  final List<String> genres;
  const GenreChipsRow({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final g = genres[i];
          return ActionChip(
            label: Text(g, style: theme.textTheme.labelLarge),
            onPressed: () => Navigator.pushNamed(
              context,
              Routes.categories,
              arguments: getGenre(g),
            ),
            avatar: const Icon(Icons.local_fire_department_rounded, size: 18),
          );
        },
      ),
    );
  }
}
