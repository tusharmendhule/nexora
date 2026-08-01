import '../../../core/models/user.dart';

enum NotificationType { like, comment, follow, mention, trust, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.user,
    required this.text,
    required this.createdAt,
    this.postPreview,
    this.isRead = false,
    this.isTrustEvent = false,
  });

  final String id;
  final NotificationType type;
  final User user;
  final String text;
  final DateTime createdAt;
  final String? postPreview;
  final bool isRead;
  final bool isTrustEvent;

  factory AppNotification.fromApi(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? 'system';
    return AppNotification(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      type: _typeFromApi(typeStr),
      user: User.fromApi((json['user'] as Map<String, dynamic>?) ?? const {}),
      text: (json['text'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
              DateTime.now(),
      postPreview: json['postPreview'] as String?,
      isRead: json['isRead'] == true,
      isTrustEvent: json['isTrustEvent'] == true,
    );
  }

  static NotificationType _typeFromApi(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'trust':
        return NotificationType.trust;
      default:
        return NotificationType.system;
    }
  }
}
