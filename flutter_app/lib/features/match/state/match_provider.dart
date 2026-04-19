import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/shared/services/api_service.dart';
import 'package:uuid/uuid.dart';

class MatchProvider extends ChangeNotifier {
  String? _sessionId;
  String? _otherUserId;
  String? _otherUserName;
  String? _otherUserAvatar;
  bool? _hasSentInvite;
  bool? _otherHasInvited;
  bool _isLoading = false;
  String? _errorMessage;

  String? get sessionId => _sessionId;
  String? get otherUserId => _otherUserId;
  String? get otherUserName => _otherUserName;
  String? get otherUserAvatar => _otherUserAvatar;
  bool? get hasSentInvite => _hasSentInvite;
  bool? get otherHasInvited => _otherHasInvited;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 获取当前匹配会话
  Future<void> getCurrentSession() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await ApiService().getCurrentSession();
      if (response.success && response.data != null) {
        final session = response.data['session'];
        _sessionId = session['sessionId'];
        // 假设当前用户是userA，需要根据实际情况判断
        _otherUserId = session['userB'];
        _hasSentInvite = session['userAInvite'];
        _otherHasInvited = session['userBInvite'];
      }
    } catch (e) {
      _errorMessage = '获取匹配会话失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 发送邀请
  Future<void> sendInvite() async {
    if (_sessionId == null) return;

    _isLoading = true;
    _errorMessage = null;

    try {
      final requestId = 'req_${const Uuid().v4()}';
      final response = await ApiService().updateInviteDecision(
        requestId,
        _sessionId!,
        'accept',
      );

      if (response.success) {
        _hasSentInvite = true;
        // 检查是否双方都已同意
        if (_otherHasInvited == true) {
          // 成为好友
          // TODO: 处理成为好友的逻辑
        }
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = '发送邀请失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 重置状态
  void reset() {
    _sessionId = null;
    _otherUserId = null;
    _otherUserName = null;
    _otherUserAvatar = null;
    _hasSentInvite = null;
    _otherHasInvited = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  static MatchProvider of(BuildContext context) {
    return Provider.of<MatchProvider>(context, listen: false);
  }
}
