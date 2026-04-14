# 12-Flutter应用端接入服务端的网络实战指南

## 1. 文档信息
- 文档名称：PhotocMatch Flutter应用端接入服务端的网络实战指南
- 文档版本：v1.0
- 更新时间：2026-04-11
- 关联文档：10-应用端设计规范纲要、09-应用端与服务端接口文档、PMServer_外部应用接入与接口测试文档
- 核心内容：环境初始化、Dart 网络层封装代码、核心业务接口调用示范、统一错误处理。

---

## 2. 环境初始化与模拟器连接

在 Flutter 中，应用端需要能够根据当前的环境变量（如 `--dart-define=DATA_MODE=real_local`）动态决定是连接本地 Emulator 还是真实的 Firebase 云端。

### 2.1 环境变量与配置代码

在应用的入口（`main.dart` 或初始化隔离层中），执行 Firebase 初始化并配置模拟器穿透：

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp();

  // 读取编译期环境变量，默认 fallback 到真实云端（提升安全性）
  const dataMode = String.fromEnvironment('DATA_MODE', defaultValue: 'real_cloud');
  
  if (dataMode == 'real_local') {
    // 跨平台本地开发 IP 穿透适配
    // Android 模拟器内访问宿主机的 localhost 必须使用 10.0.2.2
    final localhost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';

    try {
      // 1. Auth 模拟器
      FirebaseAuth.instance.useAuthEmulator(localhost, 9099);
      // 2. Firestore 模拟器
      FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);
      // 3. Functions 模拟器 (注意与服务端部署的 region 保持一致)
      FirebaseFunctions.instanceFor(region: 'us-central1')
          .useFunctionsEmulator(localhost, 5001);
      // 4. Storage 模拟器
      FirebaseStorage.instance.useStorageEmulator(localhost, 9199);
      
      debugPrint('已成功连接到本地 Firebase Emulator Suite [$localhost]');
    } catch (e) {
      debugPrint('连接本地模拟器失败或已连接: $e');
    }
  }
}
```

---

## 3. 网络请求封装层 (完整配套代码)

为避免每次调用 Cloud Functions 时都要手写重复的错误解析、`requestId` 注入和 `apiVersion` 组装，我们需要在 `Data` 层或 `Shared` 层建立一个全局统一的网络客户端（`ApiClient`）。

### 3.1 统一异常实体类定义

```dart
// lib/shared/error/app_error.dart

class AppError implements Exception {
  final String code;
  final String message;
  final String? traceId;
  final bool retryable;

  AppError({
    required this.code,
    required this.message,
    this.traceId,
    this.retryable = false,
  });

  @override
  String toString() => 'AppError[$code]: $message (Trace: $traceId)';
  
  /// 判断是否是常见的网络断开错误
  static bool isNetworkError(String code) {
    return code == 'NETWORK_ERROR' || code == 'deadline-exceeded' || code == 'unavailable';
  }
}
```

### 3.2 核心网络封装客户端 (`ApiClient`)

将下面的代码保存到 `lib/shared/network/api_client.dart` 中。它会自动拦截并解析后端的 `success` 与 `errorCode` 契约，自动为所有 `isWrite=true` 的接口打上防重放的 `requestId`。

```dart
// lib/shared/network/api_client.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import '../error/app_error.dart';

class ApiClient {
  final FirebaseFunctions _functions;
  final Uuid _uuid = const Uuid();

