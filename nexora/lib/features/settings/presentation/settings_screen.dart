import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isModerator = user?.isModerator ?? false;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Appearance',
              children: [
                _SettingTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Theme',
                  subtitle: 'Choose how Nexora looks',
                  onTap: () => _showThemeSheet(context, ref),
                ),
              ],
            ),
            _Section(
              title: 'Account',
              children: [
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  onTap: () => context.push(Routes.editProfile),
                ),
                _SettingTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved',
                  onTap: () => context.push(Routes.profile),
                ),
                _SettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy',
                  subtitle: 'How your data is protected',
                  onTap: () => _showPrivacy(context),
                ),
                _SettingTile(
                  icon: Icons.block_rounded,
                  title: 'Blocked accounts',
                  subtitle: 'Manage your boundaries',
                  onTap: () => _showBlocked(context, ref),
                ),
              ],
            ),
            _Section(
              title: 'Community',
              children: [
                _SettingTile(
                  icon: Icons.shield_outlined,
                  title: 'Trust Center',
                  subtitle: 'Score, label & history',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.trustCenter),
                ),
                if (isModerator)
                  _SettingTile(
                    icon: Icons.gavel_rounded,
                    title: 'Moderator dashboard',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.moderator),
                  ),
                if (isAdmin)
                  _SettingTile(
                    icon: Icons.space_dashboard_rounded,
                    title: 'Admin dashboard',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.admin),
                  ),
              ],
            ),
            _Section(
              title: 'About',
              children: [
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Nexora',
                  subtitle: 'v1.0.0 · The Next Generation of Connected Communities',
                  onTap: () => _showAbout(context),
                ),
                _SettingTile(
                  icon: Icons.description_outlined,
                  title: 'Community Guidelines',
                  onTap: () => _showGuidelines(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(4),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, color: AppColors.trustRed),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.trustRed, fontWeight: FontWeight.w800),
                ),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go(Routes.login);
                },
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Nexora • Built on trust 🤝',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final mode = ref.watch(themeModeProvider);
        return SafeArea(
          child: RadioGroup<AppThemeMode>(
            groupValue: mode,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).setMode(v);
                Navigator.of(sheetContext).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Theme',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const RadioListTile<AppThemeMode>(
                  value: AppThemeMode.system,
                  title: Text('System default'),
                ),
                const RadioListTile<AppThemeMode>(
                  value: AppThemeMode.light,
                  title: Text('Light'),
                ),
                const RadioListTile<AppThemeMode>(
                  value: AppThemeMode.dark,
                  title: Text('Dark'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _InfoSheet(
        icon: Icons.lock_outline_rounded,
        title: 'Privacy at Nexora',
        paragraphs: [
          'Your account is protected with JWT-based authentication. Passwords are stored as bcrypt hashes and never shared.',
          'Your Trust Score is computed from real AI analysis of your posts plus fact-check evidence. It is visible to the community by design — that is how trust works here.',
          'Media you upload (posts, stories, avatars) is stored on Cloudinary. You can delete your posts at any time, which also removes their media.',
          'Real-time notifications and chat run through an encrypted Socket.IO connection tied to your session.',
        ],
      ),
    );
  }

  Future<void> _showBlocked(BuildContext context, WidgetRef ref) async {
    List<User> blocked = const [];
    try {
      final json = await ref.read(apiClientProvider).get('/users/blocked');
      blocked = ((json as Map<String, dynamic>?)?['data'] as List? ?? const [])
          .map((u) => User.fromApi(u as Map<String, dynamic>))
          .toList();
    } catch (_) {/* empty state */}
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _BlockedSheet(blocked: blocked),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _InfoSheet(
        icon: Icons.auto_awesome_rounded,
        title: 'About Nexora',
        paragraphs: [
          'Nexora is a trust-first social platform. Every post is analysed by an AI pipeline and receives a Trust Score with a colour-coded label, so the community can see what is verified, vetted or under watch.',
          'Version 1.0.0 · Flutter frontend, Node.js + Express API, MongoDB Atlas, Cloudinary media, Gemini-powered fact-checking.',
        ],
      ),
    );
  }

  void _showGuidelines(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _InfoSheet(
        icon: Icons.description_outlined,
        title: 'Community Guidelines',
        paragraphs: [
          '1. Be honest. False reports, impersonation and fabricated claims lower your Trust Score.',
          '2. Be kind. Harassment, hate speech and doxxing lead to moderation action.',
          '3. Share real content. Misinformation is flagged by the AI fact-checking pipeline.',
          '4. Respect boundaries. Blocked or reported members are reviewed by moderators.',
          '5. Build trust. Verified members with high scores gain reach and community tools.',
        ],
      ),
    );
  }
}

/// Shared bottom-sheet for informational pages (Privacy / About / Guidelines).
class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in paragraphs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocked-accounts list backed by `GET /users/blocked`, with unblock.
class _BlockedSheet extends ConsumerStatefulWidget {
  const _BlockedSheet({required this.blocked});

  final List<User> blocked;

  @override
  ConsumerState<_BlockedSheet> createState() => _BlockedSheetState();
}

class _BlockedSheetState extends ConsumerState<_BlockedSheet> {
  late List<User> _blocked = widget.blocked;
  bool _loading = false;

  Future<void> _unblock(User user) async {
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).post('/users/${user.id}/block');
      if (!mounted) return;
      setState(() {
        _blocked = [
          for (final u in _blocked)
            if (u.id != user.id) u,
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Text(
                    'Blocked accounts',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _blocked.isEmpty
                  ? Center(
                      child: Text(
                        'You have not blocked anyone.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: _blocked.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final user = _blocked[index];
                        return ListTile(
                          leading: NexoraAvatar(
                            imageUrl: user.avatarUrl,
                            fallbackText: user.username,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TrustBadge(label: user.effectiveTrustLabel, compact: true),
                            ],
                          ),
                          subtitle: Text('@${user.username}'),
                          trailing: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: () => _unblock(user),
                                  child: const Text('Unblock'),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        NexoraCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          borderRadius: BorderRadius.circular(18),
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
