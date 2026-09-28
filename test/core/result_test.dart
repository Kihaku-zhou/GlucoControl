/// [Result]/[Ok]/[Err]/[AppFailure]/[guardAsync] 的单元测试。
///
/// 覆盖成功与失败两条分支上的 map/withContext/requireValue、失败分类与可重试
/// 判定、以及把普通异常收敛为 [FailureKind.unknown] 并保留 cause 的兜底路径。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';

void main() {
  group('AppFailure', () {
    test('network 工厂把类型固定为 network 并可重试', () {
      final failure = AppFailure.network('连不上', cause: 'socket');

      expect(failure.kind, FailureKind.network);
      expect(failure.message, '连不上');
      expect(failure.cause, 'socket');
      expect(failure.isRetryable, isTrue);
    });

    test('configuration 工厂保留 code 且不可重试', () {
      final failure = AppFailure.configuration('没填地址', code: 'nightscout.missing_url');

      expect(failure.kind, FailureKind.configuration);
      expect(failure.code, 'nightscout.missing_url');
      expect(failure.isRetryable, isFalse);
    });

    test('unsupported 工厂标记为平台不支持', () {
      final failure = AppFailure.unsupported('桌面端没有 Health Connect', code: 'hc.unsupported');

      expect(failure.kind, FailureKind.unsupported);
      expect(failure.code, 'hc.unsupported');
      expect(failure.isRetryable, isFalse);
    });

    test('只有 network 与 unknown 判定为可重试', () {
      bool retryable(FailureKind kind) =>
          AppFailure(kind: kind, message: 'x').isRetryable;

      expect(retryable(FailureKind.network), isTrue);
      expect(retryable(FailureKind.unknown), isTrue);
      expect(retryable(FailureKind.authentication), isFalse);
      expect(retryable(FailureKind.permission), isFalse);
      expect(retryable(FailureKind.parsing), isFalse);
      expect(retryable(FailureKind.storage), isFalse);
      expect(retryable(FailureKind.unsupported), isFalse);
      expect(retryable(FailureKind.configuration), isFalse);
    });

    test('toString 在有无 code 时都能定位失败', () {
      expect(
        const AppFailure(kind: FailureKind.parsing, message: '坏报文').toString(),
        'AppFailure(parsing: 坏报文)',
      );
      expect(
        const AppFailure(
          kind: FailureKind.storage,
          message: '写库失败',
          code: 'db.write',
        ).toString(),
        'AppFailure(storage:db.write: 写库失败)',
      );
    });

    test('AppFailure 是 Exception，可以被 catch 捕获', () {
      expect(
        () => throw const AppFailure(kind: FailureKind.network, message: 'x'),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('Result 的取值与判定', () {
    test('Ok 暴露值并报告成功', () {
      const result = Ok<int>(42);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result.requireValue(), 42);
      expect(result.toString(), 'Ok(42)');
    });

    test('Err 暴露失败原因且 valueOrNull 为 null', () {
      const failure = AppFailure(kind: FailureKind.network, message: '超时');
      const result = Err<int>(failure);

      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.toString(), contains('超时'));
    });

    test('相同泛型与相同值的 Ok 相等', () {
      expect(const Ok<int>(7), const Ok<int>(7));
      expect(const Ok<int>(7).hashCode, const Ok<int>(7).hashCode);
      expect(const Ok<int>(7), isNot(const Ok<int>(8)));
    });

    test('requireValue 在失败分支抛出同一个 AppFailure', () {
      const failure = AppFailure(kind: FailureKind.storage, message: '磁盘满');
      const result = Err<String>(failure);

      expect(() => result.requireValue(), throwsA(same(failure)));
    });
  });

  group('Result.map', () {
    test('Ok 上执行转换并把结果包回 Ok', () {
      const result = Ok<int>(21);

      expect(result.map((value) => value * 2), const Ok<int>(42));
    });

    test('map 可以改变泛型参数类型', () {
      const result = Ok<int>(3);

      final mapped = result.map((value) => '值=$value');

      expect(mapped.valueOrNull, '值=3');
      expect(mapped, isA<Ok<String>>());
    });

    test('Err 上不执行转换，失败原因原样传递', () {
      const failure = AppFailure(kind: FailureKind.parsing, message: '解析失败');
      const result = Err<int>(failure);
      var called = false;

      final mapped = result.map<String>((value) {
        called = true;
        return '不该出现';
      });

      expect(called, isFalse);
      expect(mapped.isOk, isFalse);
      expect(mapped.failureOrNull, same(failure));
    });
  });

  group('Result.withContext', () {
    test('Ok 原样返回，不改写成功值', () {
      const result = Ok<int>(5);

      final same = result.withContext('同步 Nightscout 失败');

      expect(same.isOk, isTrue);
      expect(same.valueOrNull, 5);
      expect(identical(same, result), isTrue);
    });

    test('Err 替换消息但保留 kind/code/cause/stackTrace', () {
      final stack = StackTrace.current;
      final cause = StateError('底层原因');
      final failure = AppFailure(
        kind: FailureKind.network,
        message: '原始消息',
        code: 'nightscout.network',
        cause: cause,
        stackTrace: stack,
      );

      final enriched = Err<int>(failure).withContext('同步最近 30 天失败');

      final updated = enriched.failureOrNull!;
      expect(updated.message, '同步最近 30 天失败');
      expect(updated.kind, FailureKind.network);
      expect(updated.code, 'nightscout.network');
      expect(updated.cause, same(cause));
      expect(updated.stackTrace, same(stack));
      expect(updated, isNot(same(failure)));
    });

    test('withContext 返回的仍是同一泛型的 Err', () {
      const result = Err<List<String>>(
        AppFailure(kind: FailureKind.unknown, message: '未知'),
      );

      final enriched = result.withContext('导入失败');

      expect(enriched, isA<Err<List<String>>>());
      expect(enriched.valueOrNull, isNull);
    });
  });

  group('guardAsync', () {
    test('正常返回时包装为 Ok', () async {
      final result = await guardAsync(() async => 6 * 7);

      expect(result, const Ok<int>(42));
    });

    test('AppFailure 直接透传，不被重新归类', () async {
      const failure = AppFailure(
        kind: FailureKind.authentication,
        message: 'token 过期',
        code: 'nightscout.unauthorized',
      );

      final result = await guardAsync<int>(() async => throw failure);

      expect(result.isOk, isFalse);
      expect(result.failureOrNull, same(failure));
      expect(result.failureOrNull!.kind, FailureKind.authentication);
    });

    test('普通异常归类为 unknown 并保留 cause 与堆栈', () async {
      final cause = FormatException('不是 JSON');

      final result = await guardAsync<Map<String, Object?>>(
        () async => throw cause,
        code: 'health.parse',
      );

      final failure = result.failureOrNull!;
      expect(failure.kind, FailureKind.unknown);
      expect(failure.code, 'health.parse');
      expect(failure.cause, same(cause));
      expect(failure.stackTrace, isNotNull);
      expect(failure.message, '操作失败：${cause.toString()}');
      expect(failure.isRetryable, isTrue);
    });

    test('message 参数覆盖默认的失败文案', () async {
      final result = await guardAsync<int>(
        () async => throw StateError('boom'),
        message: '拉取训记数据失败',
      );

      expect(result.failureOrNull!.message, '拉取训记数据失败');
      expect(result.failureOrNull!.cause, isA<StateError>());
    });

    test('同步抛出的错误同样被收敛', () async {
      final result = await guardAsync<int>(() => throw ArgumentError('参数不合法'));

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.unknown);
      expect(result.failureOrNull!.cause, isA<ArgumentError>());
    });

    test('code 缺省时为 null', () async {
      final result = await guardAsync<int>(() async => throw '纯字符串错误');

      expect(result.failureOrNull!.code, isNull);
      expect(result.failureOrNull!.cause, '纯字符串错误');
    });
  });
}
