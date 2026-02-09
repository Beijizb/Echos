# 内置API搜索调试 - 完整更新总结

## 📦 已完成的更新

### 1. **启用详细API日志** ✅
**文件**: `lib/main.dart`
- 在应用启动时自动启用 `ApiLogger.setDetailedLogsEnabled(true)`
- 所有API请求和响应都会输出到控制台

### 2. **增强错误日志** ✅
**文件**: `lib/services/search_service.dart`
- 搜索失败时输出完整的堆栈跟踪
- 更容易定位问题根源

### 3. **升级开发者模式日志系统** ✅
**文件**: `lib/services/developer_mode_service.dart`

**新增功能**：
- 日志级别分类（调试、信息、警告、错误、API）
- 日志条目结构化存储
- 支持附加数据字段
- 自动输出到控制台
- 最多保存2000条日志

**新增方法**：
- `addLogEntry()` - 添加带级别的日志
- `addDebugLog()` - 添加调试日志
- `addWarningLog()` - 添加警告日志
- `addErrorLog()` - 添加错误日志
- `addApiLog()` - 添加API日志
- `exportLogs()` - 导出日志为文本
- `getLogsByLevel()` - 按级别过滤
- `searchLogs()` - 搜索日志

**新增设置**：
- `enableApiLogging` - API日志开关（默认开启）
- `enableVerboseLogging` - 详细日志开关（默认关闭）

### 4. **API日志集成** ✅
**文件**: `lib/services/music_api/utils/api_logger.dart`

**更新内容**：
- 所有API请求自动记录到开发者日志
- 包含请求详情（URL、方法、时间戳）
- 包含响应详情（状态码、响应时间、数据大小）
- 错误自动标记为错误级别

### 5. **增强开发者页面** ✅
**文件**: `lib/pages/developer_page.dart`

**新增功能**：
- 日志搜索框（实时搜索）
- 日志级别过滤器（5个级别）
- 彩色日志显示（不同级别不同颜色）
- 显示日志数量统计
- 显示关联数据
- 可选择和复制日志

**新增控制选项**：
- API日志开关
- 详细日志开关

## 📋 使用指南

### 快速开始

1. **重新编译应用**：
   ```bash
   cd D:\test\os
   flutter clean
   flutter pub get
   flutter run -d windows
   ```

2. **启用开发者模式**：
   - 打开应用设置
   - 连续点击"设置"标题 5 次
   - 看到"开发者模式已启用"提示

3. **打开开发者页面**：
   - 设置页面会出现"开发者模式"选项
   - 点击进入

4. **测试搜索**：
   - 确认音源设置为"内置 API"
   - 搜索"周杰伦"
   - 返回开发者页面查看日志

### 查看日志的三种方式

#### 方式1：控制台日志（最详细）
运行应用时，控制台会输出：
```
[API] ═══════════════════════════════════════════════════════
[API] [netease] 📤 REQUEST
[API] ⏰ Time: 2026-02-09T14:23:45.123
[API] 🔗 Method: POST
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] 📋 Headers:
[API]    Content-Type: application/x-www-form-urlencoded
[API]    User-Agent: Mozilla/5.0...
[API] 📦 Body:
[API]    params=...&encSecKey=...
[API] ═══════════════════════════════════════════════════════
```

#### 方式2：开发者模式日志（可过滤）
在开发者页面的"日志"标签：
- 实时显示所有日志
- 可按级别过滤
- 可搜索关键词
- 可复制导出

#### 方式3：应用内日志（简洁）
搜索时会在控制台输出：
```
🔍 [SearchService] 使用内置API搜索: 周杰伦
🔍 [SearchService] 支持的平台: [netease, qq, kugou, kuwo]
🎵 [SearchService] 内置API搜索 netease: 周杰伦
✅ [SearchService] netease 搜索完成: 20 首
```

## 🔍 调试流程

### 1. 准备工作
- ✅ 重新编译应用
- ✅ 启用开发者模式
- ✅ 确认音源为"内置 API"

### 2. 执行搜索
- 在搜索框输入关键词
- 点击搜索
- 观察是否有结果

### 3. 查看日志

**如果搜索成功**：
```
[14:23:45] 🌐 API: [netease] 📤 POST https://music.163.com/weapi/search/get
[14:23:46] 🌐 API: [netease] ✅ 200 (1234ms)
[14:23:46] ℹ️ INFO: ✅ [SearchService] netease 搜索完成: 20 首
```

