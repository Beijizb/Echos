import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/toast_utils.dart';
import 'dart:developer' as developer;

/// 日志级别
enum LogLevel {
  debug,   // 调试信息
  info,    // 一般信息
  warning, // 警告
  error,   // 错误
  api,     // API请求/响应
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
  });

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.api:
        return '🌐';
    }
  }

  String get levelName {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.api:
        return 'API';
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[$formattedTime] $levelIcon $levelName: $message');
    if (data != null && data!.isNotEmpty) {
      buffer.write('\n  数据: ${data.toString()}');
    }
    return buffer.toString();
  }
}

/// 开发者模式服务
class DeveloperModeService extends ChangeNotifier {
  static final DeveloperModeService _instance = DeveloperModeService._internal();
  factory DeveloperModeService() => _instance;
  
  DeveloperModeService._internal();

  bool _isDeveloperMode = false;
  bool get isDeveloperMode => _isDeveloperMode;

  bool _isSearchResultMergeEnabled = true;
  bool get isSearchResultMergeEnabled => _isSearchResultMergeEnabled;

  bool _showPerformanceOverlay = false;
  bool get showPerformanceOverlay => _showPerformanceOverlay;

  bool _enableApiLogging = true;
  bool get enableApiLogging => _enableApiLogging;

  bool _enableVerboseLogging = false;
  bool get enableVerboseLogging => _enableVerboseLogging;

  int _settingsClickCount = 0;
  DateTime? _lastClickTime;

  /// 初始化完成的 Future，用于等待加载完成
  Future<void>? _initFuture;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// 初始化服务（必须在 WidgetsFlutterBinding.ensureInitialized() 之后调用）
  Future<void> initialize() {
    _initFuture ??= _loadDeveloperMode();
    return _initFuture!;
  }
  
  /// 等待初始化完成（如果尚未初始化则先初始化）
  Future<void> ensureInitialized() => initialize();

  /// 记录日志
  final List<LogEntry> _logEntries = [];
  List<LogEntry> get logEntries => List.unmodifiable(_logEntries);

  // 保持向后兼容
  final List<String> _logs = [];
  List<String> get logs => _logEntries.map((e) => e.toString()).toList();

  /// 处理设置按钮点击
  void onSettingsClicked() {
    _handleTrigger();
  }

  /// 处理版本信息点击
  void onVersionClicked() {
    _handleTrigger();
  }

  /// 统一处理触发逻辑
  void _handleTrigger() {
    final now = DateTime.now();
    
    // 如果距离上次点击超过2秒，重置计数
    if (_lastClickTime != null && now.difference(_lastClickTime!).inSeconds > 2) {
      _settingsClickCount = 0;
    }
    
    _lastClickTime = now;
    _settingsClickCount++;
    
    print('🔧 [DeveloperMode] 触发按钮点击次数: $_settingsClickCount');
    
    if (_isDeveloperMode) {
      // 如果已经开启，点击5次提示（类似于 Android 逻辑）
      if (_settingsClickCount >= 5) {
        ToastUtils.show('您已处于开发者模式');
        _settingsClickCount = 0;
      }
      return;
    }

    // 连续点击5次进入开发者模式
    if (_settingsClickCount >= 5) {
      _enableDeveloperMode();
      _settingsClickCount = 0;
    } else if (_settingsClickCount >= 2) {
      // 从第2次点击开始提示进度
      ToastUtils.show('再点击 ${5 - _settingsClickCount} 次即可开启开发者模式');
    }
  }

  /// 启用开发者模式
  Future<void> _enableDeveloperMode() async {
    _isDeveloperMode = true;
    await _saveDeveloperMode();
    addLog('🚀 开发者模式已启用');
    ToastUtils.success('开发者模式已启用');
    notifyListeners();
    print('🚀 [DeveloperMode] 开发者模式已启用');
  }

  /// 禁用开发者模式
  Future<void> disableDeveloperMode() async {
    _isDeveloperMode = false;
    await _saveDeveloperMode();
    addLog('🔒 开发者模式已禁用');
    notifyListeners();
    print('🔒 [DeveloperMode] 开发者模式已禁用');
  }

  /// 切换搜索结果合并开关
  Future<void> toggleSearchResultMerge(bool value) async {
    _isSearchResultMergeEnabled = value;
    await _saveDeveloperMode();
    addLog(value ? '🔄 已启用搜索结果合并' : '🔄 已禁用搜索结果合并');
    notifyListeners();
  }

  /// 切换性能叠加层开关
  Future<void> togglePerformanceOverlay(bool value) async {
    _showPerformanceOverlay = value;
    await _saveDeveloperMode();
    addLog('📈 已${value ? '启用' : '禁用'}性能叠加层');
    notifyListeners();
  }

