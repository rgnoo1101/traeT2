import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/match/state/match_provider.dart';
import 'package:flutter_app/features/capture/state/daily_flow_provider.dart';

class ViewingPage extends StatefulWidget {
  const ViewingPage({super.key});

  @override
  State<ViewingPage> createState() => _ViewingPageState();
}

class _ViewingPageState extends State<ViewingPage> {
  @override
  void initState() {
    super.initState();
    // 获取匹配会话信息
    final matchProvider = MatchProvider.of(context);
    matchProvider.getCurrentSession();
  }

  @override
  Widget build(BuildContext context) {
    final dailyFlowProvider = Provider.of<DailyFlowProvider>(context);
    final matchProvider = Provider.of<MatchProvider>(context);

    return Column(
      children: [
        // 倒计时显示
        Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Text(
            '${(dailyFlowProvider.countdown ~/ 60).toString().padLeft(2, '0')}:${(dailyFlowProvider.countdown % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ),

        // 照片显示区域
        Expanded(
          child: Row(
            children: [
              // 自己的照片
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('你的照片'),
                  ),
                ),
              ),
              // 对方的照片
              Expanded(
                child: Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Text('对方的照片'),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 按钮区域
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 提早结束按钮
              ElevatedButton.icon(
                onPressed: () {
                  final dailyFlowProvider = DailyFlowProvider.of(context);
                  dailyFlowProvider.stopCountdown();
                  dailyFlowProvider.setStatus(DailyStatus.done);
                },
                icon: const Icon(Icons.close),
                label: const Text('提早结束'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              // 邀请按钮
              matchProvider.hasSentInvite == true
                  ? const Text('已发送邀请', style: TextStyle(color: Colors.green))
                  : ElevatedButton(
                      onPressed: matchProvider.isLoading ? null : matchProvider.sendInvite,
                      child: matchProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('发起交友邀请'),
                    ),
            ],
          ),
        ),

        // 错误信息
        if (matchProvider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              matchProvider.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
