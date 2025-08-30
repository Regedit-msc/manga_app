import 'package:flutter/material.dart';
import 'package:webcomic/presentation/widgets/shimmer/shimmer_widgets.dart';

/// Lightweight shimmer layout shown while MangaInfo data loads
class MangaInfoShimmer extends StatelessWidget {
  const MangaInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Banner
                shimmerBanner(height: MediaQuery.of(context).size.height / 3),
                // Gradient overlay for readability
                Container(
                  height: MediaQuery.of(context).size.height / 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
                // Title placeholder
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: const ShimmerBox(height: 20, width: 220),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          // Chips and stats placeholders
          SliverToBoxAdapter(child: shimmerChips(count: 6)),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  Expanded(child: ShimmerBox(height: 16)),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerBox(height: 16)),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerBox(height: 16)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  Expanded(
                      child: ShimmerBox(
                          height: 44,
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                  SizedBox(width: 12),
                  Expanded(
                      child: ShimmerBox(
                          height: 44,
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
          // Summary placeholder
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(height: 18, width: 120),
                  SizedBox(height: 8),
                  ShimmerBox(height: 12),
                  SizedBox(height: 6),
                  ShimmerBox(height: 12, width: 280),
                  SizedBox(height: 6),
                  ShimmerBox(height: 12, width: 220),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
          // Chapters skeleton rows
          SliverToBoxAdapter(
              child: shimmerRows(count: 6, imageWidth: 90, imageHeight: 60)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          // Recommendations skeleton
          SliverToBoxAdapter(
              child: shimmerHorizontalCards(
                  count: 6, cardWidth: 160, imageHeight: 200)),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}
