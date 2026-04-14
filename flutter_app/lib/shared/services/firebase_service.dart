import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  FirebaseService._internal();
  
  Future<void> initialize() async {
    try {
      // 由于这是原型项目，暂时不配置FirebaseOptions
      // 实际项目中需要添加Firebase配置
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "YOUR_API_KEY",
          authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
          projectId: "YOUR_PROJECT_ID",
          storageBucket: "YOUR_PROJECT_ID.appspot.com",
          messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
          appId: "YOUR_APP_ID",
        ),
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // 不抛出异常，让应用继续运行
    }
  }
}
