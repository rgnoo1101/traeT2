import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/shared/services/api_service.dart';

class Friend {
  final String friendshipId;
  final String friendUid;
  final String friendName;
  final String friendAvatar;
  final DateTime createdAt;

  Friend({
    required this.friendshipId,
    required this.friendUid,
    required this.friendName,
    required this.friendAvatar,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendshipId: json['friendshipId'] ?? '',
      friendUid: json['friendUid'] ?? '',
      friendName: json['friendName'] ?? '',
      friendAvatar: json['friendAvatar'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class FriendProvider extends ChangeNotifier {
  List<Friend> _friends = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Friend> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 获取好友列表
  Future<void> getFriends() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      // 模拟API调用延迟
      await Future.delayed(const Duration(seconds: 1));
      
      // 添加测试数据
      _friends = [
        Friend(
          friendshipId: '1',
          friendUid: 'user1',
          friendName: '张三',
          friendAvatar: '',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        Friend(
          friendshipId: '2',
          friendUid: 'user2',
          friendName: '李四',
          friendAvatar: '',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        Friend(
          friendshipId: '3',
          friendUid: 'user3',
          friendName: '王五',
          friendAvatar: '',
          createdAt: DateTime.now().subtract(const Duration(days: 21)),
        ),
      ];
    } catch (e) {
      _errorMessage = '获取好友列表失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 模拟获取好友动态
  Future<List<dynamic>> getFriendUpdates() async {
    // 实际应该调用API获取好友的最新照片
    await Future.delayed(Duration(seconds: 1));
    // 添加测试数据
    return [
      {
        'id': '1',
        'friendId': 'user1',
        'friendName': '张三',
        'friendAvatar': '',
        'photoUrl': 'https://picsum.photos/seed/friend1/400/600',
        'caption': 'The distance of the planet at 5:30 AM. A reminder that some things are permanent.',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': '2',
        'friendId': 'user2',
        'friendName': '李四',
        'friendAvatar': '',
        'photoUrl': 'https://picsum.photos/seed/friend2/400/600',
        'caption': 'To truly only with nature can one archived for more than a second.',
        'timestamp': DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': '3',
        'friendId': 'user3',
        'friendName': '王五',
        'friendAvatar': '',
        'photoUrl': 'https://picsum.photos/seed/friend3/400/600',
        'caption': 'Coastal Archives: documenting the transient coastal light as it swept today.',
        'timestamp': DateTime.now().subtract(Duration(hours: 8)).toIso8601String(),
      },
    ];
  }

  static FriendProvider of(BuildContext context) {
    return Provider.of<FriendProvider>(context, listen: false);
  }
}
