# 内置音乐 API 集成

## 概述

本项目实现了内置音乐 API 功能,允许应用直接使用内置的音乐平台接口(网易云、QQ 音乐、酷狗音乐、酷我音乐),无需依赖外部服务器。

## 架构设计

### 1. 核心组件

```
os/lib/services/music_api/
├── platform_factory.dart          # 平台工厂,管理所有音乐平台适配器
├── base_platform.dart             # 平台基类,定义统一接口
└── platforms/
    ├── netease/                   # 网易云音乐平台
    │   └── netease_platform.dart
    ├── qq/                        # QQ 音乐平台
    │   └── qq_platform.dart
    ├── kugou/                     # 酷狗音乐平台
    │   └── kugou_platform.dart
    └── kuwo/                      # 酷我音乐平台
        └── kuwo_platform.dart
```

### 2. 设计模式

#### 2.1 工厂模式 (Factory Pattern)
[`PlatformFactory`](os/lib/services/music_api/platform_factory.dart) 使用单例模式和工厂模式管理所有平台适配器:

```dart
class PlatformFactory {
  static final PlatformFactory _instance = PlatformFactory._internal();
  final Map<String, BasePlatform> _platforms = {};
  
  factory PlatformFactory() => _instance;
  
  BasePlatform? getPlatform(MusicSource source) {
    return _platforms[source.name];
  }
}
```

#### 2.2 策略模式 (Strategy Pattern)
每个平台适配器实现 [`BasePlatform`](os/lib/services/music_api/base_platform.dart) 接口,提供统一的 API:

```dart
abstract class BasePlatform {
  Future<Map<String, dynamic>> search(String keyword, {int page = 1, int limit = 30});
  Future<Map<String, dynamic>> getSongUrl(String songId, String quality);
  Future<String> getLyric(String songId);
  Future<Map<String, dynamic>> getSongDetail(String songId);
}
```

### 3. 数据流

```
用户请求
    ↓
PlaylistService
    ↓
PlatformFactory.getPlatform()
    ↓
具体平台适配器 (NeteasePlatform/QQPlatform/KugouPlatform/KuwoPlatform)
    ↓
HTTP 请求到音乐平台 API
    ↓
数据解析和格式化
    ↓
返回统一格式的结果
```

## 平台适配器实现

### 1. 网易云音乐 (Netease)

**文件**: [`os/lib/services/music_api/platforms/netease/netease_platform.dart`](os/lib/services/music_api/platforms/netease/netease_platform.dart)

**特性**:
- 搜索功能完整
- 支持多种音质(标准、较高、极高、无损)
- 歌词支持翻译

**API 端点**:
- 搜索: `https://music.163.com/api/search/get/web`
- 歌曲 URL: `https://music.163.com/api/song/enhance/player/url`
- 歌词: `https://music.163.com/api/song/lyric`

### 2. QQ 音乐 (QQ Music)

**文件**: [`os/lib/services/music_api/platforms/qq/qq_platform.dart`](os/lib/services/music_api/platforms/qq/qq_platform.dart)

**特性**:
- VIP 歌曲标识
- 试听限制处理
- 多音质支持

**API 端点**:
- 搜索: `https://c.y.qq.com/soso/fcgi-bin/client_search_cp`
- 歌曲 URL: `https://u.y.qq.com/cgi-bin/musicu.fcg`
- 歌词: `https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg`

### 3. 酷狗音乐 (Kugou)

**文件**: [`os/lib/services/music_api/platforms/kugou/kugou_platform.dart`](os/lib/services/music_api/platforms/kugou/kugou_platform.dart)

**特性**:
- 音质选项(标准、HQ、SQ)
- 封面图片处理
- Hash 值管理

**API 端点**:
- 搜索: `http://songsearch.kugou.com/song_search_v2`
- 歌曲详情: `http://www.kugou.com/yy/index.php`
- 歌词: `http://www.kugou.com/yy/index.php`

