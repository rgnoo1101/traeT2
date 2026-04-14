import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/shared/services/api_service.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  final String chatId;
  final List<String> memberUids;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String friendName;
  final String friendAvatar;

  ChatSession({
    required this.chatId,
    required this.memberUids,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.friendName,
    required this.friendAvatar,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      chatId: json['chatId'] ?? '',
      memberUids: List<String>.from(json['memberUids'] ?? []),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: DateTime.parse(
        json['lastMessageAt'] ?? DateTime.now().toIso8601String(),
      ),
      friendName: json['friendName'] ?? '',
      friendAvatar: json['friendAvatar'] ?? '',
    );
  }
}

class Message {
  final String messageId;
  final String senderUid;
  final String text;
  final DateTime sentAt;
  final bool isSentByMe;

  Message({
    required this.messageId,
    required this.senderUid,
    required this.text,
    required this.sentAt,
    required this.isSentByMe,
  });

  factory Message.fromJson(Map<String, dynamic> json, String currentUserId) {
    return Message(
      messageId: json['messageId'] ?? '',
      senderUid: json['senderUid'] ?? '',
      text: json['text'] ?? '',
      sentAt: DateTime.parse(
        json['sentAt'] ?? DateTime.now().toIso8601String(),
      ),
      isSentByMe: json['senderUid'] == currentUserId,
    );
  }
}

class ChatProvider extends ChangeNotifier {
  List<ChatSession> _chatSessions = [];
  final Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatSession> get chatSessions => _chatSessions;
  Map<String, List<Message>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 获取聊天会话列表
  Future<void> getChats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 模拟API调用延迟
      await Future.delayed(const Duration(seconds: 1));
      
      // 添加测试数据
      _chatSessions = [
        ChatSession(
          chatId: 'chat1',
          memberUids: ['current_user', 'user1'],
          lastMessage: '你好，最近怎么样？',
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
          friendName: '张三',
          friendAvatar: '',
        ),
        ChatSession(
          chatId: 'chat2',
          memberUids: ['current_user', 'user2'],
          lastMessage: '今天的拍摄很有趣！',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
          friendName: '李四',
          friendAvatar: '',
        ),
        ChatSession(
          chatId: 'chat3',
          memberUids: ['current_user', 'user3'],
          lastMessage: '明天见！',
          lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
          friendName: '王五',
          friendAvatar: '',
        ),
      ];
    } catch (e) {
      _errorMessage = '获取聊天会话失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取消息列表
  Future<void> getMessages(String chatId, String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 模拟API调用延迟
      await Future.delayed(const Duration(seconds: 1));
      
      // 添加测试数据
      _messages[chatId] = [
        Message(
          messageId: 'msg1',
          senderUid: 'user1',
          text: '你好！',
          sentAt: DateTime.now().subtract(const Duration(minutes: 10)),
          isSentByMe: false,
        ),
        Message(
          messageId: 'msg2',
          senderUid: currentUserId,
          text: '你好，最近怎么样？',
          sentAt: DateTime.now().subtract(const Duration(minutes: 9)),
          isSentByMe: true,
        ),
        Message(
          messageId: 'msg3',
          senderUid: 'user1',
          text: '我很好，谢谢！',
          sentAt: DateTime.now().subtract(const Duration(minutes: 8)),
          isSentByMe: false,
        ),
        Message(
          messageId: 'msg4',
          senderUid: 'user1',
          text: '你呢？',
          sentAt: DateTime.now().subtract(const Duration(minutes: 7)),
          isSentByMe: false,
        ),
        Message(
          messageId: 'msg5',
          senderUid: currentUserId,
          text: '我也不错，今天的拍摄很有趣！',
          sentAt: DateTime.now().subtract(const Duration(minutes: 6)),
          isSentByMe: true,
        ),
        Message(
          messageId: 'msg6',
          senderUid: 'user1',
          text: '是的，希望下次还能一起拍摄！',
          sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
          isSentByMe: false,
        ),
      ];
    } catch (e) {
      _errorMessage = '获取消息失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 发送消息
  Future<void> sendMessage(
    String chatId,
    String text,
    String currentUserId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requestId = 'req_${const Uuid().v4()}';
      final response = await ApiService().sendMessage(requestId, chatId, text);

      if (response.success) {
        // 添加消息到本地列表
        final message = Message(
          messageId: response.data['messageId'] ?? '',
          senderUid: currentUserId,
          text: text,
          sentAt: DateTime.parse(
            response.data['sentAt'] ?? DateTime.now().toIso8601String(),
          ),
          isSentByMe: true,
        );

        if (_messages[chatId] == null) {
          _messages[chatId] = [];
        }
        _messages[chatId]!.add(message);

        // 更新会话列表中的最后一条消息
        final sessionIndex = _chatSessions.indexWhere(
          (session) => session.chatId == chatId,
        );
        if (sessionIndex != -1) {
          _chatSessions[sessionIndex] = ChatSession(
            chatId: chatId,
            memberUids: _chatSessions[sessionIndex].memberUids,
            lastMessage: text,
            lastMessageAt: DateTime.now(),
            friendName: _chatSessions[sessionIndex].friendName,
            friendAvatar: _chatSessions[sessionIndex].friendAvatar,
          );
        }
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = '发送消息失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static ChatProvider of(BuildContext context) {
    return Provider.of<ChatProvider>(context, listen: false);
  }
}
