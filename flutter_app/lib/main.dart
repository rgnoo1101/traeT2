import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/auth/state/auth_provider.dart';
import 'package:flutter_app/features/auth/presentation/login_page.dart';
import 'package:flutter_app/features/capture/state/daily_flow_provider.dart';
import 'package:flutter_app/features/match/state/match_provider.dart';
import 'package:flutter_app/features/friends/state/friend_provider.dart';
import 'package:flutter_app/features/chat/state/chat_provider.dart';
import 'package:flutter_app/features/album/state/album_provider.dart';
import 'package:flutter_app/app/home_page.dart';
import 'package:flutter_app/shared/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DailyFlowProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
      ],
      child: MaterialApp(
        title: 'PhotoMatch',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 暂时注释掉登录注册页面，直接显示MainPage以便测试其他功能
    // final authProvider = Provider.of<AuthProvider>(context);
    
    // if (authProvider.isLoggedIn) {
    //   return const MainPage();
    // } else {
    //   return const LoginPage();
    // }
    
    return const MainPage();
  }
}

