/// 失败分类。用于让调用方区分「重试有意义」与「需要用户先改配置」两类失败。
enum FailureKind {
  /// 网络不可达、超时、上游 5xx。
  network,

  /// 凭据缺失、过期或被拒。
  authentication,

  /// 平台权限未授予（Health Connect、通知、文件访问）。
  permission,

  /// 上游返回的数据无法解析为预期结构。
  parsing,

  /// 本地数据库读写失败。
  storage,

  /// 当前平台不具备该能力（例如桌面端没有 Health Connect）。
  unsupported,

  /// 配置缺失或非法（例如未填写 Health Kit 的应用 ID）。
  configuration,

  /// 未归类的失败。
  unknown,
}

/// 一次失败的结构化描述。
///
/// [message] 面向用户，[cause] 与 [stackTrace] 面向日志；[kind] 决定调用方是否可以重试。
class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  /// 便于构造网络类失败。
  factory AppFailure.network(String message, {Object? cause}) =>
      AppFailure(kind: FailureKind.network, message: message, cause: cause);

  /// 便于构造配置类失败。
  factory AppFailure.configuration(String message,
          {String? code, Object? cause}) =>
      AppFailure(
          kind: FailureKind.configuration,
          message: message,
          code: code,
          cause: cause);

  /// 便于构造「当前平台不支持」类失败。
  factory AppFailure.unsupported(String message, {String? code}) =>
      AppFailure(kind: FailureKind.unsupported, message: message, code: code);

  /// 失败类别，决定重试策略。
  final FailureKind kind;

  /// 面向用户的一句话说明。
  final String message;

  /// 稳定的机器可读标识，便于测试断言与日志聚合。
  final String? code;

  /// 触发本次失败的底层异常。
  final Object? cause;

  /// [cause] 的堆栈。
  final StackTrace? stackTrace;

  /// 该失败在保持同一输入的前提下重试是否可能成功。
  bool get isRetryable =>
      kind == FailureKind.network || kind == FailureKind.unknown;

  @override
  String toString() =>
      'AppFailure(${kind.name}${code == null ? '' : ':$code'}: $message)';
}

/// 操作结果：显式区分成功与失败，避免用 null 同时承载「无数据」和「出错」。
sealed class Result<T> {
  const Result();

  /// 构造成功结果。
  const factory Result.ok(T value) = Ok<T>;

  /// 构造失败结果。
  const factory Result.err(AppFailure failure) = Err<T>;

  /// 成功时为值，失败时为 null。仅用于不关心失败原因的场景。
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// 失败时为原因，成功时为 null。
  AppFailure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// 成功标记。
  bool get isOk => this is Ok<T>;

  /// 把成功值映射为另一种类型，失败原样传递。
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };

  /// 在失败分支上补充上下文，成功原样返回。
  Result<T> withContext(String message) => switch (this) {
        Ok<T>() => this,
        Err<T>(:final failure) => Err<T>(AppFailure(
            kind: failure.kind,
            message: message,
            code: failure.code,
            cause: failure.cause,
            stackTrace: failure.stackTrace,
          )),
      };

  /// 返回成功值，失败时抛出 [AppFailure]。
  T requireValue() => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>(:final failure) => throw failure,
      };
}

/// [Result] 的成功分支。
final class Ok<T> extends Result<T> {
  /// 包装成功值。
  const Ok(this.value);

  /// 成功值。
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

/// [Result] 的失败分支。
final class Err<T> extends Result<T> {
  /// 包装失败原因。
  const Err(this.failure);

  /// 失败原因。
  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err($failure)';
}

/// 把可能抛出 [AppFailure] 的异步调用收敛为 [Result]。
///
/// 其他异常按 [FailureKind.unknown] 归类，并保留堆栈供日志使用。
/// [code] 用于标识失败发生的操作，便于测试与日志聚合。
Future<Result<T>> guardAsync<T>(
  Future<T> Function() body, {
  String? code,
  String? message,
}) async {
  try {
    return Ok<T>(await body());
  } on AppFailure catch (failure) {
    return Err<T>(failure);
  } catch (error, stackTrace) {
    return Err<T>(AppFailure(
      kind: FailureKind.unknown,
      message: message ?? '操作失败：$error',
      code: code,
      cause: error,
      stackTrace: stackTrace,
    ));
  }
}
