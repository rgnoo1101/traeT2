import 'package:flutter/material.dart';
import 'package:flutter_app/features/match/state/match_provider.dart';
import 'package:flutter_app/features/capture/state/daily_flow_provider.dart';

class MatchWaitingPage extends StatefulWidget {
  const MatchWaitingPage({super.key});

  @override
  State<MatchWaitingPage> createState() => _MatchWaitingPageState();
}

class _MatchWaitingPageState extends State<MatchWaitingPage> {
  @override
  void initState() {
    super.initState();
    // 定期检查匹配状态
    _checkMatchStatus();
  }

  Future<void> _checkMatchStatus() async {
    final matchProvider = MatchProvider.of(context);
    final dailyFlowProvider = DailyFlowProvider.of(context);

    // 模拟匹配过程，实际应该通过API轮询或WebSocket
    await Future.delayed(const Duration(seconds: 5));

    // 模拟匹配成功
    await matchProvider.getCurrentSession();
    dailyFlowProvider.markAsMatched();
    dailyFlowProvider.startViewingCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('正在为您寻找匹配对象...', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('请耐心等待', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