### 4. 酷我音乐 (Kuwo)

**文件**: [`os/lib/services/music_api/platforms/kuwo/kuwo_platform.dart`](os/lib/services/music_api/platforms/kuwo/kuwo_platform.dart)

**特性**:
- 特殊的 API 响应格式
- 自定义 User-Agent 处理
- 歌词格式转换

**API 端点**:
- 搜索: `http://www.kuwo.cn/api/www/search/searchMusicBykeyWord`
- 歌曲 URL: `http://www.kuwo.cn/api/v1/www/music/playUrl`
- 歌词: `http://m.kuwo.cn/newh5/singles/songinfoandlrc`

## 使用方法

### 1. 在设置中添加内置音源

1. 打开应用设置
2. 进入"音源设置"
3. 点击"添加音源"
4. 选择"内置 API"类型
5. 输入名称(可选)
6. 保存

### 2. 代码集成示例

#### 搜索歌曲

```dart
final factory = PlatformFactory();
final platform = factory.getPlatform(MusicSource.netease);

if (platform != null) {
  final result = await platform.search('周杰伦', page: 1, limit: 30);
  print('搜索结果: ${result['songs']}');
}
```

#### 获取播放地址

```dart
final songUrl = await platform.getSongUrl('12345', 'high');
print('播放地址: $songUrl');
```

#### 获取歌词

```dart
final lyric = await platform.getLyric('12345');
print('歌词: $lyric');
```

## 配置

### 音源类型枚举

在 [`os/lib/models/audio_source_config.dart`](os/lib/models/audio_source_config.dart) 中定义:

```dart
enum AudioSourceType {
  builtin,    // 内置 API
  lxmusic,    // 洛雪音乐脚本
  tunehub,    // TuneHub
  omniparse,  // OmniParse / 自定义
}
```

### 音源配置模型

```dart
class AudioSourceConfig {
  final String id;
  final AudioSourceType type;
  final String name;
  final String url;  // 内置类型为空字符串
  // ... 其他字段
}
```

## 错误处理

所有平台适配器都实现了统一的错误处理机制:

```dart
try {
  final result = await platform.search(keyword);
  return result;
} catch (e) {
  debugPrint('搜索失败: $e');
  return {'error': '搜索失败: $e'};
}
```

### 常见错误类型

1. **网络错误**: 网络连接失败或超时
2. **API 限流**: 请求过于频繁被限流
3. **数据解析错误**: API 响应格式变化
4. **版权限制**: 歌曲不可用或需要 VIP

## 性能优化

### 1. 请求缓存

使用 HTTP 缓存减少重复请求:

```dart
final dio = Dio(BaseOptions(
  headers: {
    'Cache-Control': 'max-age=3600',
  },
));
```

### 2. 并发控制

限制同时进行的请求数量,避免过载:

```dart
final limit = pLimit(5); // 最多 5 个并发请求
```

### 3. 超时设置

设置合理的超时时间:

```dart
final dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 10),
));
```

## UI 集成

### 设置界面

设置界面在 [`os/lib/pages/settings_page/audio_source_settings_page.dart`](os/lib/pages/settings_page/audio_source_settings_page.dart) 中实现。

#### 支持的 UI 框架

1. **Material Design** (Android/Windows/Linux)
2. **Cupertino** (iOS/macOS)
3. **Fluent Design** (Windows 11)

#### 内置音源 UI 特性

- 不需要输入 URL
- 显示信息提示框说明使用内置接口
- 可自定义名称
- 类型选择后不可更改(编辑模式)

### Material Design 实现

```dart
if (_selectedType == AudioSourceType.builtin) ...[
  TextField(
    controller: _nameController,
    decoration: InputDecoration(
      labelText: '名称 (可选)',
      hintText: '给音源起个名字',
    ),
  ),
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '此音源直接使用应用程序内置的音乐平台接口，无需配置服务器地址。',
          ),
        ),
      ],
    ),
  ),
]
```

