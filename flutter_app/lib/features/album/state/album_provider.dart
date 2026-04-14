import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/shared/services/api_service.dart';

class Shot {
  final String shotId;
  final String storagePath;
  final DateTime shotAt;
  final String timeOfDay;
  final String status;

  Shot({
    required this.shotId,
    required this.storagePath,
    required this.shotAt,
    required this.timeOfDay,
    required this.status,
  });

  factory Shot.fromJson(Map<String, dynamic> json) {
    return Shot(
      shotId: json['shotId'] ?? '',
      storagePath: json['storagePath'] ?? '',
      shotAt: DateTime.parse(json['shotAt'] ?? DateTime.now().toIso8601String()),
      timeOfDay: json['timeOfDay'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class DateGroup {
  final String localDate;
  final List<Shot> shots;

  DateGroup({
    required this.localDate,
    required this.shots,
  });

  factory DateGroup.fromJson(Map<String, dynamic> json) {
    final shots = (json['shots'] as List).map((shot) => Shot.fromJson(shot)).toList();
    return DateGroup(
      localDate: json['localDate'] ?? '',
      shots: shots,
    );
  }
}

class AlbumProvider extends ChangeNotifier {
  List<DateGroup> _dateGroups = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DateGroup> get dateGroups => _dateGroups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 获取个人相簿
  Future<void> getMyShots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 模拟API调用延迟
      await Future.delayed(const Duration(seconds: 1));
      
      // 添加测试数据
      final today = DateTime.now();
      _dateGroups = [
        DateGroup(
          localDate: today.toString().split(' ')[0],
          shots: [
            Shot(
              shotId: 'shot1',
              storagePath: 'shots/user1/${today.toString().split(' ')[0]}/shot1.jpg',
              shotAt: today.subtract(const Duration(hours: 1)),
              timeOfDay: '下午',
              status: 'completed',
            ),
          ],
        ),
        DateGroup(
          localDate: today.subtract(const Duration(days: 1)).toString().split(' ')[0],
          shots: [
            Shot(
              shotId: 'shot2',
              storagePath: 'shots/user1/${today.subtract(const Duration(days: 1)).toString().split(' ')[0]}/shot2.jpg',
              shotAt: today.subtract(const Duration(days: 1, hours: 2)),
              timeOfDay: '上午',
              status: 'completed',
            ),
          ],
        ),
        DateGroup(
          localDate: today.subtract(const Duration(days: 2)).toString().split(' ')[0],
          shots: [
            Shot(
              shotId: 'shot3',
              storagePath: 'shots/user1/${today.subtract(const Duration(days: 2)).toString().split(' ')[0]}/shot3.jpg',
              shotAt: today.subtract(const Duration(days: 2, hours: 3)),
              timeOfDay: '晚上',
              status: 'completed',
            ),
          ],
        ),
      ];
    } catch (e) {
      _errorMessage = '获取相簿失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static AlbumProvider of(BuildContext context) {
    return Provider.of<AlbumProvider>(context, listen: false);
  }
}
