# 仓库文档与目录结构说明

本文档用于帮助你快速理解本仓库的“文档放在哪里、代码放在哪里、各目录分别负责什么”，并给出一条推荐的阅读与上手路径。

## 1. 从哪里开始读

- 项目总览与开发/构建入口：[README.md](file:///d:/test/Echos/Echos/README.md)
- 自动化构建（多平台打包、Release）：[docs/GITHUB_ACTIONS_BUILD.md](file:///d:/test/Echos/Echos/docs/GITHUB_ACTIONS_BUILD.md)
- 版本发布流程（前端版本、后端版本、发布规范）：[docs/VERSION_RELEASE_GUIDE.md](file:///d:/test/Echos/Echos/docs/VERSION_RELEASE_GUIDE.md)
- 后端 API 需求说明（接口约定）：[BackendAPI_Requirements.md](file:///d:/test/Echos/Echos/BackendAPI_Requirements.md)

说明：README 里提到 `backend/` 目录与 Bun 启动方式，但当前仓库目录中未包含 `backend/` 文件夹；若你的实际工程需要后端，请以 [BackendAPI_Requirements.md](file:///d:/test/Echos/Echos/BackendAPI_Requirements.md) 为协议来源，后端实现可能在另一个仓库或未纳入此代码目录。

## 2. 顶层目录总览

下面按“仓库根目录”维度解释各目录与文件职责（以 Flutter 多平台工程的典型形态组织）。

### 2.1 目录

- `lib/`：Flutter/Dart 业务与 UI 主代码（应用真正的“核心”）。
- `assets/`：运行时静态资源（图标、SVG、内置 JSON 等），由 [pubspec.yaml](file:///d:/test/Echos/Echos/pubspec.yaml) 声明打包。
- `docs/`：专题文档集合（更新、缓存、Windows SMTC、构建、发布、排障等）。
- `scripts/`：本地辅助脚本（PowerShell/Python），用于测试更新、存储、批处理等。
- `demo/`：示例/实验性脚本（`.js`），偏开发期验证用途。
- `.github/workflows/`：CI 工作流（GitHub Actions 多平台构建、产物上传、Release）。
- `.agent/`：面向自动化/助手流程的工作流文档（例如音源配置指南）。
- `.claude/`：本地 AI 工具/助手相关配置（对业务运行通常不关键）。

### 2.2 平台工程目录（Flutter Shell）

这些目录由 Flutter 工具链生成并承载平台原生“外壳”，通常只有在做平台能力（通知、媒体控制、窗口、系统颜色等）时需要深入。

- `android/`：Android Gradle 工程（Kotlin 原生插件、通知/悬浮歌词服务等）。
- `ios/`：iOS Xcode 工程与资源（`Info.plist`、资源集、Entitlements 等）。
- `macos/`：macOS Xcode 工程与桌面端配置。
- `windows/`：Windows CMake 工程与 Runner（C++ 原生能力：SMTC、桌面歌词、窗口、系统色等）。
- `linux/`：Linux CMake 工程与 Runner。
- `web/`：Web 壳（`index.html`、`manifest.json`、Web 图标等）。

## 3. `docs/` 文档目录结构与用途

[docs/](file:///d:/test/Echos/Echos/docs) 以“专题”划分文档，覆盖构建/发布、平台问题、功能设计、排障记录等。建议把它当作“工程运行手册 + 方案沉淀”。

### 3.1 构建与发布

- Actions 多平台构建指南：[GITHUB_ACTIONS_BUILD.md](file:///d:/test/Echos/Echos/docs/GITHUB_ACTIONS_BUILD.md)
- Actions 构建修复/记录：[GITHUB_ACTIONS_BUILD_FIX.md](file:///d:/test/Echos/Echos/docs/GITHUB_ACTIONS_BUILD_FIX.md)
- 版本发布指南（前后端版本同步、Changelog 规范）：[VERSION_RELEASE_GUIDE.md](file:///d:/test/Echos/Echos/docs/VERSION_RELEASE_GUIDE.md)
- Linux 构建依赖说明：[LINUX_BUILD_REQUIREMENTS.md](file:///d:/test/Echos/Echos/docs/LINUX_BUILD_REQUIREMENTS.md)

### 3.2 自动更新（多端）

- Android 更新：[ANDROID_AUTO_UPDATE.md](file:///d:/test/Echos/Echos/docs/ANDROID_AUTO_UPDATE.md)
- Windows 更新相关（UAC、修复与最终方案等）：[WINDOWS_AUTO_UPDATE_UAC.md](file:///d:/test/Echos/Echos/docs/WINDOWS_AUTO_UPDATE_UAC.md)、[WINDOWS_AUTO_UPDATE_FIX.md](file:///d:/test/Echos/Echos/docs/WINDOWS_AUTO_UPDATE_FIX.md)、[WINDOWS_AUTO_UPDATE_FINAL.md](file:///d:/test/Echos/Echos/docs/WINDOWS_AUTO_UPDATE_FINAL.md)
- 更新测试与排障：[AUTO_UPDATE_TEST.md](file:///d:/test/Echos/Echos/docs/AUTO_UPDATE_TEST.md)、[UPDATE_TROUBLESHOOTING.md](file:///d:/test/Echos/Echos/docs/UPDATE_TROUBLESHOOTING.md)、[UPDATE_IGNORE_FEATURE.md](file:///d:/test/Echos/Echos/docs/UPDATE_IGNORE_FEATURE.md)

### 3.3 Windows 平台能力（SMTC/系统色/数据持久化等）

- SMTC 原生实现与排障：[NATIVE_SMTC_IMPLEMENTATION.md](file:///d:/test/Echos/Echos/docs/NATIVE_SMTC_IMPLEMENTATION.md)、[SMTC_TROUBLESHOOTING.md](file:///d:/test/Echos/Echos/docs/SMTC_TROUBLESHOOTING.md)、[SMTC_APP_NAME_ISSUE.md](file:///d:/test/Echos/Echos/docs/SMTC_APP_NAME_ISSUE.md)、[SMTC_APP_IDENTITY_FIX.md](file:///d:/test/Echos/Echos/docs/SMTC_APP_IDENTITY_FIX.md)
- Windows 主题/颜色相关：[SYSTEM_THEME_COLOR.md](file:///d:/test/Echos/Echos/docs/SYSTEM_THEME_COLOR.md)、[WINDOWS_COLOR_FIX.md](file:///d:/test/Echos/Echos/docs/WINDOWS_COLOR_FIX.md)、[WINDOWS_ACCENT_COLOR_TEST.md](file:///d:/test/Echos/Echos/docs/WINDOWS_ACCENT_COLOR_TEST.md)
- Windows 数据持久化说明：[WINDOWS_DATA_PERSISTENCE_GUIDE.md](file:///d:/test/Echos/Echos/docs/WINDOWS_DATA_PERSISTENCE_GUIDE.md)

### 3.4 缓存与性能

- 缓存快速指南与配置/排障：[CACHE_QUICK_GUIDE.md](file:///d:/test/Echos/Echos/docs/CACHE_QUICK_GUIDE.md)、[CACHE_SETTINGS.md](file:///d:/test/Echos/Echos/docs/CACHE_SETTINGS.md)、[CACHE_TROUBLESHOOTING.md](file:///d:/test/Echos/Echos/docs/CACHE_TROUBLESHOOTING.md)
- 音乐缓存专题：[MUSIC_CACHE.md](file:///d:/test/Echos/Echos/docs/MUSIC_CACHE.md)
- 性能优化记录：[PERFORMANCE_OPTIMIZATION.md](file:///d:/test/Echos/Echos/docs/PERFORMANCE_OPTIMIZATION.md)

### 3.5 功能与协议/安全

- 播放器功能清单：[PLAYER_FEATURES.md](file:///d:/test/Echos/Echos/docs/PLAYER_FEATURES.md)
- 播放续播功能与测试：[PLAYBACK_RESUME_FEATURE.md](file:///d:/test/Echos/Echos/docs/PLAYBACK_RESUME_FEATURE.md)、[PLAYBACK_RESUME_TESTING.md](file:///d:/test/Echos/Echos/docs/PLAYBACK_RESUME_TESTING.md)
- 安全实现说明：[SECURITY_IMPLEMENTATION.md](file:///d:/test/Echos/Echos/docs/SECURITY_IMPLEMENTATION.md)
- 自定义文件格式/数据结构：[CYRENE_FILE_FORMAT.md](file:///d:/test/Echos/Echos/docs/CYRENE_FILE_FORMAT.md)

### 3.6 音源/登录/歌单导入等专项

- TuneHub 接口说明：[tunehub_api.md](file:///d:/test/Echos/Echos/docs/tunehub_api.md)
- 网易扫码登录指南：[netease-qr-login-guide.md](file:///d:/test/Echos/Echos/docs/netease-qr-login-guide.md)
- QQ 歌单导入指南与修复记录：[QQ_PLAYLIST_IMPORT_GUIDE.md](file:///d:/test/Echos/Echos/docs/QQ_PLAYLIST_IMPORT_GUIDE.md)、[QQ_PLAYLIST_IMPORT_FIX.md](file:///d:/test/Echos/Echos/docs/QQ_PLAYLIST_IMPORT_FIX.md)

### 3.7 管理后台

- 管理面板说明与快速开始：[ADMIN_PANEL.md](file:///d:/test/Echos/Echos/docs/ADMIN_PANEL.md)、[ADMIN_QUICK_START.md](file:///d:/test/Echos/Echos/docs/ADMIN_QUICK_START.md)

## 4. `lib/` 主代码结构与职责划分

[lib/](file:///d:/test/Echos/Echos/lib) 是 Flutter 主代码目录，建议按“入口 → 页面 → 服务 → 模型 → 组件”理解。

### 4.1 应用入口

- 应用入口文件：[main.dart](file:///d:/test/Echos/Echos/lib/main.dart)
  - 通常负责：初始化服务、注入全局状态、设置路由、启动根 Widget。

### 4.2 页面层：`lib/pages/`

[pages/](file:///d:/test/Echos/Echos/lib/pages) 包含主要界面与导航入口，按功能域拆分子目录：

- `home_page/`：首页与“为你推荐/榜单”等聚合视图。
- `player_components/` 与 `mobile_player_components/`：播放器 UI 组件组合（桌面/移动端不同布局）。
- `settings_page/`：设置相关页面与子面板（外观、网络、存储、账户等）。
- `auth/`：登录/注册/扫码登录等认证相关页面。
- 其他：如 `favorites_page.dart`、`history_page.dart`、`local_page.dart` 等功能页面。

经验法则：页面层尽量不直接写“业务细节”，而是调用 `services/` 暴露的能力，并组合 `widgets/` 的可复用组件。

### 4.3 业务服务层：`lib/services/`

[services/](file:///d:/test/Echos/Echos/lib/services) 是业务逻辑核心，通常以“单例服务 + 状态通知”的方式组织（例如网络、缓存、播放状态、更新检查、平台能力等）。

- 服务目录说明文档：[lib/services/README.md](file:///d:/test/Echos/Echos/lib/services/README.md)
- 典型职责示例：
  - `url_service.dart`：后端地址与 API 端点集中管理（官方源/自定义源切换）。
  - `auto_update_service.dart`：自动更新检查与下载/触发逻辑（与 `docs/` 中的更新文档对应）。
  - `cache_service.dart`、`persistent_storage_service.dart`：缓存与持久化存储。
  - `native_smtc_service.dart`、`system_media_service.dart`、`tray_service.dart`：平台相关能力封装（桌面端更常见）。

### 4.4 数据模型层：`lib/models/`

[models/](file:///d:/test/Echos/Echos/lib/models) 存放与后端交互、页面展示所需的数据结构（JSON 解析、序列化、枚举定义等）。

- 模型说明文档：[lib/models/README.md](file:///d:/test/Echos/Echos/lib/models/README.md)
- 典型内容：`track.dart`（歌曲）、`toplist.dart`（榜单）、`version_info.dart`（版本信息）等。

### 4.5 组件与工具：`lib/widgets/`、`lib/utils/`、`lib/layouts/`

- `widgets/`：可复用 UI 组件（包含 Cupertino/Material 等平台风格差异）。
- `utils/`：通用工具（歌词解析、主题管理、Toast 等）。
- `layouts/`：顶层布局抽象（例如不同桌面风格/框架的主布局）。

## 5. `assets/` 资源目录

[assets/](file:///d:/test/Echos/Echos/assets) 保存运行时资源，常见包括：

- `assets/icons/`：应用图标、托盘图标等（桌面端托盘通常使用专门图标）。
- `assets/ui/`：SVG 图标资源（用于 UI）。
- `assets/*.json`：内置数据（如某些页面展示所需的静态 JSON）。

资源是否会被打包进应用，取决于 [pubspec.yaml](file:///d:/test/Echos/Echos/pubspec.yaml) 中的 `assets:` 声明。

## 6. 平台工程目录说明（何时需要关心）

### 6.1 Android：`android/`

当你在做以下事情时需要进入：

- 通知栏媒体控制、前台服务、悬浮歌词等原生能力（Kotlin 文件位于 `android/app/src/main/kotlin/...`）。
- Android 构建与签名、Gradle 配置与依赖（`build.gradle.kts`、`settings.gradle.kts`）。

### 6.2 Windows：`windows/`

当你在做以下事情时需要进入：

- SMTC（系统媒体传输控制）、桌面歌词窗口、系统颜色读取、窗口行为等（`windows/runner/` 内的 C++ 实现）。
- Windows 打包与安装器（根目录 [installer.iss](file:///d:/test/Echos/Echos/installer.iss) 也与发布相关）。

### 6.3 iOS/macOS：`ios/`、`macos/`

当你在做以下事情时需要进入：

- 原生权限、Info.plist、Entitlements、签名与打包。
- CocoaPods/Xcode 工程配置。

### 6.4 Linux：`linux/`

当你在做以下事情时需要进入：

- 桌面端依赖（GTK）、CMake 配置与 runner 行为。

### 6.5 Web：`web/`

当你在做以下事情时需要进入：

- PWA manifest、Web 首屏与图标、SEO/Meta 配置等。

## 7. CI 与自动化

- CI 工作流定义：[.github/workflows/build.yml](file:///d:/test/Echos/Echos/.github/workflows/build.yml)
  - 负责多平台构建、打包产物、上传 Artifacts，以及标签触发时创建 Release。
- 对应使用说明与注意事项：[docs/GITHUB_ACTIONS_BUILD.md](file:///d:/test/Echos/Echos/docs/GITHUB_ACTIONS_BUILD.md)

## 8. 根目录常见关键文件

- Flutter 依赖与资源声明：[pubspec.yaml](file:///d:/test/Echos/Echos/pubspec.yaml)
- Flutter 锁定依赖版本：[pubspec.lock](file:///d:/test/Echos/Echos/pubspec.lock)
- Dart 静态分析规则：[analysis_options.yaml](file:///d:/test/Echos/Echos/analysis_options.yaml)
- DevTools 配置：[devtools_options.yaml](file:///d:/test/Echos/Echos/devtools_options.yaml)
- Windows 安装器脚本（Inno Setup）：[installer.iss](file:///d:/test/Echos/Echos/installer.iss)
- 其他专项说明：如 [UPGRADE_VIDEO_BACKGROUND.md](file:///d:/test/Echos/Echos/UPGRADE_VIDEO_BACKGROUND.md)、[WINDOWS_PERFORMANCE_CHECK.md](file:///d:/test/Echos/Echos/WINDOWS_PERFORMANCE_CHECK.md)

说明：根目录下的 `flutter_log.txt`、`analyze_output.txt`、`diff_output.txt` 更像是一次性输出/排查产物，不属于“项目运行必需”，可以作为问题排查参考。

## 9. 推荐阅读顺序（按目标）

- 想跑起来/本地开发：先读 [README.md](file:///d:/test/Echos/Echos/README.md) → 看 `lib/main.dart` → 从 `lib/pages/` 找主入口页面。
- 想接后端/换音源：先读 [BackendAPI_Requirements.md](file:///d:/test/Echos/Echos/BackendAPI_Requirements.md) → 再读 [lib/services/README.md](file:///d:/test/Echos/Echos/lib/services/README.md)（UrlService 相关）→ 查 `lib/services/url_service.dart` 及相关请求服务。
- 想做发布/自动构建：读 [docs/GITHUB_ACTIONS_BUILD.md](file:///d:/test/Echos/Echos/docs/GITHUB_ACTIONS_BUILD.md) → 读 [docs/VERSION_RELEASE_GUIDE.md](file:///d:/test/Echos/Echos/docs/VERSION_RELEASE_GUIDE.md) → 看 [.github/workflows/build.yml](file:///d:/test/Echos/Echos/.github/workflows/build.yml)。
- 想排 Windows 平台问题：优先查 `docs/` 中 Windows/SMTC/更新相关文档 → 对照 `windows/runner/` 与 `lib/services/` 的平台封装服务。

