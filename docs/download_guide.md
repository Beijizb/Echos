# 📦 下载和安装指南

## 为什么 Artifacts 是 ZIP 格式？

GitHub Actions 的 `upload-artifact` 功能会**自动将所有文件打包成 ZIP**，这是 GitHub 的设计行为，无法避免。

## 🎯 解决方案：从 Release 下载

### ✅ 推荐方式：Release 页面

**从 Release 页面下载的文件是原始格式，不会被二次打包！**

1. 访问：https://github.com/Beijizb/Echos/releases
2. 选择最新版本
3. 在 "Assets" 部分直接下载：
   - ✅ `app-arm64-v8a-release.apk` - Android APK（直接安装）
   - ✅ `echo-windows-x64.zip` - Windows 压缩包
   - ✅ `cyrene_music-linux-x64.tar.gz` - Linux 压缩包
   - ✅ `cyrene_music-macos.dmg` - macOS 安装包
   - ✅ `echo-ios-unsigned.ipa` - iOS 安装包

### ❌ 不推荐：Artifacts 页面

从 Actions 页面下载的 Artifacts 会被打包成 ZIP：
- `android-apk.zip` - 里面包含 APK
- `windows-x64.zip` - 里面包含另一个 ZIP
- 需要解压两次才能使用

## 📱 各平台安装说明

### Android

**文件**：`app-arm64-v8a-release.apk`

**安装步骤**：
1. 从 Release 页面下载 APK
2. 在手机上打开 APK 文件
3. 允许安装未知来源应用
4. 点击安装

### Windows

**文件**：`echo-windows-x64.zip`

**安装步骤**：
1. 从 Release 页面下载 ZIP
2. 解压到任意文件夹
3. 运行 `cyrene_music.exe`

**注意**：首次运行可能需要允许防火墙访问

### Linux

**文件**：`cyrene_music-linux-x64.tar.gz`

**安装步骤**：
```bash
# 下载并解压
tar -xzf cyrene_music-linux-x64.tar.gz

# 进入目录
cd bundle

# 运行应用
./cyrene_music
```

### macOS

**文件**：`cyrene_music-macos.dmg`

**安装步骤**：
1. 从 Release 页面下载 DMG
2. 双击打开 DMG
3. 将应用拖到 Applications 文件夹
4. 首次运行需要在"系统偏好设置"中允许

### iOS

**文件**：`echo-ios-unsigned.ipa`

**安装步骤**：
1. 下载 IPA 文件
2. 使用 AltStore、Sideloadly 或 Xcode 签名
3. 安装到设备

## 🔄 如何触发构建

### 方法 1：创建 Tag（自动发布 Release）

```bash
git tag v1.0.0
git push origin v1.0.0
```

这会自动：
1. 构建所有平台
2. 创建 Release
3. 上传所有文件到 Release

### 方法 2：手动触发

1. 访问：https://github.com/Beijizb/Echos/actions
2. 选择 "Multi-Platform Build"
3. 点击 "Run workflow"
4. 选择要构建的平台
5. 点击 "Run workflow"

**注意**：手动触发只会创建 Artifacts（ZIP 格式），不会创建 Release

### 方法 3：推送到 main 分支

```bash
git push origin main
```

这会构建所有平台，但**不会创建 Release**，只会创建 Artifacts

## 📊 对比表

| 下载方式 | Android | Windows | Linux | macOS | iOS | 推荐 |
|---------|---------|---------|-------|-------|-----|------|
| **Release** | ✅ APK | ✅ ZIP | ✅ tar.gz | ✅ DMG | ✅ IPA | ⭐⭐⭐⭐⭐ |
| **Artifacts** | ❌ ZIP(APK) | ❌ ZIP(ZIP) | ❌ ZIP(tar.gz) | ❌ ZIP(DMG) | ❌ ZIP(IPA) | ⭐ |

## 💡 最佳实践

### 对于开发者

**日常开发**：
- 推送到 main 分支
- 从 Artifacts 下载测试（需要解压）

**发布版本**：
- 创建 Tag（如 `v1.0.0`）
- 自动创建 Release
- 用户从 Release 下载原始文件

### 对于用户

**始终从 Release 页面下载**：
- https://github.com/Beijizb/Echos/releases
- 选择最新版本
- 下载对应平台的文件
- 直接安装，无需额外解压

## 🔧 技术说明

### 为什么 Artifacts 会被打包？

GitHub Actions 的设计：
```yaml
- name: Upload APK artifacts
  uses: actions/upload-artifact@v4
  with:
    name: android-apk
    path: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

即使上传的是 APK，GitHub 也会：
1. 创建一个名为 `android-apk` 的 artifact
2. 将 APK 打包成 `android-apk.zip`
3. 用户下载时得到 ZIP 文件

### Release 为什么不会打包？

Release 使用不同的机制：
```yaml
- name: Create Release
  uses: softprops/action-gh-release@v1
  with:
    files: |
      artifacts/android-apk/*.apk
```

这会：
1. 直接上传原始文件到 Release
2. 保持文件原始格式
3. 用户下载时得到原始文件

## 📝 总结

- ✅ **Release** = 原始文件格式（推荐）
- ❌ **Artifacts** = 自动打包成 ZIP（不推荐）
- 🎯 **最佳实践** = 创建 Tag 触发 Release

**记住**：始终从 Release 页面下载！
