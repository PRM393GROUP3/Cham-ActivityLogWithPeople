import 'package:flutter/foundation.dart';

enum AppEnv { dev, prod }

/// Compile-time config, supplied per environment via
/// `--dart-define-from-file=env/<dev|prod>.json`. See `env/README.md`.
/// Falls back to dev values when no file is passed.
class Env {
  static const _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  static final AppEnv appEnv = AppEnv.values.byName(_appEnv);
  static bool get isProd => appEnv == AppEnv.prod;

  static String get apiBaseUrl {
    final uri = Uri.parse(_apiBaseUrl);
    // The Android emulator reaches the host machine's localhost via 10.0.2.2.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }
    return _apiBaseUrl;
  }

  static String get wsBaseUrl => apiBaseUrl.replaceFirst(RegExp('^http'), 'ws');
}
