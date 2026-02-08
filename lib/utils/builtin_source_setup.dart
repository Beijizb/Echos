import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 快速设置内置 API 为默认音源的工具
///
/// 使用方法：
/// 1. 在应用启动时调用 setupBuiltinSource()
/// 2. 或在设置页面添加一个"重置为内置API"按钮
class BuiltinSourceSetup {

  /// 设置内置 API 为默认音源
  static Future<void> setupBuiltinSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 创建内置音源配置
      final builtinSource = {
        'id': 'builtin_default',
        'name': '内置 API',
        'type': 'builtin', // AudioSourceType.builtin
        'url': '', // 内置API不需要URL
        'enabled': true,
        'supportedPlatforms': ['netease', 'qq', 'kugou', 'kuwo'],
      };

      // 获取现有音源列表
      final sourcesJson = prefs.getString('audio_source_list');
      List<dynamic> sources = [];

      if (sourcesJson != null) {
        sources = json.decode(sourcesJson);
      }

      // 检查是否已存在内置音源
      final hasBuiltin = sources.any((s) => s['type'] == 'builtin');

      if (!hasBuiltin) {
        // 添加内置音源到列表开头
        sources.insert(0, builtinSource);
        print('✅ 已添加内置音源');
      } else {
        print('ℹ️  内置音源已存在');
      }

      // 保存音源列表
      await prefs.setString('audio_source_list', json.encode(sources));

      // 设置内置音源为活动音源
      await prefs.setString('audio_source_active_id', 'builtin_default');

      print('✅ 内置 API 已设置为默认音源');
      print('📱 请重启应用以应用更改');

    } catch (e) {
      print('❌ 设置内置音源失败: $e');
    }
  }

  /// 在设置页面显示一个快速切换按钮
  static Widget buildQuickSwitchButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await setupBuiltinSource();

        // 显示提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已切换到内置 API，请重启应用'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      icon: const Icon(Icons.refresh),
      label: const Text('切换到内置 API'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
