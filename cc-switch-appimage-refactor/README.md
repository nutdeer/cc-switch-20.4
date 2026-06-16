# CC Switch - Ubuntu 20.04 Flatpak Build

在 Ubuntu 20.04 上从源码构建 CC Switch Flatpak 包。

## 前置依赖

- `flatpak` (>= 1.14)
- `flatpak-builder` (>= 1.2)
- GNOME 46 SDK 和 Platform：

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.gnome.Sdk//46 org.gnome.Platform//46
```

- Rust 1.95+ (via rustup)
- Node.js 20+ / pnpm 9+

## 构建

```bash
make all
```

或分步执行：

```bash
make build-env   # 设置 Rust 工具链
make compile     # 编译前后端
make package     # 打包 Flatpak
```

## 安装

```bash
make install
# 或手动:
flatpak install --user output/CC-Switch.flatpak
```

## 运行

```bash
make run
# 或:
flatpak run com.ccswitch.desktop
```

## 技术说明

### 为什么用 Flatpak 而非 AppImage

Tauri 2 依赖 webkit2gtk-4.1 (>= 2.42)，在 Ubuntu 20.04 上需要:
- glib-2.0 >= 2.70 (系统为 2.64)
- libsoup-3.0 (系统仅有 libsoup-2.4)
- webkit2gtk-4.1 (系统仅有 4.0)

Flatpak 的 GNOME 46 runtime 提供所有这些库，且与系统完全隔离，无需解决 ABI 冲突。

### 构建流程

1. **前端**：在宿主系统用 pnpm + Vite 构建 (不需要 GTK/WebKit)
2. **后端**：在 GNOME 46 SDK 沙箱中用 cargo 编译 (利用 SDK 自带的 webkit2gtk-4.1 等库)
3. **打包**：将编译产物 + ayatana tray 库打包为 Flatpak bundle

### 体积

- .flatpak bundle: ~7MB (压缩)
- 安装后 (含 GNOME 46 Platform runtime): ~200MB (runtime 可跨应用共享)

## 故障排除

### canberra-gtk-module 警告
非致命，GNOME 46 runtime 不含此声音主题模块。

### deep-link 注册失败
Flatpak 中 xdg-mime 不可用，不影响应用功能。

### 托盘图标
依赖 host 系统的 ayatana-appindicator 支持。大部分 Ubuntu 桌面环境默认支持。
