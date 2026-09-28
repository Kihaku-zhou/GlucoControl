import '../../core/result.dart';
import '../../domain/health/health_repository.dart';
import '../../domain/health/health_source.dart';
import '../../domain/health/health_timeline.dart';
import '../../data/health/health_sync_service.dart';
import '../../data/health/health_timeline_service.dart';
import 'ai_tool.dart';

/// 构建健康数据工具集。
///
/// 这些工具是「让 AI 调用不同运动健康 App 的数据并做综合判断」的落点：模型不再
/// 被动接收一段预先生成的数据摘要，而是按问题自行决定查什么、查多久、要不要
/// 对比分组。相比把全部数据塞进系统提示，这样既省上下文，也让结论可追溯——
/// 每条结论都能对应到一次具体的工具调用。
class HealthTools {
  /// 组装全部工具。
  ///
  /// [syncService] 为空时不注册需要触发同步的工具，使只读场景（例如单元测试）
  /// 不必构造网络依赖。
  static List<AiTool> build({
    required HealthTimelineService timelineService,
    required HealthRepository repository,
    HealthSyncService? syncService,
  }) =>
      <AiTool>[
        ListDataSourcesTool(repository),
        QueryHealthTimelineTool(timelineService),
        GlucoseSummaryTool(timelineService),
        GlucoseContextTool(timelineService),
        CompareActiveRestDaysTool(timelineService),
        if (syncService != null) SyncDataSourceTool(syncService),
      ];
}

/// 查询各外部数据源的连接状态与数据量。
class ListDataSourcesTool implements AiTool {
  /// 构造工具。
  const ListDataSourcesTool(this._repository);

  final HealthRepository _repository;

  @override
  AiToolDefinition get definition => const AiToolDefinition(
        name: 'list_data_sources',
        description: '列出所有外部健康数据源（华为运动健康、Health Connect、'
            '硅基轻享、iGPSPORT、Keep、训记、Nightscout 等）的启用状态、'
            '最近同步时间、最近错误与已入库记录数。'
            '当用户询问「你有哪些数据」「某个 App 的数据接进来了吗」时使用。',
      );

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    final states = await _repository.syncStates();
    if (!states.isOk) return Err(states.failureOrNull!);
    return Ok(<String, Object?>{
      'sources': states
          .requireValue()
          .map((state) => <String, Object?>{
                'id': state.source.code,
                'name': state.source.displayName,
                'description': state.source.description,
                'enabled': state.enabled,
                'sampleCount': state.sampleCount,
                'lastSyncedAt': state.lastSyncedAt?.toIso8601String(),
                'lastError': state.lastError,
              })
          .toList(),
    });
  }
}

/// 查询统一健康时间线。
class QueryHealthTimelineTool implements AiTool {
  /// 构造工具。
  const QueryHealthTimelineTool(this._timelineService);

  final HealthTimelineService _timelineService;

  @override
  AiToolDefinition get definition => const AiToolDefinition(
        name: 'query_health_timeline',
        description: '按时间范围与记录类别拉取统一健康时间线，'
            '把本应用录入的数据与各外部 App 的数据合并后按时间排序返回。'
            '这是回答「最近怎么样」「某天发生了什么」的通用入口。',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'days': <String, Object?>{
              'type': 'integer',
              'description': '回溯天数，默认 7，最大 365',
            },
            'kinds': <String, Object?>{
              'type': 'array',
              'description': '只保留这些类别，留空表示全部',
              'items': <String, Object?>{
                'type': 'string',
                'enum': <String>[
                  'glucose',
                  'workout',
                  'meal',
                  'body_composition',
                  'sleep',
                  'daily_activity',
                ],
              },
            },
            'maxEntries': <String, Object?>{
              'type': 'integer',
              'description': '返回条目上限，默认 120，避免上下文过长',
            },
          },
        },
      );

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    final range = resolveRange(arguments);
    final query = HealthQuery(
      start: range.start,
      end: range.end,
      kinds: resolveKinds(arguments['kinds']),
    );
    final built = await _timelineService.build(query);
    if (!built.isOk) return Err(built.failureOrNull!);

    final timeline = built.requireValue();
    final maxEntries =
        (arguments['maxEntries'] as num?)?.toInt().clamp(1, 500) ?? 120;
    final summary = timeline.glucoseSummary();

    return Ok(<String, Object?>{
      'range': <String, Object?>{
        'start': range.start.toIso8601String(),
        'end': range.end.toIso8601String(),
      },
      'entryCount': timeline.entries.length,
      'glucoseSummary': summary?.toJson(),
      'entries': timeline.toJson(maxEntries: maxEntries),
    });
  }
}

