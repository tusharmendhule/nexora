import 'package:flutter/material.dart';

/// Animated shimmering placeholder box.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = const BorderRadius.all(Radius.circular(10)),
  });

  final double? width;
  final double height;
  final BorderRadius radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            gradient: LinearGradient(
              begin: Alignment(-1.8 + 3.6 * t, 0),
              end: Alignment(1.8 + 3.6 * t, 0),
              colors: [
                scheme.surfaceContainerHighest,
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton mimicking a feed post card.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBox(
                width: 42,
                height: 42,
                radius: BorderRadius.all(Radius.circular(21)),
              ),
              SizedBox(width: 12),
              SkeletonBox(width: 120, height: 14),
              Spacer(),
              SkeletonBox(width: 20, height: 14),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonBox(
            height: 240,
            radius: BorderRadius.circular(18),
            width: double.infinity,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              SkeletonBox(width: 24, height: 24),
              SizedBox(width: 12),
              SkeletonBox(width: 24, height: 24),
              SizedBox(width: 12),
              SkeletonBox(width: 24, height: 24),
              Spacer(),
              SkeletonBox(width: 24, height: 24),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(width: 160, height: 13),
          const SizedBox(height: 8),
          const SkeletonBox(width: 240, height: 13),
        ],
      ),
    );
  }
}

/// Skeleton row for the stories tray.
class StorySkeleton extends StatelessWidget {
  const StorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        6,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              SkeletonBox(
                width: 62,
                height: 62,
                radius: BorderRadius.all(Radius.circular(31)),
              ),
              SizedBox(height: 8),
              SkeletonBox(width: 48, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton grid used by Explore / Profile tabs.
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.items = 6});

  final int items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: items,
      itemBuilder: (_, __) => const SkeletonBox(
        radius: BorderRadius.zero,
      ),
    );
  }
}
