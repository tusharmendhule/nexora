import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/common.dart';
import '../../auth/presentation/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _location;
  late final TextEditingController _link;
  String? _avatarUrl;
  Uint8List? _avatarBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _username = TextEditingController(text: user?.username ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
    _location = TextEditingController(text: user?.location ?? '');
    _link = TextEditingController(text: user?.link ?? '');
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _location.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _avatarBytes = bytes;
          _avatarUrl = file.path;
        });
      }
    } catch (_) {
      // Leave the current avatar untouched.
    }
  }

  Future<void> _save() async {
    setState(() => _uploading = true);
    // Upload a fresh avatar to Cloudinary first, then save the text fields.
    var ok = true;
    if (_avatarBytes != null) {
      ok = await ref.read(authProvider.notifier).uploadAvatar(_avatarBytes!);
    }
    if (ok) {
      ok = await ref.read(authProvider.notifier).updateProfile(
            name: _name.text.trim(),
            username: _username.text.trim().replaceAll('@', ''),
            bio: _bio.text.trim(),
            location: _location.text.trim(),
            link: _link.text.trim(),
          );
    }
    if (!mounted) return;
    setState(() => _uploading = false);
    if (!ok) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Could not save your profile. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated ✨'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PrimaryButton(
              label: _uploading ? 'Saving…' : 'Save',
              loading: _uploading,
              expanded: false,
              onPressed: _uploading ? null : _save,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploading ? null : _changeAvatar,
                child: Stack(
                  children: [
                    if (_avatarBytes != null)
                      ClipOval(
                        child: Image.memory(
                          _avatarBytes!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      NexoraAvatar(
                        imageUrl: _avatarUrl,
                        fallbackText: _name.text,
                        size: 96,
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to change profile photo',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bio,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _link,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 24),
              NexoraCard(
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.trustGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your Trust Label and Score can\'t be edited — they\'re earned through verified activity.',
                        style: TextStyle(fontSize: 12.5, height: 1.4, color: scheme.onSurfaceVariant),
                      ),
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
}