/// 统计指定区间的血糖指标。
class GlucoseSummaryTool implements AiTool {
  /// 构造工具。
  const GlucoseSummaryTool(this._timelineService);

  final HealthTimelineService _timelineService;

  @override
  AiToolDefinition get definition => const AiToolDefinition(
        name: 'glucose_summary',
        description: '计算血糖统计指标：平均血糖、最高最低、目标范围内时间占比'
            '（TIR）、低于与高于范围的比例，以及按平均血糖推算的糖化血红蛋白。'
            '可指定目标范围。数据同时来自本应用录入与外部 CGM。',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'days': <String, Object?>{
              'type': 'integer',
              'description': '回溯天数，默认 14',
            },
            'targetMinMmolPerL': <String, Object?>{
              'type': 'number',
              'description': '目标范围下限（mmol/L），默认 3.9',
            },
            'targetMaxMmolPerL': <String, Object?>{
              'type': 'number',
              'description': '目标范围上限（mmol/L），默认 10.0',
            },
          },
        },
      );

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    final range = resolveRange(arguments);
    final built = await _timelineService.build(HealthQuery(
      start: range.start,
      end: range.end,
      kinds: const <HealthSampleKind>{HealthSampleKind.glucose},
    ));
    if (!built.isOk) return Err(built.failureOrNull!);

    final summary = built.requireValue().glucoseSummary(
          targetMinMmolPerL:
              (arguments['targetMinMmolPerL'] as num?)?.toDouble() ?? 3.9,
          targetMaxMmolPerL:
              (arguments['targetMaxMmolPerL'] as num?)?.toDouble() ?? 10.0,
        );
    if (summary == null) {
      return const Ok(<String, Object?>{
        'count': 0,
        'note': '该时间段内没有任何血糖记录，无法给出统计结论',
      });
    }
    return Ok(summary.toJson());
  }
}

/// 查询某个时间点前后的运动与饮食，用于解释血糖波动。
class GlucoseContextTool implements AiTool {
  /// 构造工具。
  const GlucoseContextTool(this._timelineService);

  final HealthTimelineService _timelineService;

  @override
  AiToolDefinition get definition => const AiToolDefinition(
        name: 'glucose_context',
        description: '给定一个时间点，找出它前后若干小时内的运动与饮食记录，'
            '用于回答「这次血糖升高/降低可能是什么原因」。'
            '返回每个相关事件与目标时刻的间隔分钟数。',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'at': <String, Object?>{
              'type': 'string',
              'description': '目标时刻，ISO 8601 格式，例如 2026-09-28T14:30:00',
            },
            'lookBackHours': <String, Object?>{
              'type': 'number',
              'description': '向前回溯小时数，默认 3',
            },
            'lookAheadHours': <String, Object?>{
              'type': 'number',
              'description': '向后延伸小时数，默认 1',
            },
          },
          'required': <String>['at'],
        },
      );

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    final rawAt = arguments['at'];
    final at = rawAt is String ? DateTime.tryParse(rawAt) : null;
    if (at == null) {
      return const Err(AppFailure(
        kind: FailureKind.parsing,
        message: 'at 参数必须是 ISO 8601 时间字符串，例如 2026-09-28T14:30:00',
        code: 'ai_tool.bad_time',
      ));
    }

    final lookBack = Duration(
      minutes: (((arguments['lookBackHours'] as num?)?.toDouble() ?? 3) * 60)
          .round(),
    );
    final lookAhead = Duration(
      minutes: (((arguments['lookAheadHours'] as num?)?.toDouble() ?? 1) * 60)
          .round(),
    );

    final built = await _timelineService.build(HealthQuery(
      start: at.subtract(lookBack),
      end: at.add(lookAhead),
    ));
    if (!built.isOk) return Err(built.failureOrNull!);

    final timeline = built.requireValue();
    final related = timeline.contextAround(at,
        lookBack: lookBack, lookAhead: lookAhead);

    return Ok(<String, Object?>{
      'at': at.toIso8601String(),
      'lookBackHours': lookBack.inMinutes / 60,
      'lookAheadHours': lookAhead.inMinutes / 60,
      'relatedEvents': related
          .map((entry) => <String, Object?>{
                ...entry.toJson(),
                'minutesFromTarget': entry.at.difference(at).inMinutes,
              })
          .toList(),
      if (related.isEmpty) 'note': '该时间窗内没有饮食或运动记录',
    });
  }
}

