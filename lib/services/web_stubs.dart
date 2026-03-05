// Web 平台的 Stub 实现

import 'package:flutter/foundation.dart';

// 判断是否在 Web 平台
const bool isWeb = kIsWeb;

/// Web 平台的数据库 stub（不存储数据，仅供 UI 测试）
class WebDatabaseStub {
  static final WebDatabaseStub _instance = WebDatabaseStub._internal();
  factory WebDatabaseStub() => _instance;
  WebDatabaseStub._internal();
  
  final List<Map<String, dynamic>> _bloodSugarRecords = [];
  final List<Map<String, dynamic>> _exerciseRecords = [];
  
  List<Map<String, dynamic>> get bloodSugarRecords => _bloodSugarRecords;
  List<Map<String, dynamic>> get exerciseRecords => _exerciseRecords;
  
  void addBloodSugarRecord(Map<String, dynamic> record) {
    _bloodSugarRecords.add(record);
  }
  
  void addExerciseRecord(Map<String, dynamic> record) {
    _exerciseRecords.add(record);
  }
}

/// Web 平台蓝牙 stub
class WebBluetoothStub {
  static final WebBluetoothStub _instance = WebBluetoothStub._internal();
  factory WebBluetoothStub() => _instance;
  WebBluetoothStub._internal();
  
  bool isSupported = false;
  bool isConnected = false;
  int? currentHeartRate;
  
  Future<void> startScan() async {
    debugPrint('Web: Bluetooth not supported');
  }
  
  Future<void> stopScan() async {}
  
  Stream<int>? get heartRateStream => null;
}

/// Web 平台权限 stub
class WebPermissionStub {
  static Future<bool> requestCamera() async => false;
  static Future<bool> requestStorage() async => false;
  static Future<bool> requestBluetooth() async => false;
  static Future<bool> requestNotifications() async => false;
}

/// Web 平台通知 stub
class WebNotificationStub {
  static Future<void> showNotification(String title, String body) async {
    debugPrint('Web: Notification - $title: $body');
  }
}
