import '../../models/track.dart';
import '../../services/audio_source_service.dart';
import 'base_platform.dart';
import 'platforms/netease/netease_platform.dart';
import 'platforms/qq/qq_platform.dart';
import 'platforms/kugou/kugou_platform.dart';
import 'platforms/kuwo/kuwo_platform.dart';

/// 平台工厂类
/// 负责管理和创建各音乐平台的适配器实例
class PlatformFactory {
  static final PlatformFactory _instance = PlatformFactory._internal();
  factory PlatformFactory() => _instance;
  PlatformFactory._internal() {
    _registerPlatforms();
  }

  final Map<String, BasePlatform> _platforms = {};
  bool _initialized = false;

  /// 注册所有平台
  void _registerPlatforms() {
    if (_initialized) return;
    
    _platforms['netease'] = NeteasePlatform();
    _platforms['qq'] = QQPlatform();
    _platforms['kugou'] = KugouPlatform();
    _platforms['kuwo'] = KuwoPlatform();
    
    _initialized = true;
    print('🎵 [PlatformFactory] 已注册 ${_platforms.length} 个平台');
  }

  /// 获取平台实例
  BasePlatform? getPlatform(MusicSource source) {
    final platform = _platforms[source.name];
    if (platform == null) {
      print('⚠️ [PlatformFactory] 平台未找到: ${source.name}');
    }
    return platform;
  }

  /// 获取所有可用平台
  List<String> getAvailablePlatforms() {
    return _platforms.keys.toList();
  }

  /// 检查平台是否可用
  bool hasPlatform(String platformName) {
    return _platforms.containsKey(platformName);
  }

  /// 释放所有资源
  void dispose() {
    for (final platform in _platforms.values) {
      platform.dispose();
    }
  }
}
