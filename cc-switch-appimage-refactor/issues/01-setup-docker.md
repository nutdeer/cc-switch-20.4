# ISSUE 1/5

## 标题
- 搭建 Docker 编译环境（Ubuntu 20.04 + vendored webkit2gtk-4.1）

## 目标
- 创建 Dockerfile，在 Ubuntu 20.04 容器中安装所有编译依赖，
  包括从 Ubuntu 22.04 手动提取安装的 webkit2gtk-4.1 和 libsoup-3.0

## 背景
- 来自 PRD：需要在 Ubuntu 20.04 环境中编译 CC Switch，以链接 GLIBC 2.31。
  但 20.04 缺少 webkit2gtk-4.1 等关键依赖，需要从 22.04 软件包中手动提取安装。

## 实现范围
- 编写 `Dockerfile` 基于 ubuntu:20.04
- 安装基础构建工具（build-essential, curl, git, pkg-config 等）
- 安装 Node.js 18+ 和 pnpm 8+
- 安装 Rust 1.85+（via rustup）
- 安装 GTK/GLib 系统依赖（libgtk-3-dev, librsvg2-dev, libayatana-appindicator3-dev）
- 下载并从 Ubuntu 22.04 (jammy) 的 .deb 包中提取安装：
  - libwebkit2gtk-4.1-dev + 运行时库
  - libjavascriptcoregtk-4.1-dev + 运行时库
  - libsoup-3.0-dev + 运行时库
  - glib-2.0 >= 2.70 开发/运行时包
  - 所有传递依赖
- 安装 linuxdeploy 和 appimagetool 用于后续打包
- 验证 pkg-config 能找到 webkit2gtk-4.1

## 涉及文件
- `Dockerfile` (新建)
- `scripts/install-vendored-deps.sh` (新建，容器内安装 22.04 依赖包的脚本)

## 实现步骤
- [ ] 1. 编写 Dockerfile（基于 ubuntu:20.04）
- [ ] 2. 安装 build-essential, curl, wget, git, pkg-config, patchelf, libssl-dev 等基础工具
- [ ] 3. 安装 Node.js 18+ (via official setup script) 和 pnpm 8+
- [ ] 4. 安装 Rust 1.85+ (via rustup)
- [ ] 5. 安装 GTK/GLib 系统依赖 (libgtk-3-dev, librsvg2-dev, libayatana-appindicator3-dev)
- [ ] 6. 编写 vendored deps 安装脚本：
       - 从 http://archive.ubuntu.com/ubuntu/pool/ 下载所需 .deb 包
       - 用 dpkg-deb 提取到 /opt/vendored-deps/
       - 设置 PKG_CONFIG_PATH, LD_LIBRARY_PATH, CPATH
       - 验证 pkg-config --modversion webkit2gtk-4.1
- [ ] 7. 安装 linuxdeploy 和 appimagetool (从 GitHub Releases 下载)
- [ ] 8. 验证容器内可编译简单的 Tauri "Hello World" 项目

## 验收标准
- [ ] `docker build -t cc-switch-builder:20.04 .` 成功，无错误
- [ ] 容器内 `pkg-config --modversion webkit2gtk-4.1` 返回 >= 2.42
- [ ] 容器内 `pkg-config --modversion libsoup-3.0` 成功返回
- [ ] 容器内 `cargo --version` 显示 1.85+
- [ ] 容器内 `pnpm --version` 显示 8+
- [ ] 容器内 `pkg-config --libs webkit2gtk-4.1` 包含正确的 -L 和 -l 标志

## 测试要求
- 必须运行：`docker build -t cc-switch-builder:20.04 .`
- 需要补充：进入容器手动验证 pkg-config 输出

## 风险
- 高风险：从 22.04 提取的 webkit2gtk-4.1 系列包可能有大量传递依赖，
  需要下载几十个 .deb 文件才能完整安装
- 中风险：22.04 的某些包可能与 20.04 的基础系统库有冲突
- 低风险：Rust/node 安装脚本在 20.04 上的兼容性

## 备注
- Dockerfile 和安装脚本放在 `/home/reallab_zwx/Desktop/cc-switch-appimage-refactor/`
- 容器名: `cc-switch-builder:20.04`
