import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/health/health_source_config.dart';
import '../../../data/health/health_sync_service.dart';
import '../../../domain/health/health_repository.dart';
import '../../../domain/health/health_source.dart';
import '../../providers/health_providers.dart';

/// 外部数据源接入管理页。
///
/// 每个数据源的可用性、授权状态与最近错误都由连接器自己报告，界面只做展示，
/// 因此新增一个数据源不需要改动本页——只要它在 [HealthSourceId] 中登记。
class HealthSourcesScreen extends ConsumerStatefulWidget {
  /// 构造页面。
  const HealthSourcesScreen({super.key});

  @override
  ConsumerState<HealthSourcesScreen> createState() =>
      _HealthSourcesScreenState();
}

class _HealthSourcesScreenState extends ConsumerState<HealthSourcesScreen> {
  bool _busy = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(healthSourceStatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据源接入'),
        actions: <Widget>[
          IconButton(
            tooltip: '同步全部',
            onPressed: _busy ? null : () => _syncAll(),
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          const _IntroCard(),
          if (_statusMessage != null) _StatusBanner(message: _statusMessage!),
          if (_busy) const LinearProgressIndicator(),
          ...HealthSourceId.values.map(
            (source) => _SourceCard(
              source: source,
              state: _stateOf(statesAsync.valueOrNull, source),
              busy: _busy,
              onConfigure: () => _configure(source),
              onSync: () => _syncOne(source),
              onPurge: () => _purge(source),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导入导出文件'),
            subtitle: const Text(
              '支持硅基轻享 CSV、训记 CSV、Keep CSV、GPX、TCX、FIT。'
              '这是所有数据源的通用兜底通路。',
            ),
            enabled: !_busy,
            onTap: _importFiles,
          ),
        ],
      ),
    );
  }

  /// 从状态列表中取出指定数据源的状态。
  static HealthSourceSyncState? _stateOf(
    List<HealthSourceSyncState>? states,
    HealthSourceId source,
  ) {
    if (states == null) return null;
    for (final state in states) {
      if (state.source == source) return state;
    }
    return null;
  }

  /// 触发单源同步并回显结果。
  Future<void> _syncOne(HealthSourceId source) async {
    setState(() {
      _busy = true;
      _statusMessage = '正在同步${source.displayName}…';
    });
    final report =
        await ref.read(healthSyncServiceProvider).syncSource(source, days: 30);
    if (!mounted) return;
    ref.invalidate(healthSourceStatesProvider);
    setState(() {
      _busy = false;
      _statusMessage = _describe(report);
    });
  }

  /// 触发全量同步。
  Future<void> _syncAll() async {
    setState(() {
      _busy = true;
      _statusMessage = '正在同步全部数据源…';
    });
    final reports = await ref.read(healthSyncServiceProvider).syncAll(days: 30);
    if (!mounted) return;
    ref.invalidate(healthSourceStatesProvider);
    setState(() {
      _busy = false;
      _statusMessage = reports.map(_describe).join('\n');
    });
  }

  /// 选择并导入一个或多个导出文件。
  Future<void> _importFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() {
      _busy = true;
      _statusMessage = '正在导入…';
    });

    final messages = <String>[];
    final syncService = ref.read(healthSyncServiceProvider);
    for (final file in picked.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        messages.add('${file.name}：无法读取文件内容');
        continue;
      }
      final result =
          await syncService.importFile(fileName: file.name, bytes: bytes);
      if (result.isOk) {
        final report = result.requireValue();
        messages.add('${file.name}：解析 ${report.parsed} 条，'
            '新增 ${report.inserted} 条，更新 ${report.updated} 条');
      } else {
        messages.add('${file.name}：${result.failureOrNull!.message}');
      }
    }

    if (!mounted) return;
    ref.invalidate(healthSourceStatesProvider);
    setState(() {
      _busy = false;
      _statusMessage = messages.join('\n');
    });
  }

  /// 清除某个数据源已入库的数据与配置。
  Future<void> _purge(HealthSourceId source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('清除${source.displayName}的数据？'),
        content: const Text('已导入的记录与连接配置都会被删除，该操作不可撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repository = ref.read(healthRepositoryProvider);
    final purged = await repository.purgeSource(source);
    await ref.read(healthSourceSettingsProvider.notifier).clear(source);
    if (!mounted) return;
    ref.invalidate(healthSourceStatesProvider);
    setState(() {
      _statusMessage = purged.isOk
          ? '已清除${source.displayName}的 ${purged.requireValue()} 条记录'
          : '清除失败：${purged.failureOrNull!.message}';
    });
  }

  /// 打开某个数据源的连接参数编辑页。
  Future<void> _configure(HealthSourceId source) async {
    final settings = ref.read(healthSourceSettingsProvider);
    final updated = await Navigator.push<HealthSourceConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => _SourceConfigScreen(
          source: source,
          initial: settings[source] ?? const HealthSourceConfig(),
        ),
      ),
    );
    if (updated == null) return;
    await ref.read(healthSourceSettingsProvider.notifier).save(source, updated);
    if (!mounted) return;
    setState(() => _statusMessage = '已保存${source.displayName}的连接参数');
  }

  /// 把同步结果整理成一行可读文字。
  static String _describe(HealthSyncReport report) {
    if (!report.succeeded) {
      return '${report.source.displayName}：${report.error ?? '同步失败'}';
    }
    final buffer = StringBuffer('${report.source.displayName}：'
        '取回 ${report.fetched} 条，新增 ${report.inserted} 条，'
        '更新 ${report.updated} 条');
    if (report.warnings.isNotEmpty) {
      buffer.write('（${report.warnings.join('；')}）');
    }
    return buffer.toString();
  }
}

