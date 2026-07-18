## 需求

### 需求：更新清单托管在仓库中

系统应当在 `main` 分支根目录提供一个 `latest.json` 文件，遵循 Tauri 更新器清单格式。清单应当包含最新发布版本、各平台下载 URL 和每个平台包的 Ed25519 签名。CI 应当在所有平台包成功上传后生成并提交此文件。

#### 场景：发布构建后清单存在

- **当** 一次发布 CI 运行成功完成
- **则** `latest.json` 应当存在于 `main` 分支的仓库根目录，且包含 Windows（NSIS）、macOS（DMG）和 Linux（AppImage）的有效条目

#### 场景：清单版本匹配发布标签

- **当** CI 运行由版本标签触发（如 `v1.2.0`）
- **则** `latest.json` 中的 `version` 字段应当等于 `1.2.0`

---

### 需求：包在 CI 期间使用 Ed25519 签名

系统应当在每次发布 CI 运行期间使用存储在 GitHub Secrets 中的 Ed25519 私钥（`TAURI_SIGNING_PRIVATE_KEY`）对发布包进行签名。对应的公钥应当嵌入 `tauri.conf.json` 的更新器插件配置中。

#### 场景：更新器拒绝被篡改的包

- **当** 下载包的签名与公钥不匹配
- **则** `tauri-plugin-updater` 应当中止安装并报告错误

#### 场景：更新器接受正确签名的包

- **当** 下载包的签名与公钥匹配
- **则** 安装正常进行

---

### 需求：`check_update` Tauri 命令

系统应当暴露一个 `check_update` Tauri 命令，查询 `latest.json` 并返回序列化的更新描述符（版本、正文、日期），如果当前版本已是最新则返回 `null`。

#### 场景：有可用更新

- **当** 调用 `check_update` 且 `latest.json` 包含高于运行中应用版本的版本
- **则** 命令应当返回至少包含 `{ version: string, body: string | null, date: string | null }` 的对象

#### 场景：已是最新版本

- **当** 调用 `check_update` 且 `latest.json` 版本等于运行中应用版本
- **则** 命令应当返回 `null`

#### 场景：网络不可达

- **当** 调用 `check_update` 且清单 URL 不可达
- **则** 命令应当返回一个错误，前端可以捕获并显示为非阻塞消息

---

### 需求：`install_update` Tauri 命令

系统应当暴露一个 `install_update` Tauri 命令，下载、验证并安装待处理的更新，然后重新启动应用。

#### 场景：安装完成后应用重新启动

- **当** 在 `check_update` 返回可用更新后调用 `install_update`
- **则** 包被下载、签名验证、安装，应用重新启动到新版本

---

### 需求：设置 → 关于中的更新检查 UI

系统应当在设置 → 关于部分显示更新状态。挂载时，如果 `check_for_updates` 已启用，该部分应当静默调用 `check_update`。状态应当经历：空闲 → 检查中 → 已是最新 / 有可用更新。当有可用更新时，应当出现"安装 vX.Y.Z"按钮。点击后应当调用 `install_update`。

#### 场景：没有可用更新

- **当** "关于"部分挂载且 `check_update` 返回 `null`
- **则** 更新行应当显示"已是最新版本"（或等效内容）以及当前版本

#### 场景：有可用更新 — 显示安装按钮

- **当** `check_update` 返回可用更新版本
- **则** "关于"部分应当显示"安装 vX.Y.Z"按钮，其中 X.Y.Z 为可用版本

#### 场景：检查已禁用 — 不执行检查

- **当** `check_for_updates` 为 `false` 且"关于"部分挂载
- **则** 不应调用 `check_update`，更新行应当显示静态版本号，无检查指示器

#### 场景：检查优雅失败

- **当** `check_update` 返回错误（如网络故障）
- **则** 更新行应当显示非阻塞错误消息，不应抛出异常或导致设置窗口崩溃

---

### 需求：注册更新器能力

系统应当在 `src-tauri/capabilities/default.json` 中声明 `updater` 权限，以便设置窗口可以调用 `check_update` 和 `install_update`。

#### 场景：命令可从设置窗口调用

- **当** 设置窗口调用 `check_update` 或 `install_update`
- **则** Tauri 不应因缺少能力权限而拒绝调用
