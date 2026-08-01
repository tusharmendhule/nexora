import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Circular member avatar with optional online indicator and story ring.
class NexoraAvatar extends StatelessWidget {
  const NexoraAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = 44,
    this.online = false,
    this.ringColor,
  });

  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final bool online;

  /// When set, draws a gradient story ring around the avatar.
  final Color? ringColor;

  String get _initial =>
      fallbackText == null || fallbackText!.isEmpty
          ? '?'
          : fallbackText![0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
      ),
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? _FallbackAvatar(initial: _initial)
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _FallbackAvatar(initial: _initial),
            ),
    );

    final Widget withRing = ringColor == null
        ? avatar
        : Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.feedStoryGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: avatar,
            ),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        withRing,
        if (online)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(color: scheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradientDeep),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