  ApiClient({FirebaseFunctions? functions}) 
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  /// 发起 Callable 接口调用
  /// [functionName] 后端实际暴露的驼峰函数名，如 authGetCurrentUser
  /// [data] 业务参数负载
  /// [isWrite] 标记是否为写操作场景，写操作自动加上 requestId 进行幂等保护
  Future<Map<String, dynamic>> callFunction(
    String functionName, 
    Map<String, dynamic> data, {
    bool isWrite = false,
  }) async {
    // 强制注入协议版本号
    data['apiVersion'] ??= 'v1';

    // 如果是写接口，自动生成唯一 requestId (防重复提交)
    if (isWrite && !data.containsKey('requestId')) {
      data['requestId'] = 'req_${_uuid.v4()}';
    }

    try {
      // 建立连接句柄
      final callable = _functions.httpsCallable(functionName);
      
      // 发起真实网络请求
      final HttpsCallableResult result = await callable.call(data);
      
      // 解析我们在服务端的统一包装层 ResponseWrapper
      final responseBody = result.data as Map<String, dynamic>;
      
      final bool success = responseBody['success'] ?? false;
      final String? serverTime = responseBody['serverTime'];
      
      // TODO: 在这里可以将 serverTime 通知给全局的 TimeManager 对齐本地时间
      
      if (success) {
        // 请求成功，直接把 payload 里的 data 层暴露给上一层 (Repository)
        return Map<String, dynamic>.from(responseBody['data'] ?? {});
      } else {
        // 请求收到但业务报错 (如：AUTH_REQUIRED, INVALID_REQUEST)
        throw AppError(
          code: responseBody['errorCode'] ?? 'UNKNOWN_ERROR',
          message: responseBody['message'] ?? '发生未知错误',
          traceId: responseBody['traceId'],
          retryable: _isRetryableBusinessError(responseBody['errorCode']),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      // Firebase SDK 层面的强错误 (如网络断开、服务端崩溃500、未授权认证)
      throw AppError(
        code: e.code,
        message: e.message ?? '网络或服务异常',
        retryable: AppError.isNetworkError(e.code),
      );
    } catch (e) {
      // 其他客户端解析异常等
      throw AppError(
        code: 'CLIENT_INTERNAL_ERROR',
        message: e.toString(),
        retryable: false,
      );
    }
  }

  /// 依据业务规则判断哪些类型的 Error 允许客户端静默重试或提示用户重试
  bool _isRetryableBusinessError(String? errorCode) {
    if (errorCode == null) return false;
    const retryableCodes = ['MATCH_NOT_FOUND', 'IDEMPOTENCY_CONFLICT'];
    return retryableCodes.contains(errorCode);
  }
}
```

---

## 4. 重点业务域调用示例 (Repository 层)

在 `Data` 架构组中，Repository 层的类负责调用 `ApiClient` 并把 Map 映射成 Dart 的业务实体对上层抛出。

### 4.1 用户与鉴权业务 (读操作场景)

```dart
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<UserEntity> getCurrentUser() async {
    // 读操作，isWrite: false
    final data = await _apiClient.callFunction('authGetCurrentUser', {}, isWrite: false);
    
    // 把 Map 解析成 Dart 实体
    return UserEntity.fromJson(Map<String, dynamic>.from(data['user']));
  }
}
```

### 4.2 拍摄与上传业务 (带 Storage 及 幂等写操作场景)

```dart
class ShotRepository {
  final ApiClient _apiClient;
  final FirebaseStorage _storage;

  ShotRepository(this._apiClient, this._storage);

  /// 包含两步：1. 直传 Storage  2. 请求 Server 记录落库
  Future<String> submitShot(String localFilePath, String uid) async {
    // 阶段1：上传图片到 Firebase Storage
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'shots/$uid/$todayStr/$fileName';
    
    final ref = _storage.ref().child(storagePath);
    
    // 设置上传校验 metadata，规避规则拒绝
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    
    await ref.putFile(File(localFilePath), metadata);
    
    // 阶段2：向服务端执行声明写入操作
    // 开启 isWrite = true 触发防重复保障
    final payload = {
      'storagePath': storagePath,
      'shotAt': DateTime.now().toUtc().toIso8601String(), // 必须传输 UTC 格式
      'timeOfDay': '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
      'localDate': todayStr,
    };

    final result = await _apiClient.callFunction('shotSubmitShot', payload, isWrite: true);
    
    return result['shotId'] as String;
  }
}
```

### 4.3 匹配与交友决断 (幂等写操作及防冲突)

```dart
class MatchRepository {
  final ApiClient _apiClient;

  MatchRepository(this._apiClient);

  Future<void> acceptInvite(String sessionId) async {
    try {
      final payload = {
        'sessionId': sessionId,
        'decision': 'accept'
      };
      
      // 这个操作极其重要，如果网络抖动，底层 ApiClient 补上的 requestId 会拦截重复写入
      await _apiClient.callFunction('matchUpdateInviteDecision', payload, isWrite: true);
      
    } on AppError catch (e) {
      if (e.code == 'IDEMPOTENCY_CONFLICT') {
        // 处理幂等冲突：说明之前已经成功发送过了，属于客户端网络抖动，本次可直接视为成功或抓取上一次成功的数据
        debugPrint('判定冲突，请求已在远端生效过一遍');
        return; 
      }
      if (e.code == 'MATCH_NOT_FOUND') {
        // 会话已经过期或被清理，需要刷新 UI
        throw Exception('匹配会话已失效，请返回主页');
      }
      rethrow;
    }
  }
}
```

---

## 5. 开发联调规约总结

1. **不要在 UI 测自己造时钟控制过期**：所有诸如 `120 秒拍摄倒计时`、`双向确认倒计时过期` 的限制判断，必须依据响应体中的 `serverTime` 配合倒计时进行，永远以服务端的拦截报错为主。
2. **写接口报错隔离**：不要遇到任何异常都只抛出一个 "Toast: 操作失败"。所有的写操作都应利用 `try { ... } on AppError catch (e)` 分支捕获，并根据上面的错误码映射表执行精准恢复。
3. **安全直传机制**：Flutter 代码端只把图片塞给 Storage（由于我们在 Storage Rule 里加了控制，这在本地和云端都是安全的），然后把路径（如 `shots/abc/img.jpg`）推给服务端，不要尝试把整个图片转成 Base64 在 Cloud Functions 里上传，这会瞬间堵死你的 Callable 函数。