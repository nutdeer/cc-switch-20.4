# ISSUE 2/5

## 标题
- 在 Docker 容器中编译 CC Switch 源码

## 目标
- 编写构建脚本，在 Issue 1 创建的 Docker 容器中编译 CC Switch 前端和后端，
  产出链接 GLIBC 2.31 的可执行文件

## 背景
- 基于 Issue 1 的 Docker 环境，需要实际编译 CC Switch 源码。
  关键：在 Ubuntu 20.04 容器中编译，确保 Rust 二进制链接 GLIBC 2.31（或更低）的符号。

## 实现范围
- 挂载 CC Switch 源码到容器
- 执行 `pnpm install` 安装前端依赖
- 执行编译（使用 Tauri CLI 或直接 cargo build）
- 从编译输出中提取 cc-switch 可执行文件和资源
- 验证二进制的 GLIBC 符号版本要求

## 涉及文件
- `scripts/compile.sh` (新建)
- CC Switch 源码 (挂载或克隆)

## 实现步骤
- [ ] 1. 编写编译脚本 `scripts/compile.sh`:
       - 启动 Docker 容器，挂载 CC Switch 源码目录到 /src
       - 容器内 `cd /src && pnpm install --frozen-lockfile`
       - 容器内 `cd /src && pnpm tauri build --bundles deb`
         （注意：Tauri 内置 bundler 可能尝试调用 appimagetool，
         如果 20.04 上不可用，退而求其次用 `cargo build --release`）
       - 从 target/release/ 提取 cc-switch 二进制
  - [ ] 2. 如果 `pnpm tauri build` 失败，分离前端和后端编译：
       - `pnpm run build:renderer` 构建前端
       - `cd src-tauri && cargo build --release` 仅构建后端
  - [ ] 3. 验证编译产物：
       - `readelf -V cc-switch | grep GLIBC` — 确认最高 GLIBC 版本 <= 2.31
       - `ldd cc-switch` — 确认链接的库
  - [ ] 4. 将二进制和资源文件复制到构建工作目录

## 验收标准
- [ ] 编译成功，无错误
- [ ] `readelf -V cc-switch | grep GLIBC` 显示最高版本 <= 2.31
- [ ] `ldd cc-switch` 显示引用的库（webkit2gtk-4.1, libsoup-3.0 等）
- [ ] 二进制文件可执行（在容器内 `./cc-switch --help` 不报 GLIBC 错误）

## 测试要求
- 必须运行：`bash scripts/compile.sh`
- 需要补充：`readelf -V` 和 `ldd` 检查

## 风险
- 中风险：Tauri 内置 AppImage bundler 在 20.04 上可能缺少 appimagetool 等工具
  - 缓解：仅编译二进制（cargo build），AppImage 打包在 Issue 3 中用 linuxdeploy 独立完成
- 中风险：Node.js 前端编译可能因 Vite/依赖版本在 Node 18 上兼容性问题
- 低风险：Rust crate 下载可能需代理（已安装）

## 备注
- 首次编译会下载所有 Rust crate 依赖，耗时长
- 编译器生成的中间文件（target/）体量大，注意磁盘空间
