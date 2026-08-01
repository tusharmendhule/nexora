import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/models/user.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../../auth/presentation/auth_provider.dart';
import 'create_post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _caption = TextEditingController();
  final TextEditingController _tagInput = TextEditingController();
  final TextEditingController _mentionInput = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _caption.dispose();
    _tagInput.dispose();
    _mentionInput.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        ref.read(createPostProvider.notifier).addMedia(file.path, bytes: bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the gallery.')),
        );
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final file = await _picker.pickVideo(source: ImageSource.camera);
      if (file != null) {
        final bytes = await file.readAsBytes();
        ref.read(createPostProvider.notifier)
            .addMedia(file.path, isVideo: true, bytes: bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access the camera.')),
        );
      }
    }
  }

  Future<void> _publish() async {
    final notifier = ref.read(createPostProvider.notifier);
    final state = ref.read(createPostProvider);
    if (state.media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo or video to publish. 📸')),
      );
      return;
    }

    // Publishes to the API (multipart → Cloudinary) and runs the AI
    // fact-check/trust pipeline, then prepends the returned post to the feed.
    final post = await notifier.publish();
    if (post == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not publish. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Posted & AI-verified ✨ Your community sees it now 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PrimaryButton(
              label: state.isPublishing ? 'Posting…' : 'Share',
              loading: state.isPublishing,
              expanded: false,
              onPressed: state.isPublishing ? null : _publish,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mediaSection(state, scheme),
              const SizedBox(height: 20),
              Text(
                'Caption',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _caption,
                maxLines: 4,
                maxLength: 2200,
                onChanged: (v) =>
                    ref.read(createPostProvider.notifier).setCaption(v),
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              _chipField(
                controller: _tagInput,
                hint: 'Add hashtags…',
                prefix: '#',
                chips: state.hashtags.map((t) => '#$t').toList(),
                onAdd: (v) => ref.read(createPostProvider.notifier).addHashtag(v),
                onRemove: (v) =>
                    ref.read(createPostProvider.notifier).removeHashtag(v.replaceAll('#', '')),
                onChanged: (v) {
                  if (v.endsWith(' ') && v.trim().isNotEmpty) {
                    ref.read(createPostProvider.notifier).addHashtag(v);
                    _tagInput.clear();
                  }
                },
              ),
              const SizedBox(height: 12),
              _chipField(
                controller: _mentionInput,
                hint: 'Mention people…',
                prefix: '@',
                chips: state.mentions.map((m) => '@$m').toList(),
                onAdd: (v) => ref.read(createPostProvider.notifier).addMention(v),
                onRemove: (v) =>
                    ref.read(createPostProvider.notifier).removeMention(v.replaceAll('@', '')),
                onChanged: (v) {
                  if (v.endsWith(' ') && v.trim().isNotEmpty) {
                    ref.read(createPostProvider.notifier).addMention(v);
                    _mentionInput.clear();
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Location',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: state.location,
                isExpanded: true,
                hint: const Text('Add location'),
                items: AppStrings.locations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) =>
                    ref.read(createPostProvider.notifier).setLocation(v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 20),
              NexoraCard(
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.trustGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trust-check before posting',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Posts from members with a Trust Score under 40 may be reviewed by moderators first.',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    TrustBadge(
                      label: (ref.watch(authProvider).user)
                              ?.effectiveTrustLabel ??
                          TrustLabel.verified,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaSection(CreatePostState state, ColorScheme scheme) {
    if (state.media.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recordVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Record'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 16, color: AppColors.trustGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Photos & videos upload to Cloudinary and pass the AI trust check before going live.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Preview section
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              state.isVideo ? 'Video preview' : 'Preview (${state.media.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  ref.read(createPostProvider.notifier).removeMediaAt(0),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remove'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.media.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = state.media[index];
              final bytes = state.mediaBytes[item];
              final Widget preview = bytes != null
                  ? Image.memory(
                      Uint8List.fromList(bytes),
                      width: 180,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: item,
                      width: 180,
                      height: 220,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 180,
                        color: Colors.black,
                        child: const Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white, size: 40),
                      ),
                    );
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: preview,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chipField({
    required TextEditingController controller,
    required String hint,
    required String prefix,
    required List<String> chips,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  InputChip(
                    label: Text(chip),
                    onDeleted: () => onRemove(chip),
                    deleteIconColor: scheme.onSurfaceVariant,
                    backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                    side: BorderSide(color: AppColors.brand.withValues(alpha: 0.3)),
                  ),
              ],
            ),
          ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (v) {
            onAdd(v);
            controller.clear();
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            isDense: true,
          ),
        ),
      ],
    );
  }

  ColorScheme get scheme => Theme.of(context).colorScheme;
}
