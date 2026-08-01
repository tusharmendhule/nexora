import 'package:flutter/material.dart';

import '../../../core/models/user.dart';

/// Severity/icon mapping for report reasons coming from the API.
class ReportReason {
  const ReportReason._(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  static const Map<String, ReportReason> _byKey = {
    'spam': ReportReason._('spam', 'Spam or misleading', Icons.campaign_outlined, Color(0xFFF97316)),
    'harassment': ReportReason._('harassment', 'Harassment or hate', Icons.report_gmailerrorred_rounded, Color(0xFFEF4444)),
    'violence': ReportReason._('violence', 'Violent content', Icons.health_and_safety_outlined, Color(0xFFEF4444)),
    'impersonation': ReportReason._('impersonation', 'Impersonation', Icons.badge_outlined, Color(0xFF3B82F6)),
    'misinformation': ReportReason._('misinformation', 'Misinformation', Icons.help_outline_rounded, Color(0xFFF59E0B)),
    'other': ReportReason._('other', 'Other', Icons.flag_outlined, Color(0xFFA855F7)),
  };

  static ReportReason fromKey(String? key) => _byKey[key] ?? _byKey['other']!;

  static const List<ReportReason> values = [
    ReportReason._('spam', 'Spam or misleading', Icons.campaign_outlined, Color(0xFFF97316)),
    ReportReason._('harassment', 'Harassment or hate', Icons.report_gmailerrorred_rounded, Color(0xFFEF4444)),
    ReportReason._('violence', 'Violent content', Icons.health_and_safety_outlined, Color(0xFFEF4444)),
    ReportReason._('impersonation', 'Impersonation', Icons.badge_outlined, Color(0xFF3B82F6)),
    ReportReason._('other', 'Other', Icons.flag_outlined, Color(0xFFA855F7)),
  ];
}

class ModerationItem {
  const ModerationItem({
    required this.id,
    required this.reportId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.reportedUser,
    this.reporter,
    this.preview = '',
    this.caption = '',
    required this.reportedAt,
    this.severity = 1,
  });

  final String id;
  final String reportId;
  final String targetId;
  final String targetType;
  final String reason;
  final User? reportedUser;
  final User? reporter;
  final String preview;
  final String caption;
  final DateTime reportedAt;
  final int severity; // 1-3

  ReportReason get reasonModel => ReportReason.fromKey(reason);

  factory ModerationItem.fromApi(Map<String, dynamic> json) {
    final reportedUser = json['reportedUser'] as Map<String, dynamic>?;
    final reporter = json['reporter'] as Map<String, dynamic>?;
    return ModerationItem(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      reportId: (json['reportId'] as String?) ?? '',
      targetId: (json['targetId'] as String?) ?? '',
      targetType: (json['targetType'] as String?) ?? 'post',
      reason: (json['reason'] as String?) ?? 'other',
      reportedUser: reportedUser == null ? null : User.fromApi(reportedUser),
      reporter: reporter == null ? null : User.fromApi(reporter),
      preview: (json['preview'] as String?) ?? '',
      caption: (json['caption'] as String?) ?? '',
      reportedAt:
          DateTime.tryParse((json['reportedAt'] as String?) ?? '') ??
              DateTime.now(),
      severity: ((json['severity'] as num?) ?? 1).toInt(),
    );
  }
}
