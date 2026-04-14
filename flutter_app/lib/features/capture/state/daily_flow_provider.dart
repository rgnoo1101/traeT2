import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum DailyStatus {
  idle,       // 初始状态
  notified,   // 收到通知
  capturing,  // 拍摄中
  uploaded,   // 已上传
  matching,   // 匹配中
  matched,    // 已匹配
  viewing,    // 互看中
  done,       // 完成
  missed,     // 错过
}

class DailyFlowProvider extends ChangeNotifier {
  DailyStatus _status = DailyStatus.idle;
  int _countdown = 0;
  Timer? _timer;
  bool _isCountingDown = false;

  DailyStatus get status => _status;
  int get countdown => _countdown;
  bool get isCountingDown => _isCountingDown;

  // 设置状态
  void setStatus(DailyStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // 开始拍摄倒计时（2分钟）
  void startCaptureCountdown() {
    _countdown = 120; // 2分钟
    _isCountingDown = true;
    _status = DailyStatus.capturing;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _countdown--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isCountingDown = false;
        _status = DailyStatus.missed;
        notifyListeners();
      }
    });
  }

  // 开始互看倒计时（2分钟）
  void startViewingCountdown() {
    _countdown = 120; // 2分钟
    _isCountingDown = true;
    _status = DailyStatus.viewing;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _countdown--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isCountingDown = false;
        _status = DailyStatus.done;
        notifyListeners();
      }
    });
  }

  // 停止倒计时
  void stopCountdown() {
    _timer?.cancel();
    _isCountingDown = false;
    notifyListeners();
  }

  // 重置状态
  void reset() {
    _timer?.cancel();
    _status = DailyStatus.idle;
    _countdown = 0;
    _isCountingDown = false;
    notifyListeners();
  }

  // 标记为已上传
  void markAsUploaded() {
    _timer?.cancel();
    _isCountingDown = false;
    _status = DailyStatus.uploaded;
    notifyListeners();
  }

  // 标记为匹配中
  void markAsMatching() {
    _status = DailyStatus.matching;
    notifyListeners();
  }

  // 标记为已匹配
  void markAsMatched() {
    _status = DailyStatus.matched;
    notifyListeners();
  }

  // 标记为已通知
  void markAsNotified() {
    _status = DailyStatus.notified;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static DailyFlowProvider of(BuildContext context) {
    return Provider.of<DailyFlowProvider>(context, listen: false);
  }
}
