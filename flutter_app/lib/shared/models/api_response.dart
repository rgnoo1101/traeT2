class ApiResponse {
  final bool success;
  final dynamic data;
  final String errorCode;
  final String message;
  final String? traceId;
  final String? serverTime;

  ApiResponse({
    required this.success,
    required this.data,
    required this.errorCode,
    required this.message,
    this.traceId,
    this.serverTime,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'],
      errorCode: json['errorCode'] ?? '',
      message: json['message'] ?? '',
      traceId: json['traceId'],
      serverTime: json['serverTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'errorCode': errorCode,
      'message': message,
      'traceId': traceId,
      'serverTime': serverTime,
    };
  }
}