## 测试

详细的测试指南请参阅 [`BUILTIN_API_TEST_GUIDE.md`](os/BUILTIN_API_TEST_GUIDE.md)。

### 快速测试

```bash
# 运行所有测试
cd os
flutter test

# 运行特定测试
flutter test test/services/music_api/platform_factory_test.dart
```

## 维护和更新

### 添加新平台

1. 在 `os/lib/services/music_api/platforms/` 创建新目录
2. 创建平台类继承 [`BasePlatform`](os/lib/services/music_api/base_platform.dart)
3. 实现所有必需方法
4. 在 [`PlatformFactory`](os/lib/services/music_api/platform_factory.dart) 中注册

示例:

```dart
class NewPlatform extends BasePlatform {
  @override
  Future<Map<String, dynamic>> search(String keyword, {int page = 1, int limit = 30}) async {
    // 实现搜索逻辑
  }
  
  // ... 实现其他方法
}

// 在 PlatformFactory 中注册
void _registerPlatforms() {
  _platforms['new_platform'] = NewPlatform();
}
```

### API 变更处理

当音乐平台 API 发生变化时:

1. 更新对应平台适配器的 API 端点
2. 调整数据解析逻辑
3. 运行测试确保功能正常
4. 更新文档

## 安全和隐私

### 1. 数据传输

- 使用 HTTPS 加密传输(如平台支持)
- 不存储用户的搜索历史(除非用户明确同意)

### 2. API 密钥

- 不在代码中硬编码 API 密钥
- 使用环境变量或安全存储

### 3. 用户隐私

- 不收集用户个人信息
- 不追踪用户行为
- 本地处理所有数据

## 常见问题 (FAQ)

### Q: 为什么某些歌曲无法播放?

**A**: 可能的原因:
- 版权限制(地区或 VIP 限制)
- 歌曲已下架
- 播放链接已过期(需要重新获取)

### Q: 搜索结果不准确怎么办?

**A**: 尝试:
- 使用更精确的关键词
- 切换到其他音乐平台
- 使用完整的歌曲名或歌手名

### Q: 如何处理 API 限流?

**A**: 
- 减少请求频率
- 实现请求缓存
- 在多个平台间负载均衡

### Q: 内置 API 和外部服务器有什么区别?

**A**:
- **内置 API**: 直接调用音乐平台接口,无需中间服务器,响应更快,但可能受到平台限制
- **外部服务器**: 通过中间服务器代理请求,可以绕过某些限制,但增加了延迟和依赖

## 贡献指南

欢迎贡献代码!请遵循以下步骤:

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/new-platform`)
3. 提交更改 (`git commit -am 'Add new platform'`)
4. 推送到分支 (`git push origin feature/new-platform`)
5. 创建 Pull Request

### 代码规范

- 遵循 Dart 代码风格指南
- 添加适当的注释和文档
- 编写单元测试
- 更新相关文档

## 许可证

本项目遵循项目主许可证。

## 联系方式

如有问题或建议,请通过 GitHub Issues 联系我们。

## 更新日志

### v1.0.0 (2026-02-05)

- ✅ 完成 PlaylistService 内置 API 集成
- ✅ 实现网易云音乐平台适配器
- ✅ 实现 QQ 音乐平台适配器
- ✅ 实现酷狗音乐平台适配器
- ✅ 实现酷我音乐平台适配器
- ✅ 添加内置 API 设置界面
- ✅ 支持 Material、Cupertino、Fluent 三种 UI 框架
- ✅ 创建测试指南和文档

## 致谢

感谢以下开源项目和资源:

- Flutter 框架
- Dio HTTP 客户端
- 各音乐平台的公开 API

---

**注意**: 本项目仅供学习和研究使用。请遵守各音乐平台的服务条款和版权法律。不得用于商业用途。