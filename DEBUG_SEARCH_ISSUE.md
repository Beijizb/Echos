# 调试内置API搜索问题指南

## 已启用的调试功能

我已经在代码中启用了详细的API日志。现在运行应用时会输出详细的调试信息。

## 如何查看日志

### 方法1：在IDE中查看（推荐）

1. **使用 VS Code**:
   - 打开项目文件夹
   - 按 `F5` 或点击"运行和调试"
   - 在"调试控制台"中查看日志输出

2. **使用 Android Studio / IntelliJ IDEA**:
   - 打开项目
   - 点击"Run" → "Debug"
   - 在"Run"窗口查看日志输出

### 方法2：命令行运行

```bash
cd D:\test\os
flutter run -d windows
```

日志会直接输出到命令行。

### 方法3：查看日志文件

应用启动时会创建日志文件，路径通常在：
```
D:\work\cyrene_music\build\windows\x64\runner\Debug\
```

## 要查找的关键日志

运行应用并尝试搜索后，在日志中查找以下内容：

### 1. 搜索开始标记
```
🔍 [SearchService] 使用内置API搜索: [你的搜索关键词]
🔍 [SearchService] 支持的平台: [netease, qq, kugou, kuwo]
```

### 2. 各平台搜索日志
```
🎵 [SearchService] 内置API搜索 netease: [关键词]
🎵 [SearchService] 内置API搜索 qq: [关键词]
🎵 [SearchService] 内置API搜索 kugou: [关键词]
🎵 [SearchService] 内置API搜索 kuwo: [关键词]
```

### 3. API请求详情（最重要）
```
[API] ═══════════════════════════════════════════════════════
[API] [netease] 📤 REQUEST
[API] ⏰ Time: [时间戳]
[API] 🔗 Method: POST
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] 📋 Headers:
[API]    Content-Type: application/x-www-form-urlencoded
[API]    User-Agent: Mozilla/5.0...
[API] 📦 Body:
[API]    params=...&encSecKey=...
[API] ═══════════════════════════════════════════════════════
```

### 4. API响应详情
```
[API] ═══════════════════════════════════════════════════════
[API] [netease] 📥 RESPONSE
[API] ⏰ Time: [时间戳]
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] ✅ Status: 200
[API] ⚡ Duration: [毫秒]ms
[API] 📦 Body:
[API]    {"code":200,"result":{"songs":[...]}}
[API] ═══════════════════════════════════════════════════════
```

### 5. 错误信息（如果有）
```
❌ [SearchService] netease 搜索失败: [错误信息]
📚 [SearchService] 堆栈跟踪: [详细堆栈]
```

或者：

```
[API] ═══════════════════════════════════════════════════════
[API] [netease] ❌ ERROR
[API] ⏰ Time: [时间戳]
[API] 🔧 Operation: search
[API] 🌐 URL: https://music.163.com/weapi/search/get
[API] 💥 Error: [错误详情]
[API] 📚 Stack Trace:
[API]    [堆栈信息]
[API] ═══════════════════════════════════════════════════════
```

### 6. 加密错误（如果有）
```
❌ [NeteaseCrypto] Weapi加密失败: [错误]
❌ [NeteaseCrypto] AES加密失败: [错误]
❌ [NeteaseCrypto] RSA加密失败: [错误]
```

## 测试步骤

1. **重新编译应用**（重要！）:
   ```bash
   cd D:\test\os
   flutter clean
   flutter pub get
   flutter run -d windows
   ```

2. **等待应用启动**，查看日志中是否有：
   ```
   🔍 API详细日志已启用
   ```

3. **确认音源设置**：
   - 打开应用
   - 进入"设置" → "音源设置"
   - 确认当前活动音源是"内置 API"

4. **执行搜索测试**：
   - 在搜索框输入："周杰伦"
   - 点击搜索
   - 观察控制台日志输出

5. **收集日志**：
   - 复制所有相关的日志输出
   - 特别注意带有 `❌` 标记的错误信息

## 常见问题诊断

### 问题1：没有看到任何API日志
**可能原因**：
- 应用没有重新编译
- 音源不是"内置 API"

**解决方法**：
1. 运行 `flutter clean` 清理缓存
2. 重新运行 `flutter run -d windows`
3. 确认音源设置为"内置 API"

### 问题2：看到"平台未找到"错误
**日志示例**：
```
❌ [SearchService] netease 搜索失败: Exception: 平台未找到: netease
```

**可能原因**：
- PlatformFactory初始化失败

**解决方法**：
- 查看应用启动日志，确认平台工厂是否正确初始化

### 问题3：看到HTTP错误（如403、401）
**日志示例**：
```
[API] ✅ Status: 403
```

**可能原因**：
- User-Agent被识别为爬虫
- API端点需要认证
- IP被封禁

### 问题4：看到加密错误
**日志示例**：
```
❌ [NeteaseCrypto] RSA加密失败: ...
```

**可能原因**：
- RSA公钥解析失败
- 加密库依赖问题

**解决方法**：
- 检查 `pubspec.yaml` 中的依赖版本
- 运行 `flutter pub get` 重新安装依赖

### 问题5：搜索返回空结果但没有错误
**可能原因**：
- API返回成功但数据为空
- JSON解析问题

**解决方法**：
- 查看API响应的Body内容
- 检查是否有 `"songs":[]` 或类似的空数组

## 下一步

收集到日志后，请：

1. **查找错误信息**：搜索日志中的 `❌` 标记
2. **确定失败的平台**：看哪个平台搜索失败
3. **分析错误原因**：根据错误信息判断问题类型
4. **提供日志**：如果需要帮助，请提供完整的错误日志

## 快速测试命令

```bash
# 清理并重新运行
cd D:\test\os
flutter clean
flutter pub get
flutter run -d windows 2>&1 | tee search_debug.log
```

这会将所有输出保存到 `search_debug.log` 文件中，方便查看。

## 联系支持

如果问题仍未解决，请提供：
1. 完整的错误日志（特别是带 `❌` 的部分）
2. API响应内容（如果有）
3. 你的操作系统和Flutter版本