/// 对比「有运动的日子」与「没有运动的日子」的血糖表现。
class CompareActiveRestDaysTool implements AiTool {
  /// 构造工具。
  const CompareActiveRestDaysTool(this._timelineService);

  final HealthTimelineService _timelineService;

  @override
  AiToolDefinition get definition => const AiToolDefinition(
        name: 'compare_active_rest_days',
        description: '把时间范围内的日期分成「当天有运动」与「当天无运动」两组，'
            '分别统计血糖指标并给出差异。用于回答「运动对我的血糖到底有没有帮助」。'
            '注意：这是观察性对比，不能证明因果关系。',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'days': <String, Object?>{
              'type': 'integer',
              'description': '回溯天数，默认 30',
            },
          },
        },
      );

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    final range = resolveRange(arguments, defaultDays: 30);
    final built = await _timelineService.build(HealthQuery(
      start: range.start,
      end: range.end,
    ));
    if (!built.isOk) return Err(built.failureOrNull!);

    final timeline = built.requireValue();
    final activeDays = <DateTime>{};
    for (final entry in timeline.ofKind(HealthTimelineKind.workout)) {
      activeDays.add(DateTime(entry.at.year, entry.at.month, entry.at.day));
    }

    final activeEntries = <HealthTimelineEntry>[];
    final restEntries = <HealthTimelineEntry>[];
    for (final entry in timeline.entries) {
      final day = DateTime(entry.at.year, entry.at.month, entry.at.day);
      if (entry.kind == HealthTimelineKind.glucose) {
        (activeDays.contains(day) ? activeEntries : restEntries).add(entry);
      } else {
        // 运动条目本身也带进各自分组，便于模型核对该日的训练内容。
        (activeDays.contains(day) ? activeEntries : restEntries).add(entry);
      }
    }

    final activeSummary = HealthTimeline(activeEntries).glucoseSummary();
    final restSummary = HealthTimeline(restEntries).glucoseSummary();

    return Ok(<String, Object?>{
      'range': <String, Object?>{
        'start': range.start.toIso8601String(),
        'end': range.end.toIso8601String(),
      },
      'activeDayCount': activeDays.length,
      'activeDays': activeSummary?.toJson(),
      'restDays': restSummary?.toJson(),
      'meanDifferenceMmolPerL': (activeSummary != null && restSummary != null)
          ? double.parse(
              (activeSummary.meanMmolPerL - restSummary.meanMmolPerL)
                  .toStringAsFixed(2))
          : null,
      'caveat': '两组天数不等且未控制饮食、用药与作息，差异只能作为线索，不能作为因果结论',
    });
  }
}

/// 触发一次数据源同步。
class SyncDataSourceTool implements AiTool {
  /// 构造工具。
  const SyncDataSourceTool(this._syncService);

  final HealthSyncService _syncService;

