import 'package:flutter/material.dart';

/// The color-coded Trust Label system — Nexora's signature feature.
///
/// Every member carries a label derived from their Trust Score and community
/// history. Colors stay constant across light/dark mode.
enum TrustLabel {
  verified('Verified', 'Fully verified identity & history', Color(0xFF22C55E)),
  vetted('Vetted', 'Vetted by community moderators', Color(0xFF3B82F6)),
  premium('Premium', 'Premium creator membership', Color(0xFFA855F7)),
  watch('Watch', 'Under review — activity is monitored', Color(0xFFF97316)),
  restricted('Restricted', 'Limited privileges in the community', Color(0xFFEF4444));

  const TrustLabel(this.label, this.description, this.color);

  final String label;
  final String description;
  final Color color;

  /// Maps a trust score to the appropriate label.
  static TrustLabel fromScore(double score) {
    if (score >= 85) return TrustLabel.verified;
    if (score >= 70) return TrustLabel.vetted;
    if (score >= 55) return TrustLabel.premium;
    if (score >= 40) return TrustLabel.watch;
    return TrustLabel.restricted;
  }
}

/// A badge unlocked by members as their trust grows.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = true,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
}

/// A Nexora member.
class User {
  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.avatarUrl,
    this.coverUrl,
    this.bio = '',
    this.location = '',
    this.link = '',
    this.trustScore = 50,
    this.trustLabel,
    this.isAiVerified = false,
    this.isModerator = false,
    this.isAdmin = false,
    this.isFollowing = false,
    this.isOnline = false,
    this.isBlocked = false,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.reels = 0,
    this.saved = 0,
    this.achievements = const [],
  });

  final String id;
  final String username;
  final String name;
  final String avatarUrl;
  final String? coverUrl;
  final String bio;
  final String location;
  final String link;
  final double trustScore;
  final TrustLabel? trustLabel;
  final bool isAiVerified;
  final bool isModerator;
  final bool isAdmin;
  final bool isFollowing;
  final bool isOnline;
  final bool isBlocked;
  final int followers;
  final int following;
  final int posts;
  final int reels;
  final int saved;
  final List<Achievement> achievements;

  TrustLabel get effectiveTrustLabel => trustLabel ?? TrustLabel.fromScore(trustScore);

  /// Maps a Nexora API user document to the app's [User] model.
  factory User.fromApi(Map<String, dynamic> json) {
    final email = (json['email'] as String?) ?? '';
    final fallbackUsername =
        email.isNotEmpty ? email.split('@').first : 'nexora_member';
    return User(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      username: (json['username'] as String?) ?? fallbackUsername,
      name: (json['name'] as String?) ?? 'Nexora member',
      avatarUrl: (json['avatar'] as String?) ??
          'https://i.pravatar.cc/300?img=47',
      coverUrl: json['coverUrl'] as String?,
      bio: (json['bio'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      link: (json['link'] as String?) ?? '',
      trustScore: ((json['trustScore'] as num?) ?? 50).toDouble(),
      trustLabel: _trustLabelFromApi(json['trustLabel'] as String?),
      isAiVerified: json['isVerified'] == true || json['isAiVerified'] == true,
      isAdmin: json['role'] == 'admin',
      isModerator: json['role'] == 'moderator',
      isFollowing: json['isFollowing'] == true,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      posts: (json['posts'] as num?)?.toInt() ?? 0,
      reels: (json['reels'] as num?)?.toInt() ?? 0,
      saved: (json['saved'] as num?)?.toInt() ?? 0,
    );
  }

  static TrustLabel? _trustLabelFromApi(String? label) {
    switch (label) {
      case 'Verified':
        return TrustLabel.verified;
      case 'Vetted':
        return TrustLabel.vetted;
      case 'Premium':
        return TrustLabel.premium;
      case 'Watch':
        return TrustLabel.watch;
      case 'Restricted':
        return TrustLabel.restricted;
      default:
        return null;
    }
  }

  User copyWith({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? link,
    String? avatarUrl,
    String? coverUrl,
    double? trustScore,
    bool? isAiVerified,
    bool? isModerator,
    bool? isAdmin,
    bool? isFollowing,
    bool? isOnline,
    bool? isBlocked,
    int? followers,
    int? following,
    int? posts,
    int? reels,
    int? saved,
    List<Achievement>? achievements,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      link: link ?? this.link,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      trustScore: trustScore ?? this.trustScore,
      trustLabel: trustLabel,
      isAiVerified: isAiVerified ?? this.isAiVerified,
      isModerator: isModerator ?? this.isModerator,
      isAdmin: isAdmin ?? this.isAdmin,
      isFollowing: isFollowing ?? this.isFollowing,
      isOnline: isOnline ?? this.isOnline,
      isBlocked: isBlocked ?? this.isBlocked,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      reels: reels ?? this.reels,
      saved: saved ?? this.saved,
      achievements: achievements ?? this.achievements,
    );
  }
}
