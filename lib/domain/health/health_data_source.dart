import '../../core/result.dart';
import 'health_source.dart';

/// 一次取数的时间窗口，左闭右开。
class HealthFetchWindow {
  /// 构造窗口。
  const HealthFetchWindow({required this.start, required this.end});

  /// 覆盖最近 [days] 天直到现在的窗口。
  factory HealthFetchWindow.lastDays(int days) {
    final end = DateTime.now();
    return HealthFetchWindow(
      start: end.subtract(Duration(days: days)),
      end: end,
    );
  }

  /// 窗口起点（含）。
  final DateTime start;

  /// 窗口终点（不含）。
  final DateTime end;

  /// 窗口跨越的天数。
  int get days => end.difference(start).inDays;

  @override
  String toString() =>
      'HealthFetchWindow(${start.toIso8601String()} .. ${end.toIso8601String()})';
}

/// 一个连接器在当前设备上的可用状态。
class HealthSourceAvailability {
  /// 构造可用性描述。
  const HealthSourceAvailability({
    required this.canFetch,
    this.isAuthorized = false,
    this.hint,
  });

  /// 当前平台是否具备该连接器（例如桌面端没有 Health Connect）。
  const HealthSourceAvailability.unavailable(this.hint)
      : canFetch = false,
        isAuthorized = false;

  /// 当前平台具备该连接器，且已完成授权。
  const HealthSourceAvailability.ready()
      : canFetch = true,
        isAuthorized = true,
        hint = null;

  /// 当前平台具备该连接器，但尚未获得授权。
  const HealthSourceAvailability.needsAuthorization(this.hint)
      : canFetch = false,
        isAuthorized = false;

  /// 是否可以立即取数。
  final bool canFetch;

  /// 用户是否已授权。
  final bool isAuthorized;

  /// 面向用户的说明，解释为什么不能取数。
  final String? hint;
}

/// 一次取数的产出。
class HealthFetchResult {
  /// 构造取数结果。
  const HealthFetchResult({
    required this.samples,
    this.warnings = const <String>[],
  });

  /// 归一化后的样本，未持久化。
  final List<HealthSample> samples;

  /// 部分成功时面向用户的说明（例如某个日期被上游限流而跳过）。
  ///
  /// 非空不代表取数失败：整体仍以 [samples] 为准，[warnings] 只用于提示覆盖不全。
  final List<String> warnings;
}

/// 一个外部健康数据连接器。
///
/// 实现方只负责「取数并归一化」，不负责持久化与去重——那些由
/// `HealthSyncService` 统一完成，保证不同来源的幂等行为一致。
abstract interface class HealthDataSource {
  /// 该连接器的标识。
  HealthSourceId get id;

  /// 是否支持后台自动增量同步。文件型连接器返回 false。
  bool get supportsAutomaticSync;

  /// 探测当前设备上的可用性与授权状态。
  Future<Result<HealthSourceAvailability>> checkAvailability();

  /// 发起授权。无需授权的连接器直接返回当前可用性。
  Future<Result<HealthSourceAvailability>> authorize();

  /// 拉取 [window] 内的样本。
  Future<Result<HealthFetchResult>> fetch(HealthFetchWindow window);
}

/// 把一个导出文件解析为归一化样本。
///
/// 文件导入是所有五个目标应用的通用兜底通路：它们都提供某种导出，
/// 而公开 API 大多不可得。
abstract interface class HealthFileImporter {
  /// 该导入器归属的数据源，用于给解析出的样本打来源标记。
  HealthSourceId get id;

  /// 界面展示名，例如「硅基轻享 CSV」。
  String get displayName;

  /// 可处理的扩展名，小写且不含点。
  List<String> get fileExtensions;

  /// 判断该导入器能否处理给定文件。
  ///
  /// 扩展名相同但结构不同时（例如多个应用的 CSV），实现应进一步检查表头。
  bool canHandle(String fileName, List<int> bytes);

  /// 解析文件内容为归一化样本。
  ///
  /// 文件损坏或结构不符时返回 [FailureKind.parsing] 失败。
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  });
}
