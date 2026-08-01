import 'package:flutter/material.dart';

/// Weekly platform growth data.
class AdminGrowthPoint {
  const AdminGrowthPoint(this.week, this.members);

  final String week;
  final double members; // count

  factory AdminGrowthPoint.fromApi(Map<String, dynamic> json) {
    return AdminGrowthPoint(
      (json['week'] as String?) ?? 'W?',
      ((json['members'] as num?) ?? 0).toDouble(),
    );
  }
}

/// A top community row.
class AdminCommunity {
  const AdminCommunity(this.name, this.members, this.health, this.color);

  final String name;
  final int members;
  final int health; // community health %
  final Color color;

  factory AdminCommunity.fromApi(Map<String, dynamic> json, Color color) {
    return AdminCommunity(
      (json['name'] as String?) ?? 'Community',
      ((json['members'] as num?) ?? 0).toInt(),
      ((json['health'] as num?) ?? 90).toInt(),
      color,
    );
  }
}

/// Platform stats from GET /admin/stats.
class AdminStats {
  const AdminStats({
    this.users = 0,
    this.posts = 0,
    this.openReports = 0,
    this.follows = 0,
    this.trustResults = 0,
    this.notifications = 0,
    this.growth = const [],
    this.topUsers = const [],
  });

  final int users;
  final int posts;
  final int openReports;
  final int follows;
  final int trustResults;
  final int notifications;
  final List<AdminGrowthPoint> growth;
  final List<Map<String, dynamic>> topUsers;

  factory AdminStats.fromApi(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map<String, dynamic>?) ?? const {};
    return AdminStats(
      users: ((stats['users'] as num?) ?? 0).toInt(),
      posts: ((stats['posts'] as num?) ?? 0).toInt(),
      openReports: ((stats['openReports'] as num?) ?? 0).toInt(),
      follows: ((stats['follows'] as num?) ?? 0).toInt(),
      trustResults: ((stats['trustResults'] as num?) ?? 0).toInt(),
      notifications: ((stats['notifications'] as num?) ?? 0).toInt(),
      growth: (json['growth'] as List?)
              ?.map((g) => AdminGrowthPoint.fromApi(g as Map<String, dynamic>))
              .toList() ??
          const [],
      topUsers: (json['topUsers'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
    );
  }
}
