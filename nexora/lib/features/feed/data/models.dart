import '../../../core/models/user.dart';

/// One of the six AI content checks (fake news, hate speech, toxic language,
/// clickbait, spam, offensive content) with its risk score + level.
class ContentCheck {
  const ContentCheck({
    required this.name,
    this.label = '',
    this.score = 0,
    this.level = 'none',
    this.flags = const [],
    this.detail = '',
  });

  final String name;
  final String label;
  final double score; // risk probability 0-100
  final String level; // none | low | medium | high
  final List<String> flags; // matched signals
  final String detail;

  bool get isFlagged => level != 'none';
  bool get isHigh => level == 'high';

  factory ContentCheck.fromApi(Map<String, dynamic>? json) {
    if (json == null) return const ContentCheck(name: '');
    return ContentCheck(
      name: (json['name'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      score: ((json['score'] as num?) ?? 0).toDouble(),
      level: (json['level'] as String?) ?? 'none',
      flags: (json['flags'] as List?)?.cast<String>() ?? const [],
      detail: (json['detail'] as String?) ?? '',
    );
  }
}

/// Trust result attached to a post (score + color label + factors + evidence).
class TrustInfo {
  const TrustInfo({
    required this.score,
    required this.label,
    this.factors = const [],
    this.factChecks = const [],
    this.checks = const [],
    this.status = 'pending',
  });

  final double score;
  final String label; // Verified | Vetted | Premium | Watch | Restricted
  final List<Map<String, dynamic>> factors;
  final List<Map<String, dynamic>> factChecks;

  /// The six AI content checks with per-category risk levels.
  final List<ContentCheck> checks;

  final String status;

  /// Checks that did NOT pass (level low/medium/high) — the reason a post may
  /// have been flagged.
  List<ContentCheck> get flaggedChecks =>
      checks.where((c) => c.isFlagged).toList();

  TrustLabel get trustLabel {
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
        return TrustLabel.fromScore(score);
    }
  }

  factory TrustInfo.fromApi(Map<String, dynamic>? json) {
    if (json == null) return const TrustInfo(score: 50, label: 'Watch');
    return TrustInfo(
      score: ((json['score'] as num?) ?? 50).toDouble(),
      label: (json['label'] as String?) ?? 'Watch',
      factors: (json['factors'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
      factChecks:
          (json['factChecks'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
      checks: (json['checks'] as List?)
              ?.map((c) => ContentCheck.fromApi(c as Map<String, dynamic>?))
              .toList() ??
          const [],
      status: (json['status'] as String?) ?? 'pending',
    );
  }
}

class Comment {
  const Comment({
    required this.id,
    required this.author,
    required this.text,
    this.likes = 0,
    required this.createdAt,
  });

  final String id;
  final User author;
  final String text;
  final int likes;
  final DateTime createdAt;

  factory Comment.fromApi(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      author: User.fromApi((json['author'] as Map<String, dynamic>?) ?? const {}),
      text: (json['text'] as String?) ?? '',
      likes: ((json['likes'] as num?) ?? 0).toInt(),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
              DateTime.now(),
    );
  }
}

class Story {
  const Story({
    required this.id,
    required this.user,
    required this.imageUrl,
    this.caption,
    this.isSeen = false,
    this.isMine = false,
  });

  final String id;
  final User user;
  final String imageUrl;
  final String? caption;
  final bool isSeen;
  final bool isMine;

  factory Story.fromApi(Map<String, dynamic> json) {
    return Story(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      user: User.fromApi((json['user'] as Map<String, dynamic>?) ?? const {}),
      imageUrl: (json['imageUrl'] as String?) ?? '',
      caption: json['caption'] as String?,
      isMine: json['isMine'] == true,
    );
  }
}

class Post {
  const Post({
    required this.id,
    required this.author,
    required this.caption,
    this.images = const [],
    this.videoUrl,
    this.location,
    this.hashtags = const [],
    this.mentions = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.bookmarks = 0,
    this.views = 0,
    required this.createdAt,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isMine = false,
    this.isAiVerified = false,
    this.trust,
  });

  final String id;
  final User author;
  final String caption;
  final List<String> images;
  final String? videoUrl;
  final String? location;
  final List<String> hashtags;
  final List<String> mentions;
  final int likes;
  final int comments;
  final int shares;
  final int bookmarks;
  final int views;
  final DateTime createdAt;
  final bool isLiked;
  final bool isBookmarked;
  final bool isMine;

  /// True when this post passed Nexora's AI content review.
  final bool isAiVerified;

  /// Nexora trust analysis (score + color-coded label + evidence).
  final TrustInfo? trust;

  bool get isVideo => videoUrl != null;
  bool get isCarousel => images.length > 1;

  /// The single image (or video) used as this post's grid thumbnail, or
  /// null for text-only posts. Guards against calling `images.first` on an
  /// empty list — the crash that used to take down the feed.
  String? get thumbnail =>
      isVideo ? videoUrl : (images.isNotEmpty ? images.first : null);

  factory Post.fromApi(Map<String, dynamic> json) {
    final media = (json['media'] as List?) ?? const [];
    final images = <String>[];
    String? videoUrl;
    for (final m in media) {
      final item = m as Map<String, dynamic>;
      final url = (item['url'] as String?) ?? '';
      if (item['type'] == 'video') {
        videoUrl ??= url;
      } else if (url.isNotEmpty) {
        images.add(url);
      }
    }
    // Fallback for legacy payloads that used a flat `images` array.
    if (images.isEmpty && json['images'] is List) {
      images.addAll((json['images'] as List).map((e) => e.toString()));
    }

    final author = User.fromApi(
      (json['author'] as Map<String, dynamic>?) ?? const {},
    );

    return Post(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      author: author,
      caption: (json['caption'] as String?) ?? '',
      images: images,
      videoUrl: videoUrl,
      location: json['location'] as String?,
      hashtags: (json['hashtags'] as List?)?.cast<String>() ?? const [],
      mentions: (json['mentions'] as List?)?.cast<String>() ?? const [],
      likes: ((json['likesCount'] as num?) ?? (json['likes'] as num?) ?? 0).toInt(),
      comments:
          ((json['commentsCount'] as num?) ?? (json['comments'] as num?) ?? 0)
              .toInt(),
      shares: ((json['sharesCount'] as num?) ?? 0).toInt(),
      bookmarks: 0,
      views: 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
              DateTime.now(),
      isLiked: json['isLiked'] == true,
      isBookmarked: json['isBookmarked'] == true,
      isMine: json['isMine'] == true,
      isAiVerified:
          json['isAiVerified'] == true ||
              (json['trust'] as Map<String, dynamic>?)?['status'] == 'verified',
      trust: TrustInfo.fromApi(json['trust'] as Map<String, dynamic>?),
    );
  }

  Post copyWith({
    User? author,
    int? likes,
    int? comments,
    int? shares,
    int? bookmarks,
    int? views,
    bool? isLiked,
    bool? isBookmarked,
    bool? isAiVerified,
    TrustInfo? trust,
  }) {
    return Post(
      id: id,
      author: author ?? this.author,
      caption: caption,
      images: images,
      videoUrl: videoUrl,
      location: location,
      hashtags: hashtags,
      mentions: mentions,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      bookmarks: bookmarks ?? this.bookmarks,
      views: views ?? this.views,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isMine: isMine,
      isAiVerified: isAiVerified ?? this.isAiVerified,
      trust: trust ?? this.trust,
    );
  }
}
