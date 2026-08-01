import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen vertical reel player.
///
/// [isActive] controls autoplay — the parent (ReelsScreen) only activates the
/// visible page so only one video plays at a time.
class ReelPlayer extends StatefulWidget {
  const ReelPlayer({
    super.key,
    required this.url,
    required this.isActive,
    this.onTap,
    this.onDoubleTap,
  });

  final String url;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      _controller.setLooping(true);
      if (widget.isActive) _controller.play();
    }).catchError((Object _) {
      if (mounted) setState(() => _initialized = false);
    });
  }

  @override
  void didUpdateWidget(covariant ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_initialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          ),
        // Tap layer (pause/resume + double-tap like)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: Container(color: Colors.transparent),
        ),
        // Play indicator when paused
        if (_initialized && !_controller.value.isPlaying)
          const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: 84,
              color: Colors.white70,
              shadows: [Shadow(color: Colors.black54, blurRadius: 24)],
            ),
          ),
        // Mute toggle
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 14,
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        // Loading shimmer on the bottom while buffering
        if (_initialized && !_controller.value.isPlaying && !widget.isActive)
          const SizedBox.shrink(),
      ],
    );
  }
}
