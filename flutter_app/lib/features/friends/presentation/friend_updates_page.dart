import 'package:flutter/material.dart';
import 'package:flutter_app/features/friends/state/friend_provider.dart';

class FriendUpdatesPage extends StatefulWidget {
  final Friend friend;
  const FriendUpdatesPage({super.key, required this.friend});

  @override
  State<FriendUpdatesPage> createState() => _FriendUpdatesPageState();
}

class _FriendUpdatesPageState extends State<FriendUpdatesPage> {
  List<dynamic> _updates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoading = true;
    });

    final friendProvider = FriendProvider.of(context);
    final updates = await friendProvider.getFriendUpdates();

    setState(() {
      _updates = updates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _updates.isEmpty
        ? const Center(child: Text('暂无动态'))
        : ListView.builder(
            itemCount: _updates.length,
            itemBuilder: (context, index) {
              final update = _updates[index];
              return ListTile(
                title: Text('今日照片'),
                subtitle: Text(
                  '拍摄时间：${DateTime.now().toString().split(' ')[0]}',
                ),
                leading: const Icon(Icons.photo),
              );
            },
          );
  }
}
