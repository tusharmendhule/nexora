import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../../auth/presentation/auth_provider.dart';
import 'profile_providers.dart';

/// Which relationship a profile sheet is showing.
enum FollowListMode { followers, following }

extension FollowListModeX on FollowListMode {
  String get apiPath => this == FollowListMode.followers ? 'followers' : 'following';

  String get title => this == FollowListMode.followers ? 'Followers' : 'Following';
}

/// Bottom sheet backed by the real `GET /users/:id/followers|following` API.
///
/// Rows show the member's trust badge and a live Follow/Following toggle;
/// tapping a row opens that member's profile. Follow-state changes refresh
/// the profile counts via [profileProvider].
class FollowListSheet extends ConsumerStatefulWidget {
  const FollowListSheet({super.key, required this.userId, required this.mode});

  final String userId;
  final FollowListMode mode;

  @override
  ConsumerState<FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends ConsumerState<FollowListSheet> {
  List<User> _users = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json =
          await ref.read(apiClientProvider).get('/users/${widget.userId}/${widget.mode.apiPath}');
      final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _users = data.map((u) => User.fromApi(u as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load ${widget.mode.title.toLowerCase()}.';
      });
    }
  }

  /// Optimistically toggle follow for a listed member and sync counts.
  Future<void> _toggleFollow(User user) async {
    if (_busyId != null) return;
    final next = !user.isFollowing;
    setState(() {
      _busyId = user.id;
      _users = [
        for (final u in _users)
          if (u.id == user.id)
            u.copyWith(
              isFollowing: next,
              followers: u.followers + (next ? 1 : -1),
            )
          else
            u,
      ];
    });
    try {
      await ref.read(apiClientProvider).post('/users/${user.id}/follow');
      if (!mounted) return;
      setState(() => _busyId = null);
      // Refresh the profile so its Followers/Following counters stay correct.
      ref.read(profileProvider.notifier).load(widget.userId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _users = [
          for (final u in _users)
            if (u.id == user.id)
              u.copyWith(
                isFollowing: !next,
                followers: u.followers + (next ? -1 : 1),
              )
            else
              u,
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The signed-in member — never show a Follow button on their own row.
    final selfId = ref.read(authProvider).user?.id;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
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
                    widget.mode.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (!_loading) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${_users.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
              child: _buildBody(scheme, selfId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme, String? selfId) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_users.isEmpty) {
      return EmptyState(
        icon: widget.mode == FollowListMode.followers
            ? Icons.people_outline_rounded
            : Icons.person_outline_rounded,
        title: 'No ${widget.mode.title.toLowerCase()} yet',
        subtitle: widget.mode == FollowListMode.followers
            ? 'When people follow this account, they will show up here.'
            : 'This account is not following anyone yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isSelf = user.id == selfId;
        return ListTile(
          onTap: () {
            if (isSelf) return;
            // Capture the router first — the sheet's own context is invalid
            // after its route is popped.
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push(Routes.profilePath(user.id));
          },
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
          trailing: isSelf
              ? null
              : _FollowButton(
                  isFollowing: user.isFollowing,
                  busy: _busyId == user.id,
                  onPressed: () => _toggleFollow(user),
                ),
        );
      },
    );
  }
}

/// Small gradient Follow / outlined Following toggle used in the list.
class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.busy,
    required this.onPressed,
  });

  final bool isFollowing;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (busy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isFollowing) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(92, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurfaceVariant,
        ),
        child: const Text('Following', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradientDeep,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(99),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(
              'Follow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
