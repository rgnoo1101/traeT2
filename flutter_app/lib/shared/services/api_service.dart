import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_app/shared/models/api_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late FirebaseFunctions _functions;
  
  ApiService._internal() {
    _functions = FirebaseFunctions.instance;
  }
  
  Future<ApiResponse> callFunction(String functionName, Map<String, dynamic> data) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(functionName);
      final result = await callable(data);
      
      return ApiResponse(
        success: true,
        data: result.data,
        errorCode: '',
        message: '',
      );
    } catch (e) {
      String errorCode = 'UNKNOWN_ERROR';
      String message = '服务调用失败';
      
      if (e is FirebaseFunctionsException) {
        errorCode = e.code;
        message = e.message ?? message;
      }
      
      return ApiResponse(
        success: false,
        data: null,
        errorCode: errorCode,
        message: message,
      );
    }
  }
  
  // Auth API
  Future<ApiResponse> getCurrentUser() async {
    return callFunction('auth.getCurrentUser', {'apiVersion': 'v1'});
  }
  
  // Shot API
  Future<ApiResponse> submitShot(String requestId, String localDate, String shotAt, String storagePath) async {
    return callFunction('shot.submitShot', {
      'apiVersion': 'v1',
      'requestId': requestId,
      'localDate': localDate,
      'shotAt': shotAt,
      'storagePath': storagePath,
    });
  }
  
  // Match API
  Future<ApiResponse> getCurrentSession() async {
    return callFunction('match.getCurrentSession', {'apiVersion': 'v1'});
  }
  
  Future<ApiResponse> updateInviteDecision(String requestId, String sessionId, String decision) async {
    return callFunction('match.updateInviteDecision', {
      'apiVersion': 'v1',
      'requestId': requestId,
      'sessionId': sessionId,
      'decision': decision,
    });
  }
  
  // Friend API
  Future<ApiResponse> listFriends({String? cursor, int limit = 20}) async {
    return callFunction('friend.listFriends', {
      'apiVersion': 'v1',
      'cursor': cursor,
      'limit': limit,
    });
  }
  
  // Chat API
  Future<ApiResponse> listChats({String? cursor, int limit = 20}) async {
    return callFunction('chat.listChats', {
      'apiVersion': 'v1',
      'cursor': cursor,
      'limit': limit,
    });
  }
  
  Future<ApiResponse> listMessages(String chatId, {String? cursor, int limit = 50}) async {
    return callFunction('chat.listMessages', {
      'apiVersion': 'v1',
      'chatId': chatId,
      'cursor': cursor,
      'limit': limit,
    });
  }
  
  Future<ApiResponse> sendMessage(String requestId, String chatId, String text) async {
    return callFunction('chat.sendMessage', {
      'apiVersion': 'v1',
      'requestId': requestId,
      'chatId': chatId,
      'text': text,
    });
  }
  
  // Album API
  Future<ApiResponse> listMyShots(String fromDate, String toDate, {String? cursor, int limit = 20}) async {
    return callFunction('album.listMyShots', {
      'apiVersion': 'v1',
      'fromDate': fromDate,
      'toDate': toDate,
      'cursor': cursor,
      'limit': limit,
    });
  }
  
  // Notification API
  Future<ApiResponse> getTodayPlan(String localDate) async {
    return callFunction('notification.getTodayPlan', {
      'apiVersion': 'v1',
      'localDate': localDate,
    });
  }
}
