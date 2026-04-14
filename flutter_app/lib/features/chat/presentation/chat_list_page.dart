import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/chat/state/chat_provider.dart';
import 'package:flutter_app/features/chat/presentation/chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 获取聊天会话列表
      final chatProvider = ChatProvider.of(context);
      chatProvider.getChats();
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return chatProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : chatProvider.errorMessage != null
            ? Center(child: Text(chatProvider.errorMessage!))
            : ListView.builder(
                itemCount: chatProvider.chatSessions.length,
                itemBuilder: (context, index) {
                  final session = chatProvider.chatSessions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: session.friendAvatar.isNotEmpty
                          ? NetworkImage(session.friendAvatar)
                          : null,
                      child: session.friendAvatar.isEmpty
                          ? Text(session.friendName.substring(0, 1))
                          : null,
                    ),
                    title: Text(session.friendName),
                    subtitle: Text(
                      session.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      session.lastMessageAt.toString().split(' ')[1].substring(0, 5),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(session: session),
                        ),
                      );
                    },
                  );
                },
              );
  }
}
