# 内置音乐API模块

这个模块提供了内置的音乐平台API支持，无需依赖外部服务即可实现音乐搜索、播放、歌词等功能。

## 📁 目录结构

```
music_api/
├── README.md                      # 本文档
├── platform_factory.dart          # 平台工厂
├── base_platform.dart             # 基础平台适配器
├── http_client.dart               # HTTP客户端
├── api_cache.dart                 # API缓存管理
├── models/                        # 数据模型
│   ├── search_response.dart       # 搜索响应
│   └── lyric_data.dart           # 歌词数据
├── crypto/                        # 加密工具
│   ├── crypto_utils.dart         # 通用加密工具
│   └── netease_crypto.dart       # 网易云加密
└── platforms/                     # 平台实现
    ├── netease/                   # 网易云音乐
    │   └── netease_platform.dart
    ├── qq/                        # QQ音乐
    │   └── qq_platform.dart
    ├── kugou/                     # 酷狗音乐
    │   └── kugou_platform.dart
    └── kuwo/                      # 酷我音乐
        └── kuwo_platform.dart
```

## 🚀 使用方法

### 1. 获取平台实例

```dart
import 'package:cyrene_music/services/music_api/platform_factory.dart';
import 'package:cyrene_music/models/track.dart';

// 获取网易云音乐平台
final platform = PlatformFactory().getPlatform(MusicSource.netease);
```

### 2. 搜索歌曲

```dart
final result = await platform?.search('周杰伦', limit: 20);
if (result != null) {
  print('找到 ${result.tracks.length} 首歌曲');
  for (final track in result.tracks) {
    print('${track.name} - ${track.artists}');
  }
}
```

### 3. 获取歌曲详情

```dart
final songDetail = await platform?.getSongDetail(
  347230,  // 歌曲ID
  AudioQuality.exhigh,  // 音质
);

if (songDetail != null) {
  print('歌曲名: ${songDetail.name}');
  print('播放URL: ${songDetail.url}');
  print('歌词: ${songDetail.lyric}');
}
```

### 4. 获取榜单

```dart
final toplists = await platform?.getToplists();
for (final toplist in toplists) {
  print('${toplist.name}: ${toplist.tracks.length} 首歌曲');
}
```

## 🎯 支持的平台

| 平台 | 状态 | 功能 |
|------|------|------|
| 网易云音乐 | ✅ 已实现 | 搜索、歌曲详情、URL、歌词、榜单、歌单 |
| QQ音乐 | ✅ 已实现 | 搜索、歌曲详情、URL、歌词、榜单、歌单 |
| 酷狗音乐 | ✅ 已实现 | 搜索、歌曲详情、URL、歌词、榜单、歌单 |
| 酷我音乐 | ✅ 已实现 | 搜索、歌曲详情、URL、歌词、榜单、歌单 |

## 💾 缓存机制

模块内置了智能缓存系统，减少重复请求：

- **搜索结果**: 缓存1小时
- **歌曲URL**: 缓存6小时
- **歌词**: 缓存30天
- **榜单**: 缓存30分钟

```dart
import 'package:cyrene_music/services/music_api/api_cache.dart';

// 清空所有缓存
ApiCache().clearAll();

// 获取缓存统计
final stats = ApiCache().getStats();
print('搜索缓存: ${stats['search']} 条');
```

## 🔐 加密说明

### 网易云音乐

使用 Weapi 加密方式：
1. AES-128-CBC 加密（两次）
2. RSA 公钥加密随机密钥

实现位置: [`crypto/netease_crypto.dart`](crypto/netease_crypto.dart)

## 📝 添加新平台

1. 在 `platforms/` 下创建新目录
2. 创建平台类继承 [`BasePlatform`](base_platform.dart)
3. 实现所有抽象方法
4. 在 [`PlatformFactory`](platform_factory.dart) 中注册

示例：

```dart
class NewPlatform extends BasePlatform {
  @override
  String get name => 'newplatform';

  @override
  Future<SearchResponse> search(String keyword, {int limit = 20}) async {
    // 实现搜索逻辑
  }
  
  // 实现其他方法...
}
```

## ⚠️ 注意事项

1. **API变化**: 音乐平台API可能随时变化，需要定期维护
2. **请求频率**: 避免过于频繁的请求，可能导致IP被封
3. **版权问题**: 仅供学习交流使用，请勿用于商业用途

## 🔧 依赖包

```yaml
dependencies:
  http: ^1.2.0
  crypto: ^3.0.3
  pointycastle: ^3.7.3  # RSA加密
```

## 📊 性能指标

- 搜索响应时间: < 1秒
- 歌曲URL获取: < 2秒
- 缓存命中率: > 60%
- API可用性: > 95%
