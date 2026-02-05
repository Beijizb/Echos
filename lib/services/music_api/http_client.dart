import 'package:http/http.dart' as http;
import 'dart:async';

/// 音乐API专用HTTP客户端
/// 提供统一的请求接口和错误处理
class MusicApiHttpClient {
  final http.Client _client = http.Client();
  
  // 默认超时时间
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// POST 请求
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      return await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(timeout ?? defaultTimeout);
    } on TimeoutException {
      throw Exception('请求超时');
    } catch (e) {
      throw Exception('请求失败: $e');
    }
  }

  /// GET 请求
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      return await _client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout ?? defaultTimeout);
    } on TimeoutException {
      throw Exception('请求超时');
    } catch (e) {
      throw Exception('请求失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _client.close();
  }
}
