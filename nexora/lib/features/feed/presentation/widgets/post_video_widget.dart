import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// In-feed video player (Instagram-style inline videos).
class PostVideo extends StatefulWidget {
  const PostVideo({
    super.key,
    required this.url,
    this.autoplay = false,
    this.allowControls = true,
    this.onDoubleTap,
  });

  final String url;
  final bool autoplay;
  final bool allowControls;
  final VoidCallback? onDoubleTap;

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
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
      if (widget.autoplay) {
        _controller.setLooping(true);
        _controller.play();
      }
    }).catchError((Object _) {
      if (mounted) setState(() => _initialized = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: _initialized ? _controller.value.aspectRatio : 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_initialized)
              VideoPlayer(_controller)
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              ),
            if (widget.allowControls && _initialized)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                onDoubleTap: widget.onDoubleTap,
                child: Container(color: Colors.transparent),
              ),
            if (_initialized && !_controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 68,
                  color: Colors.white70,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 20)],
                ),
              ),
            if (widget.allowControls && _initialized)
              Positioned(
                top: 8,
                right: 8,
                child: _GlassButton(
                  icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  onTap: _toggleMute,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap, required this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
