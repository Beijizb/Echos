import 'package:http/http.dart' as http;
import 'dart:async';
import 'utils/api_logger.dart';

/// 音乐API专用HTTP客户端
/// 提供统一的请求接口和错误处理
class MusicApiHttpClient {
  final http.Client _client = http.Client();

  // 默认超时时间
  static const Duration defaultTimeout = Duration(seconds: 15);

  // 平台名称（用于日志）
  String? _platformName;

  /// 设置平台名称
  void setPlatformName(String name) {
    _platformName = name;
  }

  /// POST 请求
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();

    try {
      // 记录请求日志
      ApiLogger.logRequest(
        platform: _platformName ?? 'Unknown',
        method: 'POST',
        url: url,
        headers: headers,
        body: body,
      );

      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(timeout ?? defaultTimeout);

      final duration = DateTime.now().difference(startTime);

      // 记录响应日志
      ApiLogger.logResponse(
        platform: _platformName ?? 'Unknown',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
      );

      return response;
    } on TimeoutException catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      ApiLogger.logError(
        platform: _platformName ?? 'Unknown',
        operation: 'POST Request Timeout',
        error: '请求超时 (${duration.inSeconds}s)',
        stackTrace: stackTrace,
        url: url,
      );
      throw Exception('请求超时');
    } catch (e, stackTrace) {
      ApiLogger.logError(
        platform: _platformName ?? 'Unknown',
        operation: 'POST Request Failed',
        error: e,
        stackTrace: stackTrace,
        url: url,
      );
      throw Exception('请求失败: $e');
    }
  }

  /// GET 请求
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();

    try {
      // 记录请求日志
      ApiLogger.logRequest(
        platform: _platformName ?? 'Unknown',
        method: 'GET',
        url: url,
        headers: headers,
      );

      final response = await _client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout ?? defaultTimeout);

      final duration = DateTime.now().difference(startTime);

      // 记录响应日志
      ApiLogger.logResponse(
        platform: _platformName ?? 'Unknown',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
      );

      return response;
    } on TimeoutException catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      ApiLogger.logError(
        platform: _platformName ?? 'Unknown',
        operation: 'GET Request Timeout',
        error: '请求超时 (${duration.inSeconds}s)',
        stackTrace: stackTrace,
        url: url,
      );
      throw Exception('请求超时');
    } catch (e, stackTrace) {
      ApiLogger.logError(
        platform: _platformName ?? 'Unknown',
        operation: 'GET Request Failed',
        error: e,
        stackTrace: stackTrace,
        url: url,
      );
      throw Exception('请求失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _client.close();
  }
}
