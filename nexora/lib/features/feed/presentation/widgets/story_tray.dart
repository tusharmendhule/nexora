import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/avatar.dart';
import '../../../../shared/widgets/story_ring.dart';
import '../../../../shared/widgets/trust_widgets.dart';
import '../../data/models.dart';
import '../feed_providers.dart';

class StoryTray extends ConsumerStatefulWidget {
  const StoryTray({super.key});

  @override
  ConsumerState<StoryTray> createState() => _StoryTrayState();
}

class _StoryTrayState extends ConsumerState<StoryTray> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _addStory() async {
    if (_uploading) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _uploading = true);
      final story =
          await ref.read(feedProvider.notifier).createStory(bytes);
      if (!mounted) return;
      setState(() => _uploading = false);
      if (story == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload your story. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story published — it stays live for 24 hours ✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted && _uploading) setState(() => _uploading = false);
    }
  }

  void _openViewer(BuildContext context, WidgetRef ref, int index) {
    final stories = ref.read(feedProvider).stories;
    if (stories.isEmpty) return;
    ref.read(feedProvider.notifier).markStorySeen(stories[index].id);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            StoryViewer(stories: stories, initialIndex: index),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(feedProvider.select((s) => s.stories));

    return SizedBox(
      height: 106,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // "Add story" ring — always first for the signed-in member.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              onTap: _addStory,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  StoryRing(
                    isSeen: false,
                    showAdd: true,
                    child: _uploading
                        ? Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          )
                        : NexoraAvatar(
                            imageUrl: null,
                            fallbackText: 'You',
                            size: 58,
                          ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 68,
                    child: Text(
                      'Your story',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final story in stories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () =>
                    _openViewer(context, ref, stories.indexOf(story)),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    StoryRing(
                      isSeen: story.isSeen,
                      showAdd: false,
                      child: NexoraAvatar(
                        imageUrl: story.user.avatarUrl,
                        fallbackText: story.user.username,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        story.user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen, auto-advancing story viewer.
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.stories, required this.initialIndex});

  final List<Story> stories;
  final int initialIndex;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  Timer? _timer;
  double _progress = 0;

  static const Duration _perStory = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _progress = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _progress += 100 / (_perStory.inMilliseconds / 100));
      if (_progress >= 100) _next();
    });
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    if (_index > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: stories.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _startTimer();
              },
              itemBuilder: (context, index) {
                final story = stories[index];
                final user = story.user;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: story.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.broken_image_rounded,
                            color: Colors.white38, size: 48),
                      ),
                    ),
                    // Legibility gradients
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.35, 0.7, 1],
                          colors: [
                            Colors.black87,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                        child: Column(
                          children: [
                            // Progress bars
                            Row(
                              children: List.generate(
                                stories.length,
                                (i) => Expanded(
                                  child: Container(
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: i == _index
                                        ? Align(
                                            alignment: Alignment.centerLeft,
                                            child: FractionallySizedBox(
                                              widthFactor: (_progress / 100).clamp(0.0, 1.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(99),
                                                ),
                                              ),
                                            ),
                                          )
                                        : i < _index
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white70,
                                                  borderRadius: BorderRadius.circular(99),
                                                ),
                                              )
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                NexoraAvatar(
                                  imageUrl: user.avatarUrl,
                                  fallbackText: user.username,
                                  size: 34,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  user.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'now',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                TrustBadge(label: user.effectiveTrustLabel, compact: true),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    story.isMine
                                        ? 'Tap to add to your story'
                                        : (story.caption ?? ''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
