import '../../../core/models/user.dart';
import '../../feed/data/models.dart';

class Reel {
  const Reel({
    required this.id,
    required this.user,
    required this.videoUrl,
    required this.caption,
    this.music,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.plays = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.trust,
  });

  final String id;
  final User user;
  final String videoUrl;
  final String caption;
  final String? music;
  final int likes;
  final int comments;
  final int shares;
  final int plays;
  final bool isLiked;
  final bool isBookmarked;
  final TrustInfo? trust;

  factory Reel.fromApi(Map<String, dynamic> json) {
    return Reel(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      user: User.fromApi((json['user'] as Map<String, dynamic>?) ?? const {}),
      videoUrl: (json['videoUrl'] as String?) ?? '',
      caption: (json['caption'] as String?) ?? '',
      music: json['music'] as String?,
      likes: ((json['likes'] as num?) ?? 0).toInt(),
      comments: ((json['comments'] as num?) ?? 0).toInt(),
      shares: ((json['shares'] as num?) ?? 0).toInt(),
      plays: ((json['plays'] as num?) ?? 0).toInt(),
      isLiked: json['isLiked'] == true,
      isBookmarked: json['isBookmarked'] == true,
      trust: TrustInfo.fromApi(json['trust'] as Map<String, dynamic>?),
    );
  }

  Reel copyWith({
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return Reel(
      id: id,
      user: user,
      videoUrl: videoUrl,
      caption: caption,
      music: music,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares,
      plays: plays,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      trust: trust,
    );
  }
}
