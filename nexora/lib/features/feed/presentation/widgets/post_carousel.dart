import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Instagram-style swipeable multi-image carousel with animated dots.
class PostCarousel extends StatefulWidget {
  const PostCarousel({
    super.key,
    required this.images,
    this.height = 420,
    this.onDoubleTap,
  });

  final List<String> images;
  final double height;
  final VoidCallback? onDoubleTap;

  @override
  State<PostCarousel> createState() => _PostCarouselState();
}

class _PostCarouselState extends State<PostCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: GestureDetector(
            onDoubleTap: widget.onDoubleTap,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