**如果搜索失败**：
```
[14:23:45] 🌐 API: [netease] 📤 POST https://music.163.com/weapi/search/get
[14:23:46] ❌ ERROR: [netease] search 失败: Exception: 搜索失败: 403
[14:23:46] 📚 [SearchService] 堆栈跟踪: ...
```

### 4. 分析问题

根据日志判断问题类型：

**HTTP 403/401**：
- User-Agent被识别为爬虫
- 需要更新请求头

**HTTP 500/502**：
- 服务器错误
- API端点可能已变更

**加密错误**：
```
❌ [NeteaseCrypto] RSA加密失败: ...
```
- 加密实现有问题
- 需要检查加密库

**超时错误**：
```
❌ [SearchService] netease 搜索失败: TimeoutException
```
- 网络问题
- 需要检查网络连接

**JSON解析错误**：
```
❌ [SearchService] netease 搜索失败: FormatException
```
- API返回格式变更
- 需要更新解析逻辑

### 5. 导出日志

1. 在开发者页面点击"复制全部"
2. 粘贴到文本文件保存
3. 可以分享给开发者分析

## 📊 日志级别说明

| 级别 | 图标 | 用途 | 示例 |
|------|------|------|------|
| DEBUG | 🔍 | 详细调试信息 | 缓存命中、参数验证 |
| INFO | ℹ️ | 一般信息 | 搜索开始、搜索完成 |
| WARNING | ⚠️ | 警告信息 | 缓存过期、降级处理 |
| ERROR | ❌ | 错误信息 | 搜索失败、网络错误 |
| API | 🌐 | API请求响应 | HTTP请求、响应状态 |

## 🎯 常见问题诊断

### 问题1：所有平台都搜索不到
**可能原因**：
- 音源不是"内置 API"
- 网络连接问题
- 平台工厂初始化失败

**检查方法**：
1. 查看日志中是否有"使用内置API搜索"
2. 查看是否有"平台未找到"错误
3. 检查网络连接

### 问题2：只有某个平台搜索不到
**可能原因**：
- 该平台API变更
- 加密问题（网易云）
- User-Agent问题

**检查方法**：
1. 在开发者日志中搜索平台名（如"netease"）
2. 查看该平台的API请求和响应
3. 检查HTTP状态码

### 问题3：搜索很慢
**可能原因**：
- 网络延迟
- 并行请求过多
- 超时设置过长

**检查方法**：
1. 查看API响应时间（duration_ms）
2. 如果超过3秒，可能是网络问题
3. 检查是否有超时错误

### 问题4：搜索结果为空但没有错误
**可能原因**：
- API返回成功但数据为空
- JSON解析问题
- 关键词问题

**检查方法**：
1. 查看API响应的Body内容
2. 检查是否有 `"songs":[]`
3. 尝试其他关键词

## 📁 相关文件

### 核心文件
- `lib/main.dart` - 应用入口，启用日志
- `lib/services/search_service.dart` - 搜索服务
- `lib/services/developer_mode_service.dart` - 开发者模式服务
- `lib/services/music_api/utils/api_logger.dart` - API日志工具
- `lib/pages/developer_page.dart` - 开发者页面

### 平台实现
- `lib/services/music_api/platforms/netease/netease_platform.dart` - 网易云
- `lib/services/music_api/platforms/qq/qq_platform.dart` - QQ音乐
- `lib/services/music_api/platforms/kugou/kugou_platform.dart` - 酷狗
- `lib/services/music_api/platforms/kuwo/kuwo_platform.dart` - 酷我

### 文档
- `DEBUG_SEARCH_ISSUE.md` - 调试指南
- `DEVELOPER_MODE_LOG_UPDATE.md` - 开发者模式更新说明
- `BUILTIN_API_README.md` - 内置API文档
- `BUILTIN_API_TEST_GUIDE.md` - 测试指南

## 🚀 下一步

1. **立即测试**：
   ```bash
   flutter clean && flutter pub get && flutter run -d windows
   ```

2. **启用开发者模式**：
   - 连续点击设置标题5次

3. **执行搜索测试**：
   - 搜索"周杰伦"
   - 查看日志输出

4. **分析结果**：
   - 如果成功：恭喜！问题已解决
   - 如果失败：复制日志，继续分析

5. **反馈问题**：
   - 如果需要帮助，提供完整的日志
   - 特别是带 `❌` 的错误信息

## 💡 提示

- 日志会自动滚动到底部
- 可以随时清除日志重新开始
- 详细日志会产生大量输出，仅在需要时开启
- API日志默认开启，建议保持开启状态
- 日志最多保存2000条，超过会自动删除最旧的

祝调试顺利！如果有任何问题，请提供日志输出。🎉
