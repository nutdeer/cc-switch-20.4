# CC-Switch Ubuntu 20.04 适配版

让 [CC-Switch](https://github.com/farion1231/cc-switch) 在 Ubuntu 20.04 LTS 上运行的适配方案。

CC-Switch 是一个管理 Claude Code、Codex、Gemini CLI、OpenCode 等 AI 编程工具的桌面应用（Tauri 2 + React + TypeScript + Rust）。

## 为什么需要适配

官方 v3.16.2 仅支持 Ubuntu 22.04+。在 Ubuntu 20.04 上：
- **GLIBC 版本太低**（2.31，官方需要 2.32~2.35）
- **缺少系统库**：webkit2gtk-4.1、libsoup-3.0、glib-2.0 >= 2.70 均不在 20.04 仓库中

## 解决方案

通过 Flatpak 的 GNOME 46 SDK 打包 —— SDK 自带所有缺失的运行时库，与宿主系统完全隔离，无需升级系统 GLIBC。

## 安装

```bash
# 1. 安装 Flatpak
sudo apt install flatpak flatpak-builder
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# 2. 安装 GNOME 46 运行时（仅首次需要，~500MB，之后可跨应用共享）
flatpak install --user flathub org.gnome.Sdk//46 org.gnome.Platform//46

# 3. 安装 CC-Switch（直接用预构建的包，无需编译）
flatpak install --user CC-Switch.flatpak

# 4. 运行
flatpak run com.ccswitch.desktop
```

## 目录说明

| 文件 | 说明 |
|------|------|
| `CC-Switch.flatpak` | **预构建的 Flatpak 安装包**（~15MB），开箱即用 |
| `CC-Switch-v3.16.2-Linux-x86_64.deb` | 官方 v3.16.2 deb，**不可在 20.04 上运行**（GLIBC 不兼容） |
| `CC-Switch-v3.9.0-3-Linux.deb` | 旧版 v3.9.0-3 deb，可能兼容 20.04（未验证） |
| `cc-switch-source/` | v3.16.2 完整源码（未被 git 跟踪） |
| `cc-switch-appimage-refactor/` | 构建脚本：Flatpak 方案（成功）+ AppImage 方案（未完成） |
| `cc-switch-flatpak-build/` | Flatpak 构建工作目录 |
| `cc-switch-flatpak-repo/` | Flatpak 本地仓库 |
| `CC-Switch-v3.16.2-extracted/` | v3.16.2 deb 解压内容 |
| `cc-switch-3.9.0-3-deb-extracted/` | v3.9.0-3 deb 解压内容 |

> `.deb` 文件可以直接 `sudo dpkg -i xxx.deb` 安装，但 v3.16.2 版本在 20.04 上因 GLIBC 不兼容会报错。

## AppImage 尝试

曾尝试通过 bundling 系统库的方式打包 AppImage，因 webkit2gtk-4.1 依赖链庞大且存在 ABI 冲突风险，改用了 Flatpak。AppImage 构建脚本保留在 `cc-switch-appimage-refactor/` 中供参考。

## 参考资料

- 官方仓库：[github.com/farion1231/cc-switch](https://github.com/farion1231/cc-switch)
- 官方网站：[ccswitch.io](https://ccswitch.io)
- 作者：[Jason Young](https://github.com/farion1231)，MIT 协议
