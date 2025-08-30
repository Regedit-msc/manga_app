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
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar to match the real layout
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const ShimmerBox(height: 20, width: 150),
            backgroundColor: theme.brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF2C2C54),
            elevation: 1,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: const [
                    ShimmerBox(height: 32, width: 80),
                    SizedBox(width: 8),
                    ShimmerBox(height: 32, width: 24),
                    SizedBox(width: 8),
                    ShimmerBox(height: 32, width: 24),
                    SizedBox(width: 8),
                    ShimmerBox(height: 32, width: 24),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),

          // Main content with image card layout matching the actual design
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Image card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const ShimmerBox(
                      width: 120,
                      height: 160,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right side - Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        // Title
                        ShimmerBox(height: 24, width: double.infinity),
                        SizedBox(height: 8),
                        ShimmerBox(height: 20, width: 180),
                        SizedBox(height: 6),

                        // Author
                        ShimmerBox(height: 16, width: 120),
                        SizedBox(height: 12),

                        // Stats row
                        Row(
                          children: [
                            ShimmerBox(height: 28, width: 60),
                            SizedBox(width: 8),
                            ShimmerBox(height: 28, width: 80),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Status chip
                        ShimmerBox(
                          height: 24,
                          width: 80,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Genres section
          SliverToBoxAdapter(child: shimmerChips(count: 5)),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),

          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Expanded(
                    child: ShimmerBox(
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ShimmerBox(
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(height: 18, width: 80), // "Summary" title
                  SizedBox(height: 8),
                  ShimmerBox(height: 14, width: double.infinity),
                  SizedBox(height: 6),
                  ShimmerBox(height: 14, width: double.infinity),
                  SizedBox(height: 6),
                  ShimmerBox(height: 14, width: 280),
                  SizedBox(height: 6),
                  ShimmerBox(height: 14, width: 220),
                ],
              ),
            ),
          ),

          // Chapters section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child:
                  const ShimmerBox(height: 18, width: 100), // "Chapters" title
            ),
          ),

          // Chapters list - using list tiles to match the actual implementation
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 6,
              (ctx, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: const [
                    ShimmerBox(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(height: 16, width: double.infinity),
                          SizedBox(height: 4),
                          ShimmerBox(height: 12, width: 140),
                          SizedBox(height: 4),
                          ShimmerBox(height: 12, width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 24)),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}
