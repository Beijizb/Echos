import 'dart:async';
import 'utils/api_logger.dart';

/// 缓存数据包装类
class CachedData<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CachedData({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > ttl;
  }
}

/// API缓存管理器
class ApiCache {
  static final ApiCache _instance = ApiCache._internal();
  factory ApiCache() => _instance;
  ApiCache._internal();

  // 不同类型的缓存
  final Map<String, CachedData<dynamic>> _searchCache = {};
  final Map<String, CachedData<String>> _urlCache = {};
  final Map<String, CachedData<String>> _lyricCache = {};
  final Map<String, CachedData<dynamic>> _toplistCache = {};

  // 缓存时间配置
  static const Duration searchCacheTTL = Duration(hours: 1);
  static const Duration urlCacheTTL = Duration(hours: 6);
  static const Duration lyricCacheTTL = Duration(days: 30);
  static const Duration toplistCacheTTL = Duration(minutes: 30);

  /// 获取搜索缓存
  T? getSearch<T>(String key) {
    final result = _get(_searchCache, key);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'getSearch',
      key: key,
      hit: result != null,
    );
    return result;
  }

  /// 设置搜索缓存
  void setSearch<T>(String key, T data) {
    _set(_searchCache, key, data, searchCacheTTL);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'setSearch',
      key: key,
      hit: null,
    );
  }

  /// 获取URL缓存
  String? getUrl(String key) {
    final result = _get(_urlCache, key);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'getUrl',
      key: key,
      hit: result != null,
    );
    return result;
  }

  /// 设置URL缓存
  void setUrl(String key, String data) {
    _set(_urlCache, key, data, urlCacheTTL);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'setUrl',
      key: key,
      hit: null,
    );
  }

  /// 获取歌词缓存
  String? getLyric(String key) {
    final result = _get(_lyricCache, key);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'getLyric',
      key: key,
      hit: result != null,
    );
    return result;
  }

  /// 设置歌词缓存
  void setLyric(String key, String data) {
    _set(_lyricCache, key, data, lyricCacheTTL);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'setLyric',
      key: key,
      hit: null,
    );
  }

  /// 获取榜单缓存
  T? getToplist<T>(String key) {
    final result = _get(_toplistCache, key);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'getToplist',
      key: key,
      hit: result != null,
    );
    return result;
  }

  /// 设置榜单缓存
  void setToplist<T>(String key, T data) {
    _set(_toplistCache, key, data, toplistCacheTTL);
    ApiLogger.logCache(
      platform: 'Cache',
      operation: 'setToplist',
      key: key,
      hit: null,
    );
  }

  /// 通用获取方法
  T? _get<T>(Map<String, CachedData<dynamic>> cache, String key) {
    final cached = cache[key];
    if (cached != null && !cached.isExpired) {
      print('💾 [ApiCache] 命中缓存: $key');
      return cached.data as T;
    }
    if (cached != null && cached.isExpired) {
      cache.remove(key);
      print('⏰ [ApiCache] 缓存过期: $key');
    }
    return null;
  }

  /// 通用设置方法
  void _set<T>(
    Map<String, CachedData<dynamic>> cache,
    String key,
    T data,
    Duration ttl,
  ) {
    cache[key] = CachedData(
      data: data,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
    print('💾 [ApiCache] 设置缓存: $key (TTL: ${ttl.inMinutes}分钟)');
  }

  /// 清空所有缓存
  void clearAll() {
    _searchCache.clear();
    _urlCache.clear();
    _lyricCache.clear();
    _toplistCache.clear();
    print('🗑️ [ApiCache] 已清空所有缓存');
  }

  /// 清空搜索缓存
  void clearSearch() {
    _searchCache.clear();
    print('🗑️ [ApiCache] 已清空搜索缓存');
  }

  /// 获取缓存统计信息
  Map<String, int> getStats() {
    return {
      'search': _searchCache.length,
      'url': _urlCache.length,
      'lyric': _lyricCache.length,
      'toplist': _toplistCache.length,
    };
  }
}
