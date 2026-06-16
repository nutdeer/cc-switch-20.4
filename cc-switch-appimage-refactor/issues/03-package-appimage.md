# ISSUE 3/5

## 标题
- 使用 linuxdeploy 打包生成兼容 Ubuntu 20.04 的 AppImage

## 目标
- 将编译产物 + 所有运行时依赖（webkit2gtk-4.1, libsoup-3.0, glib-2.70+, bundled glibc）
  打包为一个可在 Ubuntu 20.04 上独立运行的 AppImage

## 背景
- Issue 2 产出的二进制链接 GLIBC 2.31，但依赖的 webkit2gtk-4.1.so 等库自身
  链接 GLIBC 2.35。解决方案：将较新的 glibc 打包进 AppImage，
  通过自定义 AppRun 管理 LD_LIBRARY_PATH 让 bundled 库使用 bundled glibc。

## 实现范围
- 创建 AppDir 目录结构
- 从 Ubuntu 22.04 提取 webkit2gtk-4.1, libsoup-3.0, glib-2.70+ 运行时 .so 文件
- 使用 linuxdeploy 自动收集非 GTK 的依赖
- 使用 linuxdeploy-plugin-gtk 收集 GTK/GLib 主题依赖
- 编写 AppRun 脚本：
  - 设置 LD_LIBRARY_PATH 优先加载 bundled libs（包括 bundled glibc）
  - 使用 patchelf 修改二进制，指向 bundled ld-linux
  - 设置 WebKit 环境变量
- 使用 appimagetool 生成最终 .AppImage

## 涉及文件
- `scripts/package-appimage.sh` (新建)
- `AppDir/AppRun` (新建)
- `AppDir/cc-switch.desktop` (从源码复制并调整)
- `AppDir/cc-switch.png` (从源码复制)
- `AppDir/usr/bin/cc-switch` (从编译产物复制)
- `AppDir/usr/lib/` (bundled libraries)

## 实现步骤
- [ ] 1. 创建 AppDir 结构：
       ```
       AppDir/
       ├── AppRun                    # 自定义启动脚本
       ├── cc-switch.desktop
       ├── cc-switch.png
       ├── usr/
       │   ├── bin/
       │   │   └── cc-switch        # 主二进制
       │   └── lib/
       │       ├── x86_64-linux-gnu/ # bundled glibc + webkit libs
       │       └── ...              # 其他 bundled libraries
       ```
  - [ ] 2. 复制编译产物到 AppDir/usr/bin/
  - [ ] 3. 从 Ubuntu 22.04 包中提取运行时库到 AppDir/usr/lib/：
       - libwebkit2gtk-4.1.so.0
       - libjavascriptcoregtk-4.1.so.0
       - libsoup-3.0.so.0
       - libglib-2.0.so.0 (2.70+)
       - libgio-2.0.so.0 (2.70+)
       - libgobject-2.0.so.0 (2.70+)
       - 以及所有传递依赖
  - [ ] 4. 准备 bundled glibc 兼容层：
       - 从 Ubuntu 22.04 提取 libc.so.6, ld-linux-x86-64.so.2 放到 AppDir
       - 用 patchelf 将 cc-switch 二进制的 interpreter 指向 bundled ld-linux
       - 或者用 AppRun 设置正确的 LD_LIBRARY_PATH
  - [ ] 5. 编写 AppRun 脚本：
       ```bash
       #!/bin/bash
       APPDIR="$(dirname "$(readlink -f "$0")")"
       export LD_LIBRARY_PATH="$APPDIR/usr/lib:$APPDIR/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
       export WEBKIT_DISABLE_DMABUF_RENDERER=1
       export WEBKIT_DISABLE_COMPOSITING_MODE=1
       exec "$APPDIR/usr/bin/cc-switch" "$@"
       ```
  - [ ] 6. 复制 .desktop 文件和图标
  - [ ] 7. 运行 linuxdeploy 收集额外依赖
  - [ ] 8. 运行 linuxdeploy-plugin-gtk 收集 GTK 主题/图标依赖
  - [ ] 9. 运行 appimagetool 生成最终 .AppImage
  - [ ] 10. 测试：在 Ubuntu 20.04 上提取并验证 bundled libs 完整

## 验收标准
- [ ] 生成 .AppImage 文件（如 CC-Switch-v3.16.2-Linux-x86_64.AppImage）
- [ ] `./CC-Switch-*.AppImage --appimage-extract` 后检查：
  - 包含 libwebkit2gtk-4.1.so.0
  - 包含 libsoup-3.0.so.0
  - 包含 libglib-2.0.so.0 (>= 2.70)
- [ ] 在 Ubuntu 20.04 上运行 ./CC-Switch-*.AppImage 不报 GLIBC 错误
- [ ] CC Switch GUI 窗口正常显示

## 测试要求
- 必须运行：在 Ubuntu 20.04 上执行 `./CC-Switch-*.AppImage`
- 需要补充：用 `LD_DEBUG=libs` 验证库加载路径

## 风险
- 核心风险：即使 bundler 了所有库 + bundled glibc，库之间的 ABI 兼容性
  可能仍有问题（如某些库用 glibc 2.35 的 feature_test_macros 编译）
- 缓解方案：如果 bundled glibc 方案失败，改用 patchelf 直接修改库的 GLIBC 版本符号
  （降级符号版本，有风险但可能有效）
- AppImage 体积可能超过 200MB

## 备注
- linuxdeploy-x86_64.AppImage 从 https://github.com/linuxdeploy/linuxdeploy/releases 下载
- appimagetool-x86_64.AppImage 从 https://github.com/AppImage/AppImageKit/releases 下载
- linuxdeploy-plugin-gtk 从 https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/releases 下载