  /// 切换API日志开关
  Future<void> toggleApiLogging(bool value) async {
    _enableApiLogging = value;
    await _saveDeveloperMode();
    addLog('🌐 已${value ? '启用' : '禁用'}API日志');
    notifyListeners();
  }

  /// 切换详细日志开关
  Future<void> toggleVerboseLogging(bool value) async {
    _enableVerboseLogging = value;
    await _saveDeveloperMode();
    addLog('📝 已${value ? '启用' : '禁用'}详细日志');
    notifyListeners();
  }

  /// 添加日志（新版本，支持日志级别）
  void addLogEntry(LogLevel level, String message, {Map<String, dynamic>? data}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      data: data,
    );

    _logEntries.add(entry);

    // 限制日志数量，最多保留2000条
    if (_logEntries.length > 2000) {
      _logEntries.removeAt(0);
    }

    // 在控制台输出
    if (_enableVerboseLogging || level == LogLevel.error || level == LogLevel.warning) {
      developer.log(
        message,
        name: 'DeveloperMode',
        level: _getLogLevelValue(level),
        time: entry.timestamp,
      );
    }

    notifyListeners();
  }

  int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.api:
        return 700;
    }
  }

  /// 添加日志
  void addLog(String message) {
    addLogEntry(LogLevel.info, message);
  }

  /// 添加调试日志
  void addDebugLog(String message, {Map<String, dynamic>? data}) {
    if (_enableVerboseLogging) {
      addLogEntry(LogLevel.debug, message, data: data);
    }
  }

  /// 添加警告日志
  void addWarningLog(String message, {Map<String, dynamic>? data}) {
    addLogEntry(LogLevel.warning, message, data: data);
  }

  /// 添加错误日志
  void addErrorLog(String message, {Map<String, dynamic>? data}) {
    addLogEntry(LogLevel.error, message, data: data);
  }

  /// 添加API日志
  void addApiLog(String message, {Map<String, dynamic>? data}) {
    if (_enableApiLogging) {
      addLogEntry(LogLevel.api, message, data: data);
    }
  }

  /// 清除所有日志
  void clearLogs() {
    _logEntries.clear();
    addLog('🗑️ 日志已清除');
    notifyListeners();
  }

  /// 导出日志为文本
  String exportLogs() {
    return _logEntries.map((e) => e.toString()).join('\n');
  }

  /// 按级别过滤日志
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logEntries.where((e) => e.level == level).toList();
  }

  /// 搜索日志
  List<LogEntry> searchLogs(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _logEntries.where((e) =>
      e.message.toLowerCase().contains(lowerKeyword) ||
      (e.data?.toString().toLowerCase().contains(lowerKeyword) ?? false)
    ).toList();
  }

  /// 加载开发者模式状态
  Future<void> _loadDeveloperMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDeveloperMode = prefs.getBool('developer_mode') ?? false;
      _isSearchResultMergeEnabled = prefs.getBool('search_result_merge_enabled') ?? true;
      _showPerformanceOverlay = prefs.getBool('show_performance_overlay') ?? false;
      _enableApiLogging = prefs.getBool('enable_api_logging') ?? true;
      _enableVerboseLogging = prefs.getBool('enable_verbose_logging') ?? false;
      _isInitialized = true;
      if (_isDeveloperMode) {
        print('🔧 [DeveloperMode] 从本地加载: 已启用');
        addLog('🔄 开发者模式状态已恢复');
      }
      print('🔧 [DeveloperMode] 搜索结果合并设置加载: $_isSearchResultMergeEnabled');
      print('🔧 [DeveloperMode] API日志: $_enableApiLogging, 详细日志: $_enableVerboseLogging');
      notifyListeners();
    } catch (e) {
      print('❌ [DeveloperMode] 加载失败: $e');
      _isInitialized = true; // 即使加载失败也标记为已初始化，使用默认值
      notifyListeners();
    }
  }

  /// 保存开发者模式状态
  Future<void> _saveDeveloperMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('developer_mode', _isDeveloperMode);
      await prefs.setBool('search_result_merge_enabled', _isSearchResultMergeEnabled);
      await prefs.setBool('show_performance_overlay', _showPerformanceOverlay);
      await prefs.setBool('enable_api_logging', _enableApiLogging);
      await prefs.setBool('enable_verbose_logging', _enableVerboseLogging);
      print('💾 [DeveloperMode] 状态已保存: 开发者模式=$_isDeveloperMode, 搜索合并=$_isSearchResultMergeEnabled, API日志=$_enableApiLogging');
    } catch (e) {
      print('❌ [DeveloperMode] 保存失败: $e');
    }
  }
}
