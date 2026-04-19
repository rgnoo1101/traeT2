import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/auth/state/auth_provider.dart';
import 'package:flutter_app/features/capture/state/daily_flow_provider.dart';
import 'package:flutter_app/features/capture/presentation/capture_page.dart';
import 'package:flutter_app/features/match/presentation/match_waiting_page.dart';
import 'package:flutter_app/features/match/presentation/viewing_page.dart';
import 'package:flutter_app/features/friends/presentation/friends_list_page.dart';
import 'package:flutter_app/features/friends/presentation/feed_page.dart';
import 'package:flutter_app/features/chat/presentation/chat_list_page.dart';
import 'package:flutter_app/features/album/presentation/album_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.grey), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.feed, color: Colors.grey), label: '动态'),
          BottomNavigationBarItem(icon: Icon(Icons.people, color: Colors.grey), label: '好友'),
          BottomNavigationBarItem(icon: Icon(Icons.chat, color: Colors.grey), label: '聊天'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_album, color: Colors.grey), label: '相簿'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeContent();
      case 1:
        return const FeedPage();
      case 2:
        return const FriendsListPage();
      case 3:
        return const ChatListPage();
      case 4:
        return const AlbumPage();
      default:
        return const HomeContent();
    }
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final dailyFlowProvider = Provider.of<DailyFlowProvider>(context);

    switch (dailyFlowProvider.status) {
      case DailyStatus.idle:
        return _buildIdleState(context);
      case DailyStatus.notified:
        return _buildNotifiedState(dailyFlowProvider);
      case DailyStatus.capturing:
        return CapturePage();
      case DailyStatus.uploaded:
        return _buildUploadedState();
      case DailyStatus.matching:
        return const MatchWaitingPage();
      case DailyStatus.matched:
        return _buildMatchedState();
      case DailyStatus.viewing:
        return ViewingPage();
      case DailyStatus.done:
        return _buildDoneState();
      case DailyStatus.missed:
        return _buildMissedState();
      default:
        return _buildIdleState(context);
    }
  }

  Widget _buildIdleState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 64, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('等待今日拍摄通知', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          const Text('系统将在每天随机时间发送拍摄通知', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          // 测试按钮
          ElevatedButton(
            onPressed: () {
              final dailyFlowProvider = DailyFlowProvider.of(context);
              dailyFlowProvider.markAsNotified();
            },
            child: const Text('测试：模拟收到拍摄通知'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifiedState(DailyFlowProvider dailyFlowProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.blue),
          const SizedBox(height: 20),
          const Text('拍摄通知', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          const Text('请在2分钟内完成拍摄', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              dailyFlowProvider.startCaptureCountdown();
            },
            child: const Text('开始拍摄'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, size: 64, color: Colors.green),
          SizedBox(height: 20),
          Text('上传成功', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('正在等待匹配...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMatchedState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.purple),
          SizedBox(height: 20),
          Text('匹配成功', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('准备进入互看环节', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDoneState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 20),
          Text('今日任务完成', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('明天再来吧！', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMissedState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 20),
          Text('拍摄超时', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('请等待明天的拍摄通知', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

