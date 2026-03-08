import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database_providers.dart';
import 'webdav/webdav_service.dart';

/// 自动同步服务
class AutoSyncService {
  final Ref _ref;
  
  AutoSyncService(this._ref);
  
  /// 检查是否启用自动同步
  Future<bool> isAutoSyncEnabled() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final enabled = prefs.getBool('webdav_enabled') ?? false;
    final autoSync = prefs.getBool('webdav_auto_sync') ?? true;
    return enabled && autoSync;
  }
  
  /// 触发自动同步
  Future<void> triggerAutoSync() async {
    if (!await isAutoSyncEnabled()) {
      return;
    }
    
    try {
      final syncManager = _ref.read(syncManagerProvider);
      await syncManager.syncAll();
      debugPrint('Auto sync completed');
    } catch (e) {
      debugPrint('Auto sync failed: $e');
    }
  }
}

/// 自动同步服务 Provider
final autoSyncServiceProvider = Provider<AutoSyncService>((ref) {
  return AutoSyncService(ref);
});

/// 便捷方法：触发自动同步（供其他地方调用）
Future<void> triggerAutoSync(WidgetRef ref) async {
  final service = ref.read(autoSyncServiceProvider);
  await service.triggerAutoSync();
}
