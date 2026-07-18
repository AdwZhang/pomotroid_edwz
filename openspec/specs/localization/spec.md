## 需求

### 需求：基于 Paraglide 的消息目录

系统应当使用 Paraglide JS v2（`@inlang/paraglide-js`）管理所有用户可见字符串。所有字符串应当定义在消息文件（`messages/<locale>.json`）中，并通过生成的类型安全消息函数（`m.<key>()`）访问。基础语言应当为 `en`。

#### 场景：类型安全的消息访问

- **当** 开发者引用一个不存在的消息键
- **则** TypeScript 应当报告编译错误

#### 场景：未使用消息的树摇优化

- **当** 应用构建为生产版本
- **则** 未使用键的消息函数应当从包中被消除

### 需求：发布时支持的语言

系统应当发布八种语言：英语（`en`，基础）、西班牙语（`es`）、法语（`fr`）、德语（`de`）、日语（`ja`）、简体中文（`zh`）、葡萄牙语（`pt`）和土耳其语（`tr`）。非英语语言可以是机器翻译。所有语言消息文件应当包含 `messages/en.json` 中定义的每个键的翻译。

#### 场景：非英语语言中所有键都存在

- **当** 加载非英语消息文件
- **则** `messages/en.json` 中定义的每个键都应当有对应条目

#### 场景：缺失键回退到英语

- **当** 活跃语言文件中缺少某个消息键
- **则** 应当显示英语字符串作为回退

#### 场景：土耳其语可选择

- **当** 用户在设置 → 系统中打开语言选择器
- **则** 土耳其语应当作为选项出现，选择后应当以土耳其语显示所有 UI 字符串

### 需求：自动语言检测

系统应当默认为 `language = 'auto'`。当 `'auto'` 激活时，语言应当从 `navigator.language` 解析，通过匹配最接近的支持语言（前缀匹配）。如果没有匹配，语言应当回退到 `en`。

#### 场景：精确语言匹配

- **当** `navigator.language` 为 `'fr'`
- **则** 活跃语言应当为 `fr`

#### 场景：带区域限定的语言匹配

- **当** `navigator.language` 为 `'de-AT'`
- **则** 活跃语言应当为 `de`

#### 场景：不支持的语言回退

- **当** `navigator.language` 为 `'zh-CN'`
- **则** 活跃语言应当回退到 `en`

### 需求：用户语言覆盖

系统应当允许用户通过系统设置部分的语言下拉菜单覆盖检测到的语言。选择的语言应当作为 `language` 设置持久化并立即应用，无需重启应用。

#### 场景：用户选择特定语言

- **当** 用户从语言下拉菜单选择 `'fr'`
- **则** 两个窗口中的所有 UI 字符串应当立即以法语显示

#### 场景：用户重置为自动检测

- **当** 用户从语言下拉菜单选择 `'Auto'`
- **则** `language` 保存为 `'auto'`，语言从 `navigator.language` 重新解析

### 需求：语言在两个窗口中应用

系统应当在主计时器窗口和设置窗口中都应用活跃语言。当 `language` 设置变更时，两个窗口都应当响应 `settings:changed` 事件重新调用 `setLocale()`。

#### 场景：语言变更传播到两个窗口

- **当** 用户在设置窗口打开时更改语言设置
- **则** 计时器窗口和设置窗口都应当更新其显示的字符串

### 需求：所有语言中的工具提示字符串

所有工具提示 i18n 键应当存在于每个支持的语言消息文件中。非英语翻译可以是机器翻译。定义了以下键：

| 键 | 英文值 |
| --- | --- |
| `tooltip_settings` | `"Open Settings"` |
| `tooltip_statistics` | `"Open Statistics"` |
| `tooltip_restart_round` | `"Restart the current round from the beginning."` |
| `tooltip_skip` | `"Skip to the next round."` |
| `tooltip_reset` | `"Reset the timer to the first work round. Current session progress will be cleared."` |
| `tooltip_mute` | `"Mute alert sounds"` |
| `tooltip_unmute` | `"Unmute alert sounds"` |
| `tooltip_round_counter` | `"Current work round out of the total rounds before a long break."` |
| `tooltip_round_counter_session` | `"Continuous session round count. Resets only when the timer is reset."` |
| `tooltip_verbose_logging` | `"Enables detailed debug logging. Use when reporting issues. Log files are accessible via Open Log Folder in Settings → About."` |
| `tooltip_websocket` | `"Enables a local WebSocket server for external integrations such as stream overlays. Disabled by default."` |

注意：`system_tray_gnome_hint` 被 Linux 专用的系统托盘开关上的 `TooltipInfo` 图标复用；它早于此功能，不需要新键。

#### 场景：非英语语言中所有工具提示键都存在

- **当** 加载非英语消息文件
- **则** 上面列出的每个工具提示键在该文件中都应当有对应条目

---

### 需求：翻译后的桌面通知

系统应当使用翻译后的 Paraglide 消息字符串构造标题和正文来发送桌面通知。通知字符串构造应当在前端进行；Rust 后端应当接收预翻译的 `title` 和 `body`。

#### 场景：工作轮次完成通知使用活跃语言

- **当** 工作轮次完成且活跃语言为 `fr`
- **则** 通知标题和正文应当为法语

#### 场景：通知 Rust 命令接受任意标题和正文

- **当** 从前端调用 `notification_show(title, body)`
- **则** Rust 应当使用提供的标题和正文显示通知，不进行任何字符串构造
