## 新增需求

### 需求：构建版本字符串在编译时烘焙

系统应当在 `cargo build` 期间通过在 `build.rs` 中调用 `git describe --tags --long --always --dirty` 计算一个符合 semver 的构建版本字符串，并将结果作为编译时环境变量 `APP_BUILD_VERSION` 发出。完整的提交 SHA 应当通过 `git rev-parse HEAD` 单独作为 `APP_BUILD_SHA` 发出。

#### 场景：开发构建（距最近标签有若干提交）

- **当** 二进制文件从距最近标签 N > 0 个提交的位置编译
- **则** `APP_BUILD_VERSION` 应当为 `{base}-dev.{N}+{short-sha}`（如 `1.0.0-dev.80+20b2d87`）

#### 场景：发布构建（精确在标签位置）

- **当** 二进制文件从精确位于标签的提交编译
- **则** `APP_BUILD_VERSION` 应当为 `{base}+{short-sha}`（如 `1.0.0+20b2d87`）

#### 场景：工作树有未提交更改

- **当** 二进制文件在有未提交更改时编译
- **则** `APP_BUILD_VERSION` 应当在构建元数据中包含 `.dirty` 后缀（如 `1.0.0-dev.80+20b2d87.dirty`）

#### 场景：无 git 历史或无标签

- **当** `git describe` 失败（无 git 二进制文件、无标签、浅克隆脱离态）
- **则** `APP_BUILD_VERSION` 应当回退到 `{base}+unknown`，其中 `{base}` 从 `tauri.conf.json` 读取

#### 场景：新提交后增量重建

- **当** 进行新提交并再次运行 `cargo build`
- **则** 构建脚本应当重新执行并生成反映新提交的更新后的 `APP_BUILD_VERSION`

---

### 需求：构建版本通过 IPC 命令暴露

系统应当提供一个 Tauri 命令 `app_version`，返回 `APP_BUILD_VERSION` 作为 `&'static str`。此命令应当可在任何时候由前端调用，返回编译时烘焙的版本字符串。

#### 场景：命令返回烘焙的版本

- **当** 前端调用 `app_version`
- **则** 响应应当为编译到二进制文件中的 `APP_BUILD_VERSION` 字符串

---

### 需求：构建版本在设置 → 关于中显示

系统应当在设置 → 关于中显示构建版本字符串，取代之前硬编码的版本常量。显示的字符串应当使用短 SHA 格式（7 个字符）。

#### 场景：关于挂载时显示版本

- **当** 用户打开设置 → 关于
- **则** 版本行应当显示完整的 semver 构建字符串（如 `1.0.0-dev.80+20b2d87`）

#### 场景：版本字符串永不为空

- **当** `app_version` 成功返回
- **则** "关于"部分应当显示返回的字符串；如果调用失败，应当回退显示 `tauri.conf.json` 中的基础版本

---

### 需求：启动时记录完整提交 SHA

系统应当在应用启动期间以 INFO 级别记录完整的 40 字符提交 SHA（来自 `APP_BUILD_SHA`），连同构建版本字符串。

#### 场景：启动日志包含完整 SHA

- **当** 应用启动
- **则** 日志文件应当包含一条 INFO 条目，同时有构建版本字符串和完整提交 SHA（如 `[app] version=1.0.0-dev.80+20b2d87 sha=20b2d87173870d939002efe84fddff2e944eabd6`）

---

### 需求：CI 工作流获取完整 git 历史

CI 构建工作流应当在所有 checkout 步骤使用 `fetch-depth: 0`，以便 `git describe` 可以访问完整的标签历史并在 CI 生成的产物中计算提交距离。

#### 场景：CI 产物携带提交计数

- **当** 在 CI 中从距最近标签 N 个提交的位置构建二进制文件
- **则** 二进制文件的 `APP_BUILD_VERSION` 应当包含提交计数 N（如 `1.0.0-dev.80+abc1234`）
