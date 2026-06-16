# CONTEXT

## 背景
- 项目/功能：CC Switch - Tauri 2 桌面应用 (All-in-One Manager for Claude Code, Codex, Gemini CLI, OpenCode, OpenClaw & Hermes)
- 当前状态：v3.16.2 已发布，官方支持 Ubuntu 22.04+，不支持 Ubuntu 20.04
- 相关链接或文件：
  - 源码: /home/reallab_zwx/Desktop/cc-switch-source
  - 官方仓库: https://github.com/farion1231/cc-switch
  - Cargo.toml: src-tauri/Cargo.toml (webkit2gtk v2_16 feature)
  - CI 构建: .github/workflows/release.yml (ubuntu-22.04 runner)
  - Flatpak manifest: flatpak/com.ccswitch.desktop.yml

## 问题
- 现在遇到什么问题：CC Switch v3.16.2 的 AppImage/DEB 无法在 Ubuntu 20.04 上运行
- 这个问题影响谁：所有使用 Ubuntu 20.04 LTS 的用户
- 目前的失败表现：
  1. 运行时 GLIBC 版本不匹配:
     ```
     libm.so.6: version `GLIBC_2.35' not found
     libc.so.6: version `GLIBC_2.32' not found
     libc.so.6: version `GLIBC_2.33' not found
     libc.so.6: version `GLIBC_2.34' not found
     ```
  2. 从源码编译失败: webkit2gtk-4.1, libsoup-3.0, glib-2.0 >= 2.70 在 Ubuntu 20.04 仓库中不存在
  3. 官方 CI 在 ubuntu-22.04 上编译（GLIBC 2.35），生成的二进制在 GLIBC 2.31 系统上无法加载

## 目标
- 这次要达成什么：让 CC Switch 能够以 AppImage 形式在 Ubuntu 20.04 上构建、打包和运行
- 完成后应该看到什么结果：
  1. 可在一键构建脚本中从源码编译生成 AppImage
  2. 生成的 AppImage 可在 Ubuntu 20.04 上正常运行
  3. 构建流程自动化（Makefile），可重复

## 非目标
- 这次明确不做什么：
  - 不修改 CC Switch 业务逻辑代码
  - 不升级/降级 Tauri 版本
  - 不改变 Node.js/Rust 版本要求
  - 不发布到 Flathub 或官方渠道

## 约束
- 时间约束：无硬性截止
- 技术约束：
  - 必须保持 Tauri 2.8.2 + webkit2gtk v2_16 feature
  - 必须保持现有 Rust 1.85+ 和前端依赖不变
  - 目标系统 GLIBC 2.31 (Ubuntu 20.04)
  - 构建环境使用 Docker (ubuntu:20.04)
- 业务约束：不修改上游仓库
- 兼容性约束：构建产物需同时兼容 Ubuntu 20.04+ 和 22.04+

## 已知信息
- 已确认事实：
  1. Ubuntu 20.04 apt 仓库无 webkit2gtk-4.1, libsoup-3.0, glib-2.0 >= 2.70
  2. Tauri 2 / wry 的 Linux 后端强制要求 webkit2gtk-4.1 (API level 2.42+)
  3. 官方 Cargo.toml 中 webkit2gtk crate 使用 features = ["v2_16"]
  4. 官方 CI 使用 ubuntu-22.04 runner，直接 apt install libwebkit2gtk-4.1-dev
  5. Tauri 内置 AppImage bundler（内部调用 appimagetool），无外部 linuxdeploy
  6. 官方 releases 提供 x86_64 AppImage ~93MB
  7. 当前机器 GLIBC 2.31 (Ubuntu 20.04.6 LTS)
- 假设但未验证的内容：
  1. 从 Ubuntu 22.04 提取的 webkit2gtk-4.1 .so 文件能否在 GLIBC 2.31 环境下配合 bundled glibc 加载
  2. Tauri 内置 AppImage bundler 在 20.04 上的兼容性

## 候选方案
- 方案 A (当前): AppImage 打包 - 在 Ubuntu 20.04 Docker 中编译（链接 GLIBC 2.31），
  从 22.04 提取 webkit2gtk-4.1 dev/runtime 包，用 linuxdeploy + bundled glibc 方式打包
- 方案 B (后备): Flatpak 从源码构建 - GNOME 46 SDK 提供全部运行时
- 方案 C (不可行): 降级 Tauri 到 1.x — 改动太大，失去 Tauri 2 功能
- 目前倾向：方案 A - AppImage with bundled libraries + glibc compat

## 风险
- 风险 1 (核心): webkit2gtk-4.1 的 .so 自身可能强依赖 GLIBC 2.32+ 符号，
  即使同时打包 bundled glibc 也可能有 ABI 冲突
- 风险 2: AppImage 体积可能极大（webkit2gtk + glib + gtk 全家桶 100MB+）
- 风险 3: libsoup-3.0 和系统已有 libsoup-2.4 可能存在端口/DBus 冲突
- 风险 4: Tauri 内置 AppImage bundler 可能在 20.04 的旧版 FUSE/工具链上不工作

## 需要补充的问题
- 问题 1: 需要在 Ubuntu 22.04 的 .deb 中找到 webkit2gtk-4.1 的完整依赖闭包
- 问题 2: bundled glibc 版本选择（建议使用 Ubuntu 22.04 的 glibc 2.35）
- 问题 3: linuxdeploy-plugin-gtk 在 webkit2gtk-4.1 上的支持情况
