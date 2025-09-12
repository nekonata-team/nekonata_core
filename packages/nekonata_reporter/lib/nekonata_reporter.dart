import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// 抽象的なエラーレポーターのインターフェース
abstract interface class ErrorReporter {
  /// 初期設定を行う。`Firebase.initializeApp()`を呼び出した後に呼び出す。
  /// もしくは、自動収集のオプトイン、オプトアウト時に呼び出す。
  ///
  /// [autoCollectionEnable]は自動収集を有効にするかどうかのフラグ。
  /// デフォルトではデバッグモードでは無効、それ以外では有効。
  /// [overrideFlutterError]がtrueの場合、Flutterのグローバルなエラーハンドラーを上書きします。
  /// 特別なカスタマイズが必要でない場合はtrueに設定することをお勧めします。
  Future<void> setUp({
    bool? autoCollectionEnable,
    bool overrideFlutterError = true,
  });

  /// エラーのレポート
  Future<void> reportError(
    Object error,
    StackTrace stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  });

  /// ログの記録
  Future<void> log(String message);
}

/// エラーレポートのコールバック関数の型定義
typedef ErrorReporterCallback = void Function(Object error, StackTrace stack);

/// Crashlyticsを使用したエラーレポーターの実装
/// これらのメソッドを呼ぶ前に、`Firebase.initializeApp()`を呼び出す必要があります。
final class FirebaseErrorReporter implements ErrorReporter {
  /// [FirebaseCrashlytics]のインスタンスを受け取るコンストラクタ
  /// インスタンスが提供されない場合、デフォルトのインスタンスを使用
  const FirebaseErrorReporter({
    this.crashlytics,
    this.onError,
  });

  /// Crashlyticsのインスタンス
  final FirebaseCrashlytics? crashlytics;

  /// [reportError]が呼ばれたときに実行されるコールバック関数
  final ErrorReporterCallback? onError;

  FirebaseCrashlytics get _instance =>
      crashlytics ?? FirebaseCrashlytics.instance;

  @override
  Future<void> setUp({
    bool? autoCollectionEnable,
    bool overrideFlutterError = true,
  }) async {
    final enable = autoCollectionEnable ?? !kDebugMode;
    await _instance.setCrashlyticsCollectionEnabled(enable);

    if (overrideFlutterError) {
      FlutterError.onError = (errorDetails) {
        _instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  @override
  Future<void> reportError(
    Object error,
    StackTrace stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    onError?.call(error, stack);
    await _instance.recordError(
      error,
      stack,
      reason: reason,
      information: information,
      fatal: fatal,
    );
  }

  @override
  Future<void> log(String message) async {
    await _instance.log(message);
  }
}
