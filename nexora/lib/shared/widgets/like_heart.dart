import 'package:flutter/material.dart';

/// A centered heart that bursts and fades when [trigger] is incremented.
///
/// Used for the double-tap-to-like gesture on posts and reels.
class LikeHeart extends StatefulWidget {
  const LikeHeart({super.key, required this.trigger, this.size = 110});

  final int trigger;
  final double size;

  @override
  State<LikeHeart> createState() => _LikeHeartState();
}

class _LikeHeartState extends State<LikeHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final CurvedAnimation _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
    reverseCurve: Curves.easeIn,
  );

  @override
  void didUpdateWidget(covariant LikeHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          return Opacity(
            opacity: (1 - progress).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value,
              child: Icon(
                Icons.favorite_rounded,
                size: widget.size,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 18),
                  Shadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
