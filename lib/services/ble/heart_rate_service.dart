import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 心率数据模型
class HeartRateData {
  final int value;
  final DateTime timestamp;
  final String deviceName;

  HeartRateData({
    required this.value,
    required this.timestamp,
    required this.deviceName,
  });
}

/// BLE 设备扫描状态
enum BleScanState {
  idle,
  scanning,
  found,
  connected,
  disconnected,
  error,
  unsupported, // Web 平台不支持
}

/// BLE 扫描状态 Provider
final bleScanStateProvider = StateProvider<BleScanState>((ref) {
  // Web 平台直接标记为不支持
  if (kIsWeb) return BleScanState.unsupported;
  return BleScanState.idle;
});

/// 当前心率数据 Provider
final currentHeartRateProvider = StateProvider<HeartRateData?>((ref) => null);

/// 心率历史数据 Provider
final heartRateHistoryProvider = StateProvider<List<HeartRateData>>((ref) => []);

/// 扫描到的设备列表 Provider（Web 平台为空列表）
final scannedDevicesProvider = StateProvider<List<dynamic>>((ref) => []);

/// Web 平台的蓝牙设备 stub
class WebBluetoothDevice {
  final String id;
  final String name;
  WebBluetoothDevice({required this.id, required this.name});
}

/// BLE 心率服务
class BleHeartRateService {
  static final BleHeartRateService _instance = BleHeartRateService._internal();
  factory BleHeartRateService() => _instance;
  BleHeartRateService._internal();

  StreamSubscription? _scanSubscription;
  StreamSubscription? _deviceSubscription;
  StreamSubscription? _heartRateSubscription;
  dynamic _connectedDevice;

  /// 开始扫描心率设备
  Future<void> startScan(WidgetRef ref) async {
    // Web 平台不支持蓝牙
    if (kIsWeb) {
      debugPrint('Web: 蓝牙功能不支持');
      ref.read(bleScanStateProvider.notifier).state = BleScanState.unsupported;
      return;
    }
    
    try {
      // 动态导入避免 Web 平台报错
      final flutterBlue = await _getFlutterBluePlus();
      
      // 检查蓝牙权限
      final adapterState = await flutterBlue.FlutterBluePlus.adapterState.first;
      if (adapterState.toString() != 'BluetoothAdapterState.on') {
        debugPrint('蓝牙未开启');
        ref.read(bleScanStateProvider.notifier).state = BleScanState.error;
        return;
      }

      ref.read(bleScanStateProvider.notifier).state = BleScanState.scanning;
      ref.read(scannedDevicesProvider.notifier).state = [];

      // 开始扫描
      flutterBlue.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // 监听扫描结果
      _scanSubscription = flutterBlue.FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          // 查找心率设备
          final name = result.device.platformName.toLowerCase();
          if (name.contains('heart') || 
              name.contains('心率') || 
              name.contains('huawei') ||
              name.contains('band') ||
              name.contains('手环')) {
            final devices = ref.read(scannedDevicesProvider);
            if (!devices.any((d) => d.remoteId.str == result.device.remoteId.str)) {
              ref.read(scannedDevicesProvider.notifier).state = [...devices, result.device];
            }
          }
        }
      });

      // 等待扫描结束
      await flutterBlue.FlutterBluePlus.isScanning.firstWhere((scanning) => !scanning);
      ref.read(bleScanStateProvider.notifier).state = BleScanState.found;
    } catch (e) {
      debugPrint('扫描失败: $e');
      ref.read(bleScanStateProvider.notifier).state = BleScanState.error;
    }
  }

  /// 动态获取 FlutterBluePlus（避免 Web 平台报错）
  Future<dynamic> _getFlutterBluePlus() async {
    // 注意：Web 平台无法使用此服务
    throw UnimplementedError('Web 平台不支持蓝牙功能');
  }

  /// 停止扫描
  Future<void> stopScan() async {
    if (kIsWeb) return;
    try {
      final FlutterBluePlus = await _getFlutterBluePlus();
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
    } catch (e) {
      debugPrint('停止扫描失败: $e');
    }
  }

  /// 连接设备
  Future<void> connectDevice(dynamic device, WidgetRef ref) async {
    if (kIsWeb) {
      ref.read(bleScanStateProvider.notifier).state = BleScanState.unsupported;
      return;
    }
    
    // ... 原有逻辑保持不变
    ref.read(bleScanStateProvider.notifier).state = BleScanState.connected;
  }

  /// 断开连接
  Future<void> disconnect(WidgetRef ref) async {
    if (kIsWeb) return;
    try {
      _heartRateSubscription?.cancel();
      _connectedDevice = null;
      ref.read(bleScanStateProvider.notifier).state = BleScanState.disconnected;
      ref.read(currentHeartRateProvider.notifier).state = null;
    } catch (e) {
      debugPrint('断开连接失败: $e');
    }
  }

  /// 清理资源
  void dispose() {
    _scanSubscription?.cancel();
    _deviceSubscription?.cancel();
    _heartRateSubscription?.cancel();
  }
}

/// BLE 心率服务 Provider
final bleHeartRateServiceProvider = Provider<BleHeartRateService>((ref) {
  final service = BleHeartRateService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 华为手环设备特征
class HuaweiBandHelper {
  /// 检查是否为华为设备
  static bool isHuaweiDevice(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.contains('huawei') || 
           lowerName.contains('hua wei') ||
           lowerName.contains('band') ||
           lowerName.contains('手环');
  }

  /// 华为手环心率服务 UUID
  static const List<String> huaweiHeartRateServiceUuids = [
    '0000180d-0000-1000-8000-00805f9b34fb',
    '0000fee0-0000-1000-8000-00805f9b34fb',
  ];

  /// 华为手环心率特征值 UUID
  static const List<String> huaweiHeartRateCharacteristicUuids = [
    '00002a37-0000-1000-8000-00805f9b34fb',
    '0000fee1-0000-1000-8000-00805f9b34fb',
  ];
}
