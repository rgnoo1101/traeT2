import 'package:flutter/material.dart';
import 'package:flutter_app/features/friends/state/friend_provider.dart';

// --- 優化 A: 定義資料模型 (Data Model) ---
// 未來串接 API 時，只需修改這個 class 的 fromJson 方法
class Post {
  final String id;
  final String friendName;
  final String photoUrl;
  final String caption;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.friendName,
    required this.photoUrl,
    required this.caption,
    required this.timestamp,
  });

  // 工廠方法：將 API 回傳的 JSON 轉換為物件
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      friendName: json['friendName'] ?? 'UNKNOWN',
      photoUrl: json['photoUrl'] ?? '',
      caption: json['caption'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> _feedItems = []; // 改為強型別 List
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (_feedItems.isNotEmpty) return;

    setState(() => _isLoading = true);

    try {
      final friendProvider = FriendProvider.of(context);
      final rawUpdates = await friendProvider.getFriendUpdates();
      
      // 優化：在此處將原始資料轉換為模型物件
      setState(() {
        _feedItems = rawUpdates.map((data) => Post.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Feed Loading Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : RefreshIndicator( // 優化：增加下拉刷新功能
                onRefresh: () async {
                  _feedItems.clear();
                  await _loadFeed();
                },
                color: Colors.black,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  itemCount: _feedItems.length,
                  itemBuilder: (context, index) {
                    return PolaroidPostCard(post: _feedItems[index]);
                  },
                ),
              ),
      ),
    );
  }
}

// --- 優化 B: 獨立的拍立得組件 (Polaroid Card) ---
class PolaroidPostCard extends StatelessWidget {
  final Post post;

  const PolaroidPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${post.timestamp.year}.${post.timestamp.month}.${post.timestamp.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 頂部好友資訊
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black.withOpacity(0.05),
                  child: const Icon(Icons.person, size: 16, color: Colors.black26),
                ),
                const SizedBox(width: 10),
                Text(
                  post.friendName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Text(
                  'JUST NOW', 
                  style: TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // 拍立得相框
          LayoutBuilder(
            builder: (context, constraints) {
              final double frameWidth = constraints.maxWidth * 0.85;
              final double frameHeight = frameWidth * 1.5;
              final double photoWidth = frameWidth - 32;
              final double photoHeight = photoWidth * (4 / 3);
              
              return Container(
                width: frameWidth,
                height: frameHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // 照片內容
                    SizedBox(
                      width: photoWidth,
                      height: photoHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: Image.network(
                          post.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.black12,
                            child: const Icon(Icons.broken_image, color: Colors.white30),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 底部手寫感文字
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                      child: Column(
                        children: [
                          Text(
                            post.caption,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              color: Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.black12,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}