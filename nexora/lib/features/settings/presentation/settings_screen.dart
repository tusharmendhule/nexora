import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../shared/widgets/common.dart';
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
                  subtitle: 'Who can see your activity',
                  onTap: () => _comingSoon(context),
                ),
                _SettingTile(
                  icon: Icons.block_rounded,
                  title: 'Blocked accounts',
                  subtitle: 'Manage your boundaries',
                  onTap: () => _comingSoon(context),
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
                  onTap: () => _comingSoon(context),
                ),
                _SettingTile(
                  icon: Icons.description_outlined,
                  title: 'Community Guidelines',
                  onTap: () => _comingSoon(context),
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

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This will be fully wired up with the backend 🔌'),
        behavior: SnackBarBehavior.floating,
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