  @override
  AiToolDefinition get definition => const AiToolDefinition(
        name: 'sync_data_source',
        description: '立即从某个外部数据源拉取最新数据（或同步全部已配置的数据源）。'
            '当用户说「更新一下数据」「拉取最近的记录」时使用。'
            '注意：训记接口按训练日限流，同一日期约 90 秒内只能读一次。',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'source': <String, Object?>{
              'type': 'string',
              'description': '数据源编码，例如 xunji、health_connect、nightscout、'
                  'huawei_health；留空表示同步全部',
            },
            'days': <String, Object?>{
              'type': 'integer',
              'description': '回溯天数，默认 14',
            },
          },
        },
      );

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    final days = (arguments['days'] as num?)?.toInt().clamp(1, 365) ?? 14;
    final rawSource = arguments['source'];
    final sourceCode = rawSource is String && rawSource.trim().isNotEmpty
        ? rawSource.trim()
        : null;

    if (sourceCode == null) {
      final reports = await _syncService.syncAll(days: days);
      return Ok(<String, Object?>{
        'reports': reports.map(_reportJson).toList(),
      });
    }

    final source = HealthSourceId.tryFromCode(sourceCode);
    if (source == null) {
      return Err(AppFailure(
        kind: FailureKind.parsing,
        message: '未知的数据源编码 $sourceCode，'
            '可用值：${HealthSourceId.values.map((s) => s.code).join('、')}',
        code: 'ai_tool.unknown_source',
      ));
    }
    final report = await _syncService.syncSource(source, days: days);
    return Ok(_reportJson(report));
  }

  /// 把同步结果整理成模型可读的 JSON。
  static Map<String, Object?> _reportJson(HealthSyncReport report) =>
      <String, Object?>{
        'source': report.source.code,
        'name': report.source.displayName,
        'succeeded': report.succeeded,
        'fetched': report.fetched,
        'inserted': report.inserted,
        'updated': report.updated,
        if (report.warnings.isNotEmpty) 'warnings': report.warnings,
        if (report.error != null) 'error': report.error,
      };
}

/// 解析时间范围参数。
///
/// 支持两种写法：`days`（相对今天回溯）与 `startDate`/`endDate`（绝对区间）。
/// 同时给出时以绝对区间为准，因为它更明确。
({DateTime start, DateTime end}) resolveRange(
  Map<String, Object?> arguments, {
  int defaultDays = 7,
}) {
  final rawStart = arguments['startDate'];
  final rawEnd = arguments['endDate'];
  final start = rawStart is String ? DateTime.tryParse(rawStart) : null;
  final end = rawEnd is String ? DateTime.tryParse(rawEnd) : null;
  if (start != null && end != null && end.isAfter(start)) {
    return (start: start, end: end);
  }
  final days =
      (arguments['days'] as num?)?.toInt().clamp(1, 365) ?? defaultDays;
  final now = DateTime.now();
  return (start: now.subtract(Duration(days: days)), end: now);
}

/// 解析类别过滤参数；无法识别的编码被忽略而不是报错。
Set<HealthSampleKind> resolveKinds(Object? raw) {
  if (raw is! List) return const <HealthSampleKind>{};
  final kinds = <HealthSampleKind>{};
  for (final item in raw) {
    if (item is! String) continue;
    final byTimelineKind = HealthTimelineKind.tryFromCode(item);
    if (byTimelineKind != null) {
      kinds.add(_sampleKindOf(byTimelineKind));
      continue;
    }
    final bySampleKind = HealthSampleKind.tryFromCode(item);
    if (bySampleKind != null) kinds.add(bySampleKind);
  }
  return kinds;
}

/// 把时间线类别映射回样本类别。
///
/// [HealthTimelineKind.meal] 没有对应的外部样本类别，映射到血糖类别以便
/// 让时间线构建器把饮食一并带上。
HealthSampleKind _sampleKindOf(HealthTimelineKind kind) => switch (kind) {
      HealthTimelineKind.glucose => HealthSampleKind.glucose,
      HealthTimelineKind.workout => HealthSampleKind.workout,
      HealthTimelineKind.meal => HealthSampleKind.glucose,
      HealthTimelineKind.bodyComposition => HealthSampleKind.bodyComposition,
      HealthTimelineKind.sleep => HealthSampleKind.sleep,
      HealthTimelineKind.dailyActivity => HealthSampleKind.dailyActivity,
    };
