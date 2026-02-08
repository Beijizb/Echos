import 'package:flutter/foundation.dart';

/// API 日志工具类
/// 提供详细的请求和响应日志
class ApiLogger {
  static const String _tag = '[API]';
  static bool _enableDetailedLogs = kDebugMode; // 默认在 Debug 模式下启用详细日志

  /// 设置是否启用详细日志
  static void setDetailedLogsEnabled(bool enabled) {
    _enableDetailedLogs = enabled;
  }

  /// 记录请求开始
  static void logRequest({
    required String platform,
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!_enableDetailedLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    print('');
    print('$_tag ═══════════════════════════════════════════════════════');
    print('$_tag [$platform] 📤 REQUEST');
    print('$_tag ⏰ Time: $timestamp');
    print('$_tag 🔗 Method: $method');
    print('$_tag 🌐 URL: $url');

    if (headers != null && headers.isNotEmpty) {
      print('$_tag 📋 Headers:');
      headers.forEach((key, value) {
        // 隐藏敏感信息
        if (key.toLowerCase().contains('cookie') ||
            key.toLowerCase().contains('authorization')) {
          print('$_tag    $key: ***HIDDEN***');
        } else {
          print('$_tag    $key: $value');
        }
      });
    }

    if (body != null) {
      print('$_tag 📦 Body:');
      final bodyStr = body.toString();
      if (bodyStr.length > 500) {
        print('$_tag    ${bodyStr.substring(0, 500)}... (truncated)');
      } else {
        print('$_tag    $bodyStr');
      }
    }
    print('$_tag ═══════════════════════════════════════════════════════');
  }

  /// 记录响应成功
  static void logResponse({
    required String platform,
    required String url,
    required int statusCode,
    required String body,
    required Duration duration,
  }) {
    if (!_enableDetailedLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    print('');
    print('$_tag ═══════════════════════════════════════════════════════');
    print('$_tag [$platform] 📥 RESPONSE');
    print('$_tag ⏰ Time: $timestamp');
    print('$_tag 🌐 URL: $url');
    print('$_tag ✅ Status: $statusCode');
    print('$_tag ⚡ Duration: ${duration.inMilliseconds}ms');

    if (body.isNotEmpty) {
      print('$_tag 📦 Body:');
      if (body.length > 1000) {
        print('$_tag    ${body.substring(0, 1000)}... (truncated, total: ${body.length} chars)');
      } else {
        print('$_tag    $body');
      }
    }
    print('$_tag ═══════════════════════════════════════════════════════');
  }

  /// 记录错误
  static void logError({
    required String platform,
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
    String? url,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    print('');
    print('$_tag ═══════════════════════════════════════════════════════');
    print('$_tag [$platform] ❌ ERROR');
    print('$_tag ⏰ Time: $timestamp');
    print('$_tag 🔧 Operation: $operation');
    if (url != null) {
      print('$_tag 🌐 URL: $url');
    }
    print('$_tag 💥 Error: $error');

    if (_enableDetailedLogs && stackTrace != null) {
      print('$_tag 📚 Stack Trace:');
      final stackLines = stackTrace.toString().split('\n');
      for (var i = 0; i < stackLines.length && i < 10; i++) {
        print('$_tag    ${stackLines[i]}');
      }
      if (stackLines.length > 10) {
        print('$_tag    ... (${stackLines.length - 10} more lines)');
      }
    }
    print('$_tag ═══════════════════════════════════════════════════════');
  }

  /// 记录信息
  static void logInfo({
    required String platform,
    required String message,
    Map<String, dynamic>? data,
  }) {
    if (!_enableDetailedLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    print('$_tag [$platform] ℹ️  $message');

    if (data != null && data.isNotEmpty) {
      print('$_tag    Data:');
      data.forEach((key, value) {
        print('$_tag      $key: $value');
      });
    }
  }

  /// 记录性能指标
  static void logPerformance({
    required String platform,
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metrics,
  }) {
    if (!_enableDetailedLogs) return;

    print('$_tag [$platform] ⚡ Performance: $operation took ${duration.inMilliseconds}ms');

    if (metrics != null && metrics.isNotEmpty) {
      metrics.forEach((key, value) {
        print('$_tag    $key: $value');
      });
    }
  }

  /// 记录缓存操作
  static void logCache({
    required String platform,
    required String operation,
    required String key,
    bool? hit,
  }) {
    if (!_enableDetailedLogs) return;

    final hitStr = hit == true ? '🎯 HIT' : hit == false ? '❌ MISS' : '💾 SET';
    print('$_tag [$platform] $hitStr Cache: $operation - $key');
  }
}
