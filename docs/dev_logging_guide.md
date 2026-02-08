# 📊 开发日志系统说明

## 概述

新的日志系统提供了详细的 API 请求、响应和性能监控信息，帮助开发者快速定位问题和优化性能。

## 日志类型

### 1. 📤 请求日志

记录所有 HTTP 请求的详细信息：

```
[API] ═══════════════════════════════════════════════════════
[API] [netease] 📤 REQUEST
[API] ⏰ Time: 2026-02-08T18:30:45.123456
[API] 🔗 Method: POST
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] 📋 Headers:
[API]    Content-Type: application/x-www-form-urlencoded
[API]    User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
[API]    Cookie: ***HIDDEN***
[API] 📦 Body:
[API]    params=xxxxx&encSecKey=xxxxx
[API] ═══════════════════════════════════════════════════════
```

### 2. 📥 响应日志

记录 HTTP 响应和性能指标：

```
[API] ═══════════════════════════════════════════════════════
[API] [netease] 📥 RESPONSE
[API] ⏰ Time: 2026-02-08T18:30:45.456789
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] ✅ Status: 200
[API] ⚡ Duration: 333ms
[API] 📦 Body:
[API]    {"code":200,"result":{"songs":[...]}} (truncated, total: 5234 chars)
[API] ═══════════════════════════════════════════════════════
```

### 3. ⚡ 性能日志

记录操作性能指标：

```
[API] [netease] ⚡ Performance: search took 333ms
[API]    keyword: 周杰伦
[API]    results: 20
[API]    total: 265
```

### 4. 🎯 缓存日志

记录缓存操作：

```
[API] [Cache] 🎯 HIT Cache: getSearch - netease_周杰伦
[API] [Cache] ❌ MISS Cache: getUrl - 12345678
[API] [Cache] 💾 SET Cache: setSearch - netease_周杰伦
```

### 5. ℹ️ 信息日志

记录操作信息：

```
[API] [netease] ℹ️  开始搜索
[API]    Data:
[API]      keyword: 周杰伦
[API]      limit: 20
```

### 6. ❌ 错误日志

记录错误和堆栈跟踪：

```
[API] ═══════════════════════════════════════════════════════
[API] [netease] ❌ ERROR
[API] ⏰ Time: 2026-02-08T18:30:45.789012
[API] 🔧 Operation: search
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] 💥 Error: Exception: 请求超时
[API] 📚 Stack Trace:
[API]    #0      MusicApiHttpClient.post (package:...)
[API]    #1      NeteasePlatform.search (package:...)
[API]    ... (8 more lines)
[API] ═══════════════════════════════════════════════════════
```

## 配置

### 启用/禁用详细日志

```dart
import 'package:your_app/services/music_api/utils/api_logger.dart';

// 启用详细日志
ApiLogger.setDetailedLogsEnabled(true);

// 禁用详细日志
ApiLogger.setDetailedLogsEnabled(false);
```

默认情况下，详细日志在 **Debug 模式**下自动启用，在 **Release 模式**下自动禁用。

## 安全特性

### 自动隐藏敏感信息

日志系统会自动隐藏以下敏感信息：
- Cookie
- Authorization
- Token
- Password

示例：
```
[API] 📋 Headers:
[API]    Cookie: ***HIDDEN***
[API]    Authorization: ***HIDDEN***
```

### 内容截断

长内容会自动截断，避免日志过大：
- 请求 Body > 500 字符：截断并显示 "(truncated)"
- 响应 Body > 1000 字符：截断并显示总长度

## 使用场景

### 1. 调试 API 问题

查看完整的请求和响应，快速定位问题：
```
- 检查请求 URL 是否正确
- 检查请求参数是否完整
- 检查响应状态码
- 检查响应内容格式
```

### 2. 性能优化

通过性能日志识别慢请求：
```
[API] [netease] ⚡ Performance: search took 2345ms  ← 慢请求！
```

### 3. 缓存效率分析

查看缓存命中率：
```
[API] [Cache] 🎯 HIT Cache: getSearch - netease_周杰伦  ← 命中
[API] [Cache] ❌ MISS Cache: getUrl - 12345678         ← 未命中
```

### 4. 错误追踪

完整的错误堆栈帮助快速定位问题源头：
```
[API] ❌ ERROR
[API] 💥 Error: Exception: 请求超时
[API] 📚 Stack Trace: ...
```

## 日志示例：完整搜索流程

```
[API] [netease] ℹ️  开始搜索
[API]    Data:
[API]      keyword: 周杰伦
[API]      limit: 20

[API] [Cache] ❌ MISS Cache: getSearch - netease_周杰伦

[API] ═══════════════════════════════════════════════════════
[API] [netease] 📤 REQUEST
[API] ⏰ Time: 2026-02-08T18:30:45.123456
[API] 🔗 Method: POST
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] 📋 Headers:
[API]    Content-Type: application/x-www-form-urlencoded
[API]    User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
[API] 📦 Body:
[API]    params=xxxxx&encSecKey=xxxxx
[API] ═══════════════════════════════════════════════════════

[API] ═══════════════════════════════════════════════════════
[API] [netease] 📥 RESPONSE
[API] ⏰ Time: 2026-02-08T18:30:45.456789
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] ✅ Status: 200
[API] ⚡ Duration: 333ms
[API] 📦 Body:
[API]    {"code":200,"result":{"songs":[...],"songCount":265}}
[API] ═══════════════════════════════════════════════════════

[API] [Cache] 💾 SET Cache: setSearch - netease_周杰伦

[API] [netease] ⚡ Performance: search took 333ms
[API]    keyword: 周杰伦
[API]    results: 20
[API]    total: 265
```

## 最佳实践

1. **开发阶段**：启用详细日志，便于调试
2. **测试阶段**：保持详细日志，记录性能数据
3. **生产环境**：禁用详细日志，只保留错误日志
4. **性能分析**：关注 Duration 指标，优化慢请求
5. **缓存优化**：提高缓存命中率，减少网络请求

## 技术细节

### 实现位置

- **日志工具**：`lib/services/music_api/utils/api_logger.dart`
- **HTTP 客户端**：`lib/services/music_api/http_client.dart`
- **平台实现**：`lib/services/music_api/platforms/*/`
- **缓存管理**：`lib/services/music_api/api_cache.dart`

### 日志级别

- **INFO**：一般信息（操作开始、参数等）
- **PERFORMANCE**：性能指标
- **CACHE**：缓存操作
- **ERROR**：错误和异常

### 时间戳格式

使用 ISO 8601 格式：`2026-02-08T18:30:45.123456`

## 常见问题

### Q: 日志太多，影响性能？
A: Release 模式下自动禁用详细日志，不影响性能。

### Q: 如何只看某个平台的日志？
A: 使用 IDE 的日志过滤功能，搜索 `[netease]` 或 `[qq]` 等。

### Q: 如何导出日志？
A: 使用 `flutter logs > output.log` 命令导出到文件。

### Q: 敏感信息会泄露吗？
A: 不会，系统自动隐藏 Cookie、Authorization 等敏感字段。

## 更新日志

### v1.0.0 (2026-02-08)
- ✅ 初始版本
- ✅ 支持请求/响应日志
- ✅ 支持性能监控
- ✅ 支持缓存日志
- ✅ 支持错误追踪
- ✅ 自动隐藏敏感信息
- ✅ 内容自动截断
