import 'package:flutter/material.dart';
import 'package:flutter_app/features/friends/state/friend_provider.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> _feedItems = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (_feedItems.isNotEmpty) return; // 避免重复加载

    setState(() {
      _isLoading = true;
    });

    final friendProvider = FriendProvider.of(context);
    final updates = await friendProvider.getFriendUpdates();

    setState(() {
      _feedItems = updates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedItems.isEmpty
              ? const Center(child: Text('暂无动态'))
              : ListView.builder(
                  itemCount: _feedItems.length,
                  itemBuilder: (context, index) {
                    final item = _feedItems[index];
                    return _buildFeedItem(item);
                  },
                ),
    );
  }

  Widget _buildFeedItem(dynamic item) {
    final timestamp = DateTime.parse(item['timestamp']);
    final formattedDate = '${timestamp.month}/${timestamp.day}/${timestamp.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标签
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 好友信息
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['friendName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '2 min ago', // 简化处理，实际应该根据时间戳计算
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 照片
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Image.network(
              item['photoUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400,
            ),
          ),
          
          //  caption
          Text(
            item['caption'],
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          // 分隔线
          Container(
            margin: const EdgeInsets.only(top: 20),
            height: 1,
            color: Colors.black12,
          ),
        ],
      ),
    );
  }
}
