import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Wraps an avatar (or any child) in the signature story gradient ring.
/// Seen stories render a neutral grey ring.
class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.child,
    this.isSeen = false,
    this.showAdd = false,
  });

  final Widget child;
  final bool isSeen;
  final bool showAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final ring = Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSeen ? scheme.outlineVariant : null,
        gradient: isSeen ? null : AppColors.feedStoryGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surface),
        child: child,
      ),
    );

    if (!showAdd) return ring;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ring,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              border: Border.all(color: scheme.surface, width: 2),
            ),
            child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
