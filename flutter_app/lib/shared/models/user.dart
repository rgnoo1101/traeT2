class User {
  final String uid;
  final String nickname;
  final String avatarUrl;
  final String timezone;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  User({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    required this.timezone,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      timezone: json['timezone'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }
}
