import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
}

/// BLE 扫描状态 Provider
final bleScanStateProvider = StateProvider<BleScanState>((ref) => BleScanState.idle);

/// 当前心率数据 Provider
final currentHeartRateProvider = StateProvider<HeartRateData?>((ref) => null);

/// 心率历史数据 Provider
final heartRateHistoryProvider = StateProvider<List<HeartRateData>>((ref) => []);

/// 扫描到的设备列表 Provider
final scannedDevicesProvider = StateProvider<List<BluetoothDevice>>((ref) => []);

/// BLE 心率服务
class BleHeartRateService {
  static final BleHeartRateService _instance = BleHeartRateService._internal();
  factory BleHeartRateService() => _instance;
  BleHeartRateService._internal();

  StreamSubscription? _scanSubscription;
  StreamSubscription? _deviceSubscription;
  StreamSubscription? _heartRateSubscription;
  BluetoothDevice? _connectedDevice;

  /// 开始扫描心率设备
  Future<void> startScan(WidgetRef ref) async {
    try {
      // 检查蓝牙权限
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        debugPrint('蓝牙未开启');
        ref.read(bleScanStateProvider.notifier).state = BleScanState.error;
        return;
      }

      ref.read(bleScanStateProvider.notifier).state = BleScanState.scanning;
      ref.read(scannedDevicesProvider.notifier).state = [];

      // 开始扫描
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // 监听扫描结果
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          // 查找心率设备（通常心率设备的名称包含 "Heart Rate" 或 "心率"）
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
      await FlutterBluePlus.isScanning.firstWhere((scanning) => !scanning);
      ref.read(bleScanStateProvider.notifier).state = BleScanState.found;
    } catch (e) {
      debugPrint('扫描失败: $e');
      ref.read(bleScanStateProvider.notifier).state = BleScanState.error;
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  /// 连接设备
  Future<void> connectDevice(BluetoothDevice device, WidgetRef ref) async {
    try {
      ref.read(bleScanStateProvider.notifier).state = BleScanState.scanning;
      
      // 停止扫描
      await stopScan();

      // 连接设备
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // 发现服务和特征值
      final services = await device.discoverServices();
      
      // 查找心率服务 (UUID: 0x180D)
      for (final service in services) {
        if (service.uuid.str.toUpperCase().contains('180D')) {
          // 查找心率测量特征值 (UUID: 0x2A37)
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid.str.toUpperCase().contains('2A37')) {
              // 启用通知
              await characteristic.setNotifyValue(true);
              
              // 监听心率数据
              _heartRateSubscription = characteristic.lastValueStream.listen((value) {
                // 解析心率值（第一个字节是标志，第二个字节是心率）
                // 如果第一位是 0x10，则心率值在第二个字节
                // 否则心率值直接在第一个字节
                int heartRate;
                if (value.isNotEmpty) {
                  if (value[0] & 0x10 != 0) {
                    heartRate = value[1];
                  } else {
                    heartRate = value[0];
                  }
                  
                  final data = HeartRateData(
                    value: heartRate,
                    timestamp: DateTime.now(),
                    deviceName: device.platformName,
                  );
                  
                  ref.read(currentHeartRateProvider.notifier).state = data;
                  
                  // 添加到历史
                  final history = ref.read(heartRateHistoryProvider);
                  ref.read(heartRateHistoryProvider.notifier).state = [...history, data];
                }
              });
              
              break;
            }
          }
          break;
        }
      }

      ref.read(bleScanStateProvider.notifier).state = BleScanState.connected;
    } catch (e) {
      debugPrint('连接失败: $e');
      ref.read(bleScanStateProvider.notifier).state = BleScanState.error;
    }
  }

  /// 断开连接
  Future<void> disconnect(WidgetRef ref) async {
    try {
      await _connectedDevice?.disconnect();
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
/// 华为手环使用 HUAWEI Health Kit，可能需要使用特定的 UUID
/// 标准心率服务 UUID: 0x180D
/// 华为健康服务 UUID: FITA Service (0xFEE0) 或 HRS (0x180D)
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
    '0000180d-0000-1000-8000-00805f9b34fb', // 标准心率服务
    '0000fee0-0000-1000-8000-00805f9b34fb', // FIT 服务
  ];

  /// 华为手环心率特征值 UUID
  static const List<String> huaweiHeartRateCharacteristicUuids = [
    '00002a37-0000-1000-8000-00805f9b34fb', // 标准心率测量
    '0000fee1-0000-1000-8000-00805f9b34fb', // FIT 心率
  ];
}
