# ISSUE 4/5

## 标题
- 编写一键构建脚本 Makefile

## 目标
- 提供从源码到 AppImage 的一键构建命令（`make all`）

## 实现范围
- 编写顶层 `Makefile`，串联所有构建步骤
- 支持参数化：版本号、源码目录、输出目录
- 构建成功/失败状态输出清晰

## 涉及文件
- `Makefile` (新建)
- `scripts/` 目录下的各脚本（Issue 1-3 中创建）

## 实现步骤
- [ ] 1. 定义 Makefile targets:
       ```
       make help              # 显示所有可用 targets
       make build-env         # Issue 1: docker build
       make compile           # Issue 2: 编译源码
       make package           # Issue 3: 打包 AppImage
       make all               # 一键执行 build-env + compile + package
       make clean             # 清理构建产物
       make shell             # 进入 Docker 容器交互式 shell
       ```
  - [ ] 2. 定义可配置变量：
       ```
       APP_VERSION ?= 3.16.2
       SOURCE_DIR ?= /home/reallab_zwx/Desktop/cc-switch-source
       OUTPUT_DIR ?= $(PWD)/output
       ```
  - [ ] 3. `make build-env`: 调用 `docker build -t cc-switch-builder:20.04 .`
  - [ ] 4. `make compile`: 调用 `scripts/compile.sh`
  - [ ] 5. `make package`: 调用 `scripts/package-appimage.sh`
  - [ ] 6. `make all`: 逐步执行 build-env -> compile -> package
  - [ ] 7. `make clean`: 删除 Docker 镜像、中间文件

## 验收标准
- [ ] `make all` 可一键产出 .AppImage 文件
- [ ] 多次运行幂等（已有产物时跳过重复步骤）
- [ ] 构建失败时输出有意义的错误信息
- [ ] `make help` 显示帮助信息

## 测试要求
- 必须运行：`make all`
- 需要补充：`make clean && make all` 验证干净构建

## 风险
- 低风险，纯流程编排

## 备注
- Makefile 放在项目根目录 `/home/reallab_zwx/Desktop/cc-switch-appimage-refactor/Makefile`
- 使用 .PHONY 声明防止与文件名冲突
