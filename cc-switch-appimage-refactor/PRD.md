# PRD

## 1. 目标
- 产品/功能名称：CC Switch Ubuntu 20.04 兼容 AppImage 构建方案
- 解决的问题：CC Switch 无法在 Ubuntu 20.04 LTS 上安装和运行
- 预期收益：
  - Ubuntu 20.04 用户可以使用 CC Switch
  - 提供可重复的自动化构建流程
  - 构建产物同时兼容 Ubuntu 20.04 和 22.04+

## 2. 背景
- 来自 `CONTEXT.md` 的关键信息：
  - Tauri 2 的 webkit2gtk-4.1 依赖在 Ubuntu 20.04 完全不满足
  - 官方 CI 在 ubuntu-22.04 (GLIBC 2.35) 上编译，二进制在 20.04 (GLIBC 2.31) 上加载失败
  - 采用在 20.04 Docker 中编译 + 从 22.04 提取依赖 + bundled glibc 的 AppImage 方案

## 3. 用户故事
- 作为：Ubuntu 20.04 LTS 用户
- 我想：下载/构建一个可运行的 CC Switch AppImage 文件
- 以便：在旧系统上正常使用 CC Switch 管理 Claude Code/Codex/Gemini 等 CLI 工具

## 4. 功能范围
### 必做
- 在 Ubuntu 20.04 Docker 容器中编译 CC Switch 源码（链接 GLIBC 2.31）
- 从 Ubuntu 22.04 提取 webkit2gtk-4.1 + libsoup-3.0 开发/运行时包
- 使用 linuxdeploy 自动收集所有运行时依赖到 AppDir
- 打包 bundled glibc 解决运行时 GLIBC 版本差异
- 生成可在 Ubuntu 20.04 上直接运行的 `.AppImage` 文件
- 编写 Makefile 一键构建

### 可选
- GitHub Actions CI 自动发布 20.04 兼容 AppImage
- 自动符号剥离减小体积
- AppImageUpdate 增量更新支持

### 不做
- 不修改 CC Switch Rust/TS 源码
- 不改变上游构建系统（pnpm/tauri/cargo）
- 不发布到 Flathub
- 不生成 deb/rpm 格式

## 5. 需求说明
### 5.1 行为
- `./CC-Switch-*.AppImage` 执行后应启动 CC Switch GUI
- 系统托盘图标正常工作
- 所有功能（Provider 切换, MCP 管理, 代理, Skills 等）正常

### 5.2 交互
- AppImage 双击/命令行执行启动，行为与原版一致
- 首次启动可能提示 FUSE 安装（标准 AppImage 行为）

### 5.3 数据
- 配置数据存储在 `~/.cc-switch/`（与原版一致）
- AppImage 自身不写入配置，所有用户数据在 host 文件系统

### 5.4 异常处理
- GLIBC 不匹配 -> 构建阶段通过 bundled glibc 解决
- 缺少 FUSE -> 提示用户安装或使用 `--appimage-extract-and-run`
- 库加载失败 -> AppRun 脚本输出诊断信息
- 构建失败 -> Makefile 输出明确错误信息

## 6. 非功能要求
- 性能：与原版无显著差异
- 稳定性：等价于在 Ubuntu 22.04 上原生运行
- 可维护性：构建脚本可读、可重复、参数化
- 安全性：不引入额外后门或补丁，仅打包官方源码

## 7. 验收标准
- [ ] 构建脚本可在 Docker 中无人工干预完成编译
- [ ] 生成的 `.AppImage` 文件可在 Ubuntu 20.04 上启动并显示 GUI
- [ ] 基本功能正常: Provider 切换, 托盘菜单, 设置页面
- [ ] 生成的 `.AppImage` 也可在 Ubuntu 22.04+ 正常运行
- [ ] 构建流程文档化（Makefile + README）

## 8. 依赖项
- Docker（提供 Ubuntu 20.04 编译环境）
- 从 Ubuntu 22.04 提取的 webkit2gtk-4.1 全家桶（dev + runtime）
- Node.js 18+ / pnpm 8+ / Rust 1.85+（在容器内）
- linuxdeploy-x86_64.AppImage + linuxdeploy-plugin-gtk
- appimagetool-x86_64.AppImage
- Bundled glibc 兼容方案（patchelf + 自定义 AppRun）

## 9. 风险与待决问题
- 风险：
  - webkit2gtk-4.1 的 .so 自身依赖 GLIBC 2.35，即使 bundled glibc 也可能有 ABI 冲突
  - linuxdeploy-plugin-gtk 可能无法正确识别 webkit2gtk-4.1 的依赖
  - Tauri 内置 bundler 可能在 20.04 上不工作
- 待确认：
  - bundled glibc 的具体实现方式（patchelf interpreter + LD_LIBRARY_PATH）
  - 需要打包的最小依赖集合
  - 构建产物在 22.04+ 上的兼容性
