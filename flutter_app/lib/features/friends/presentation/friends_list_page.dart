import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/friends/state/friend_provider.dart';
import 'package:flutter_app/features/friends/presentation/friend_updates_page.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 获取好友列表
      final friendProvider = FriendProvider.of(context);
      friendProvider.getFriends();
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);

    return friendProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : friendProvider.errorMessage != null
            ? Center(child: Text(friendProvider.errorMessage!))
            : ListView.builder(
                itemCount: friendProvider.friends.length,
                itemBuilder: (context, index) {
                  final friend = friendProvider.friends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: friend.friendAvatar.isNotEmpty
                          ? NetworkImage(friend.friendAvatar)
                          : null,
                      child: friend.friendAvatar.isEmpty
                          ? Text(friend.friendName.substring(0, 1))
                          : null,
                    ),
                    title: Text(friend.friendName),
                    subtitle: Text('添加时间：${friend.createdAt.toString().split(' ')[0]}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendUpdatesPage(friend: friend),
                        ),
                      );
                    },
                  );
                },
              );
  }
}
