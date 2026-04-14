import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/chat/state/chat_provider.dart';
import 'package:flutter_app/features/auth/state/auth_provider.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatSession session;
  const ChatDetailPage({super.key, required this.session});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 获取消息列表
    final chatProvider = ChatProvider.of(context);
    final authProvider = AuthProvider.of(context);
    if (authProvider.firebaseUser != null) {
      chatProvider.getMessages(widget.session.chatId, authProvider.firebaseUser!.uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = ChatProvider.of(context);
    final authProvider = AuthProvider.of(context);
    if (authProvider.firebaseUser != null) {
      await chatProvider.sendMessage(widget.session.chatId, text, authProvider.firebaseUser!.uid);
      _messageController.clear();
      // 滚动到底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages[widget.session.chatId] ?? [];

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: chatProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Align(
                      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message.isSentByMe ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                ),
        ),

        // 输入框
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('发送'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