/// 页面顶部的说明卡片。
class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '接入你在别处记录的健康数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '五个目标应用的开放程度差别很大：训记提供官方 Open API，'
              'iGPSPORT 有官方接口但需商务申请，华为运动健康走 Health Kit 且需资质审核，'
              'Keep 没有公开接口，硅基轻享只能经 Juggluco 推送到 Nightscout 后只读拉取。'
              '因此本页同时提供「在线连接」与「文件导入」两条通路，导出的原始文件对所有来源都有效。',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              '接入前请确认你有权导出并处理这些数据；血糖属于敏感健康信息。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作结果提示条。
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
    );
  }
}

/// 单个数据源的状态卡片。
class _SourceCard extends ConsumerStatefulWidget {
  const _SourceCard({
    required this.source,
    required this.state,
    required this.busy,
    required this.onConfigure,
    required this.onSync,
    required this.onPurge,
  });

  final HealthSourceId source;
  final HealthSourceSyncState? state;
  final bool busy;
  final VoidCallback onConfigure;
  final VoidCallback onSync;
  final VoidCallback onPurge;

  @override
  ConsumerState<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends ConsumerState<_SourceCard> {
  bool _checking = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  /// 探测该数据源在当前设备上的可用性。
  Future<void> _check() async {
    if (widget.source == HealthSourceId.manual) return;
    setState(() => _checking = true);
    final source = ref.read(healthDataSourcesProvider)[widget.source];
    if (source == null) {
      setState(() {
        _checking = false;
        _hint = '本平台没有可用的连接器';
      });
      return;
    }
    final result = await source.checkAvailability();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _hint = result.isOk
          ? result.requireValue().hint
          : result.failureOrNull!.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final subtitle = StringBuffer(widget.source.description);
    if (state != null && state.sampleCount > 0) {
      subtitle.write('\n已入库 ${state.sampleCount} 条');
    }
    if (state?.lastSyncedAt != null) {
      subtitle.write('，最近同步 ${_formatTime(state!.lastSyncedAt!)}');
    }
    if (state?.lastError != null) {
      subtitle.write('\n上次失败：${state!.lastError}');
    }
    if (_hint != null) {
      subtitle.write('\n$_hint');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: _checking
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_iconOf(widget.source)),
        title: Text(widget.source.displayName),
        subtitle: Text(subtitle.toString(),
            style: const TextStyle(fontSize: 12, height: 1.5)),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          enabled: !widget.busy,
          onSelected: (value) {
            switch (value) {
              case 'config':
                widget.onConfigure();
              case 'sync':
                widget.onSync();
              case 'purge':
                widget.onPurge();
            }
          },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'config', child: Text('连接设置')),
            PopupMenuItem<String>(value: 'sync', child: Text('立即同步')),
            PopupMenuItem<String>(value: 'purge', child: Text('清除数据')),
          ],
        ),
        onTap: widget.onConfigure,
      ),
    );
  }

  /// 数据源对应的图标。
  static IconData _iconOf(HealthSourceId source) => switch (source) {
        HealthSourceId.healthConnect => Icons.favorite,
        HealthSourceId.huaweiHealth => Icons.watch,
        HealthSourceId.sibionics => Icons.water_drop,
        HealthSourceId.igpsport => Icons.directions_bike,
        HealthSourceId.keep => Icons.fitness_center,
        HealthSourceId.xunji => Icons.sports_gymnastics,
        HealthSourceId.nightscout => Icons.cloud_sync,
        HealthSourceId.fileImport => Icons.upload_file,
        HealthSourceId.manual => Icons.edit_note,
      };

  /// 把时间格式化为「月-日 时:分」。
  static String _formatTime(DateTime time) =>
      '${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')} '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

/// 一个可编辑的配置字段。
class _FieldSpec {
  const _FieldSpec({
    required this.key,
    required this.label,
    this.helper,
    this.obscure = false,
  });

  final String key;
  final String label;
  final String? helper;
  final bool obscure;
}

/// 数据源连接参数编辑页。
///
/// 字段随数据源而异，但都以同一套「键 → 值」模型落到
/// [HealthSourceConfig] 上，因此不需要为每个来源写一个页面。
class _SourceConfigScreen extends StatefulWidget {
  const _SourceConfigScreen({required this.source, required this.initial});

  final HealthSourceId source;
  final HealthSourceConfig initial;

  @override
  State<_SourceConfigScreen> createState() => _SourceConfigScreenState();
}

class _SourceConfigScreenState extends State<_SourceConfigScreen> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _controllers = <String, TextEditingController>{
      'baseUrl': TextEditingController(text: initial.baseUrl ?? ''),
      'apiKey': TextEditingController(text: initial.apiKey ?? ''),
      'accessToken': TextEditingController(text: initial.accessToken ?? ''),
      'clientId': TextEditingController(text: initial.clientId ?? ''),
      'clientSecret': TextEditingController(text: initial.clientSecret ?? ''),
      'extra': TextEditingController(
        text: initial.extra.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('\n'),
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fieldsFor(widget.source);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.displayName} 连接设置'),
        actions: <Widget>[
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            widget.source.description,
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (fields.isEmpty)
            const Text('该数据源无需填写连接参数，保存后按「立即同步」或完成授权即可。'),
          for (final field in fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[field.key],
                obscureText: field.obscure,
                maxLines: field.key == 'extra' ? 6 : 1,
                decoration: InputDecoration(
                  labelText: field.label,
                  helperText: field.helper,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '连接参数保存在本机。血糖等健康数据属于敏感个人信息，'
                '导入前请确认你有权处理这些数据，并避免在共享设备上长期保留凭据。',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 保存并返回新配置。
  void _save() {
    final extra = <String, String>{};
    for (final line in _controllers['extra']!.text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final separator = trimmed.indexOf('=');
      if (separator <= 0) continue;
      extra[trimmed.substring(0, separator).trim()] =
          trimmed.substring(separator + 1).trim();
    }

    Navigator.pop(
      context,
      HealthSourceConfig(
        baseUrl: _emptyToNull(_controllers['baseUrl']!.text),
        apiKey: _emptyToNull(_controllers['apiKey']!.text),
        accessToken: _emptyToNull(_controllers['accessToken']!.text),
        clientId: _emptyToNull(_controllers['clientId']!.text),
        clientSecret: _emptyToNull(_controllers['clientSecret']!.text),
        extra: extra,
      ),
    );
  }

  /// 空白输入归一化为 null，避免把空串当作「已配置」。
  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 各数据源需要填写的字段。
  static List<_FieldSpec> _fieldsFor(HealthSourceId source) => switch (source) {
        HealthSourceId.xunji => const <_FieldSpec>[
            _FieldSpec(
              key: 'apiKey',
              label: '训记 API Key',
              helper: '在训记 App 的「我的 > 数据导出和导入」中生成，需要买断或 VIP 账号',
              obscure: true,
            ),
            _FieldSpec(
              key: 'baseUrl',
              label: '接口地址（可选）',
              helper: '留空使用官方地址 https://trains.xunjiapp.cn',
            ),
          ],
        HealthSourceId.nightscout => const <_FieldSpec>[
            _FieldSpec(
              key: 'baseUrl',
              label: 'Nightscout 站点地址',
              helper: '例如 https://your-site.example.com',
            ),
            _FieldSpec(
              key: 'accessToken',
              label: 'API secret',
              helper: '填写后会以 SHA-1 摘要作为 api-secret 请求头发送',
              obscure: true,
            ),
            _FieldSpec(
              key: 'extra',
              label: '附加参数（每行 key=value）',
              helper: '例如 token=只读访问令牌、path.glucose=/api/v1/entries.json',
            ),
          ],
        HealthSourceId.huaweiHealth => const <_FieldSpec>[
            _FieldSpec(
              key: 'clientId',
              label: 'client_id',
              helper: '需先在华为开发者联盟申请「运动健康」应用并通过资质审核',
            ),
            _FieldSpec(
              key: 'clientSecret',
              label: 'client_secret',
              obscure: true,
            ),
            _FieldSpec(
              key: 'accessToken',
              label: 'access_token',
              helper: '完成 OAuth 授权码流程后填入',
              obscure: true,
            ),
            _FieldSpec(
              key: 'baseUrl',
              label: '云侧数据接口地址',
              helper: '按审核通过后文档给出的域名填写',
            ),
            _FieldSpec(
              key: 'extra',
              label: '数据路径（每行 key=value）',
              helper: '例如 glucose=/healthkit/v1/glucose、steps=/healthkit/v1/steps；'
                  '键名支持 glucose、workout、sleep、steps',
            ),
          ],
        HealthSourceId.healthConnect => const <_FieldSpec>[],
        HealthSourceId.sibionics ||
        HealthSourceId.keep ||
        HealthSourceId.igpsport =>
          const <_FieldSpec>[
            _FieldSpec(
              key: 'extra',
              label: '附加参数（每行 key=value）',
              helper: '这些来源没有公开 API，请改用「导入导出文件」；'
                  '若你已自建中转服务，可在此填写其参数',
            ),
          ],
        HealthSourceId.fileImport || HealthSourceId.manual =>
          const <_FieldSpec>[],
      };
}
